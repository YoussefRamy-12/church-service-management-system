-- Phase 1: verified cross-service student identity matching and linking.
-- Expand-only: legacy students columns and register_service_student(uuid,...) remain.
-- Run duplicate_students_report.sql before this migration. The guarded index below
-- aborts if normalized name + birth-date duplicates appeared since that report.

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA extensions;

CREATE OR REPLACE FUNCTION private.normalize_ar_name(p_value text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $function$
  SELECT pg_catalog.btrim(
    pg_catalog.lower(
      pg_catalog.regexp_replace(
        pg_catalog.regexp_replace(
          pg_catalog.translate(
            pg_catalog.btrim(COALESCE(p_value, '')),
            'أإآىة',
            'ااايه'
          ),
          '[ً-ٰٟـ]',
          '',
          'g'
        ),
        '[[:space:]]+',
        ' ',
        'g'
      )
    )
  );
$function$;

CREATE OR REPLACE FUNCTION private.normalize_phone(p_value text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
SET search_path = ''
AS $function$
DECLARE
  v_digits text;
BEGIN
  v_digits := pg_catalog.translate(
    COALESCE(p_value, ''),
    '٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹',
    '01234567890123456789'
  );
  v_digits := pg_catalog.regexp_replace(v_digits, '[^0-9]', '', 'g');

  IF v_digits = '' THEN
    RETURN NULL;
  ELSIF v_digits ~ '^0020[0-9]{10}$' THEN
    RETURN '0' || pg_catalog.substr(v_digits, 5);
  ELSIF v_digits ~ '^20[0-9]{10}$' THEN
    RETURN '0' || pg_catalog.substr(v_digits, 3);
  ELSIF v_digits ~ '^[1-9][0-9]{8}$' THEN
    RETURN '0' || v_digits;
  ELSIF v_digits ~ '^[1-9][0-9]{9}$' THEN
    RETURN '0' || v_digits;
  END IF;

  RETURN v_digits;
END;
$function$;

REVOKE ALL ON FUNCTION private.normalize_ar_name(text)
  FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.normalize_phone(text)
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION private.normalize_ar_name(text), private.normalize_phone(text) TO authenticated;

ALTER TABLE public.students
  ADD COLUMN IF NOT EXISTS normalized_name text
  GENERATED ALWAYS AS (private.normalize_ar_name(name)) STORED;

-- Known limitation: namesakes born on the same day cannot be created while the unique index on (normalized_name, birth_date) exists.
DO $migration_guard$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.students
    WHERE birth_date IS NOT NULL
    GROUP BY normalized_name, birth_date
    HAVING count(*) > 1
  ) THEN
    RAISE EXCEPTION
      'Duplicate normalized student names and birth dates exist; review supabase/audit/duplicate_students_report.sql before retrying';
  END IF;
END
$migration_guard$;

CREATE UNIQUE INDEX IF NOT EXISTS students_normalized_name_birth_date_uidx
  ON public.students (normalized_name, birth_date)
  WHERE birth_date IS NOT NULL;

CREATE INDEX IF NOT EXISTS students_normalized_name_trgm_idx
  ON public.students USING gin (normalized_name extensions.gin_trgm_ops);

CREATE TABLE IF NOT EXISTS public.student_identity_review_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  service_id uuid NOT NULL REFERENCES public.services(id) ON DELETE RESTRICT,
  requested_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  proposed_student_data jsonb NOT NULL
    CHECK (pg_catalog.jsonb_typeof(proposed_student_data) = 'object')
    CHECK (NOT (proposed_student_data ?| ARRAY[
      'sensitive_data', 'student_sensitive_data', 'medical_notes',
      'guardian_name', 'guardian_phone', 'father_job', 'father_phone',
      'mother_name', 'mother_job', 'mother_phone', 'financial_status',
      'address_building', 'address_street', 'address_floor',
      'address_apartment', 'confessor'
    ])),
  candidate_student_ids uuid[] NOT NULL DEFAULT ARRAY[]::uuid[],
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'linked', 'new_person', 'rejected')),
  resolved_by uuid REFERENCES auth.users(id) ON DELETE RESTRICT,
  resolved_at timestamptz,
  idempotency_key uuid NOT NULL,
  request_fingerprint text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT student_identity_review_resolution_state_check
    CHECK ((status = 'pending' AND resolved_by IS NULL AND resolved_at IS NULL)
        OR (status <> 'pending' AND resolved_by IS NOT NULL AND resolved_at IS NOT NULL)),
  CONSTRAINT student_identity_review_request_idempotency_unique
    UNIQUE (requested_by, idempotency_key)
);

CREATE INDEX IF NOT EXISTS student_identity_review_requests_service_status_idx
  ON public.student_identity_review_requests (service_id, status, created_at DESC);

CREATE TABLE IF NOT EXISTS public.student_identity_link_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id uuid REFERENCES public.students(id) ON DELETE RESTRICT,
  service_id uuid NOT NULL REFERENCES public.services(id) ON DELETE RESTRICT,
  membership_id uuid REFERENCES public.service_students(id) ON DELETE RESTRICT,
  action text NOT NULL
    CHECK (action IN ('linked_existing', 'created_new', 'sent_for_review')),
  decided_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  match_basis jsonb NOT NULL DEFAULT '{}'::jsonb
    CHECK (pg_catalog.jsonb_typeof(match_basis) = 'object'),
  request_fingerprint text NOT NULL,
  idempotency_key uuid,
  review_request_id uuid REFERENCES public.student_identity_review_requests(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT student_identity_link_event_shape_check CHECK (
    (action = 'sent_for_review' AND student_id IS NULL AND membership_id IS NULL
      AND review_request_id IS NOT NULL)
    OR
    (action IN ('linked_existing', 'created_new') AND student_id IS NOT NULL
      AND membership_id IS NOT NULL)
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS student_identity_link_events_actor_idempotency_uidx
  ON public.student_identity_link_events (decided_by, idempotency_key)
  WHERE idempotency_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS student_identity_link_events_service_created_idx
  ON public.student_identity_link_events (service_id, created_at DESC);

CREATE INDEX IF NOT EXISTS student_identity_link_events_review_request_idx
  ON public.student_identity_link_events (review_request_id)
  WHERE review_request_id IS NOT NULL;

ALTER TABLE public.student_identity_review_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_identity_link_events ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.student_identity_review_requests
  FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON TABLE public.student_identity_link_events
  FROM PUBLIC, anon, authenticated, service_role;
GRANT SELECT ON TABLE public.student_identity_review_requests TO authenticated;
GRANT SELECT ON TABLE public.student_identity_link_events TO authenticated;

DROP POLICY IF EXISTS student_identity_review_requests_read
  ON public.student_identity_review_requests;
CREATE POLICY student_identity_review_requests_read
  ON public.student_identity_review_requests
  FOR SELECT TO authenticated
  USING (
    requested_by = (SELECT auth.uid())
    OR (SELECT private.is_super_admin())
  );

DROP POLICY IF EXISTS student_identity_link_events_read
  ON public.student_identity_link_events;
CREATE POLICY student_identity_link_events_read
  ON public.student_identity_link_events
  FOR SELECT TO authenticated
  USING (
    (SELECT private.is_super_admin())
    OR (SELECT private.is_overall_admin_for_service(service_id))
  );

COMMENT ON TABLE public.student_identity_review_requests IS
  'Human-reviewed student identity decisions. Proposed data excludes student_sensitive_data.';
COMMENT ON TABLE public.student_identity_link_events IS
  'Append-only audit trail for student identity decisions; writes are limited to verified RPCs.';

CREATE OR REPLACE FUNCTION public.find_student_candidates(
  p_service_id uuid,
  p_name text,
  p_birth_date date,
  p_phone text
)
RETURNS TABLE (
  student_id uuid,
  display_name text,
  age integer,
  service_names text[],
  already_in_service boolean,
  match_score numeric
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_name text;
BEGIN
  IF (SELECT auth.uid()) IS NULL THEN
    RAISE EXCEPTION 'authentication_required' USING ERRCODE = '42501';
  END IF;
  IF p_service_id IS NULL
     OR NOT (SELECT private.can_access_service(p_service_id)) THEN
    RAISE EXCEPTION 'service_access_required' USING ERRCODE = '42501';
  END IF;

  v_name := private.normalize_ar_name(p_name);
  IF v_name IS NULL OR pg_catalog.char_length(v_name) < 3 THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH search_input AS (
    SELECT v_name AS normalized_name,
           private.normalize_phone(p_phone) AS normalized_phone
  ),
  scored AS (
    SELECT
      s.id AS candidate_id,
      s.name AS candidate_name,
      CASE
        WHEN s.birth_date IS NULL THEN NULL
        ELSE pg_catalog.date_part(
          'year',
          pg_catalog.age(CURRENT_DATE, s.birth_date)
        )::integer
      END AS candidate_age,
      COALESCE(
        pg_catalog.array_agg(DISTINCT sv.name ORDER BY sv.name)
          FILTER (WHERE sv.id IS NOT NULL),
        ARRAY[]::text[]
      ) AS candidate_services,
      COALESCE(
        pg_catalog.bool_or(ss.service_id = p_service_id),
        false
      ) AS in_requested_service,
      extensions.similarity(s.normalized_name, i.normalized_name) AS name_similarity,
      (s.birth_date = p_birth_date AND p_birth_date IS NOT NULL) AS birth_match,
      (
        i.normalized_phone IS NOT NULL
        AND private.normalize_phone(s.phone) = i.normalized_phone
      ) AS phone_match
    FROM public.students AS s
    CROSS JOIN search_input AS i
    LEFT JOIN public.service_students AS ss
      ON ss.student_id = s.id
     AND ss.status <> 'rejected'
    LEFT JOIN public.services AS sv
      ON sv.id = ss.service_id
    WHERE s.normalized_name OPERATOR(extensions.%) i.normalized_name
    GROUP BY s.id, s.name, s.birth_date, i.normalized_name, i.normalized_phone
  )
  SELECT
    scored.candidate_id,
    scored.candidate_name,
    scored.candidate_age,
    scored.candidate_services,
    scored.in_requested_service,
    pg_catalog.round(
      (
        100.0 * (
          0.65 * scored.name_similarity
          + 0.20 * CASE WHEN scored.birth_match THEN 1.0 ELSE 0.0 END
          + 0.15 * CASE WHEN scored.phone_match THEN 1.0 ELSE 0.0 END
        )
      )::numeric,
      1
    )
  FROM scored
  ORDER BY 6 DESC, scored.candidate_id
  LIMIT 10;
END;
$function$;

REVOKE ALL ON FUNCTION public.find_student_candidates(uuid, text, date, text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.find_student_candidates(uuid, text, date, text)
  TO authenticated;

-- Replace, rather than remove, the existing owner-service compatibility RPC.
-- Identity fields are global: only the identity owner's overall leaders and
-- platform super-admins can change them. Other services still edit membership data.
CREATE OR REPLACE FUNCTION public.update_service_student(
  p_membership_id uuid,
  p_name text,
  p_birth_date date,
  p_phone text,
  p_photo_path text,
  p_school text,
  p_grade text,
  p_is_deacon boolean,
  p_enrollment_date timestamptz,
  p_notes text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_student_id uuid;
  v_service_id uuid;
  v_class_id uuid;
  v_proposed_class_id uuid;
  v_identity_service_id uuid;
  v_current_name text;
  v_current_birth_date date;
  v_current_phone text;
  v_is_super_admin boolean;
  v_is_overall_admin boolean;
BEGIN
  SELECT ss.student_id, ss.service_id, ss.class_id, ss.proposed_class_id
  INTO v_student_id, v_service_id, v_class_id, v_proposed_class_id
  FROM public.service_students AS ss
  WHERE ss.id = p_membership_id
  FOR UPDATE;

  IF v_student_id IS NULL THEN
    RAISE EXCEPTION 'membership_not_found_or_not_authorized'
      USING ERRCODE = '42501';
  END IF;

  v_is_super_admin := (SELECT private.is_super_admin());
  IF NOT v_is_super_admin
     AND NOT (SELECT private.can_access_service(v_service_id)) THEN
    RAISE EXCEPTION 'membership_not_found_or_not_authorized'
      USING ERRCODE = '42501';
  END IF;

  v_is_overall_admin :=
    (SELECT private.is_overall_admin_for_service(v_service_id));

  IF NOT v_is_super_admin AND NOT v_is_overall_admin
     AND NOT (SELECT private.can_access_class(
       COALESCE(v_class_id, v_proposed_class_id)
     )) THEN
    RAISE EXCEPTION 'membership_not_found_or_not_authorized'
      USING ERRCODE = '42501';
  END IF;

  SELECT s.service_id, s.name, s.birth_date, s.phone
  INTO v_identity_service_id, v_current_name, v_current_birth_date, v_current_phone
  FROM public.students AS s
  WHERE s.id = v_student_id;

  IF v_is_super_admin
     OR (v_identity_service_id = v_service_id AND v_is_overall_admin) THEN
    BEGIN
      UPDATE public.students AS s
      SET name = pg_catalog.btrim(p_name),
          birth_date = COALESCE(p_birth_date, s.birth_date),
          phone = NULLIF(pg_catalog.btrim(COALESCE(p_phone, '')), ''),
          photo_path = NULLIF(pg_catalog.btrim(COALESCE(p_photo_path, '')), ''),
          updated_at = pg_catalog.now()
      WHERE s.id = v_student_id;
    EXCEPTION
      WHEN unique_violation THEN
        RAISE EXCEPTION 'possible_duplicate' USING ERRCODE = '23505';
    END;
  ELSIF pg_catalog.btrim(p_name) IS DISTINCT FROM pg_catalog.btrim(v_current_name)
     OR (p_birth_date IS NOT NULL AND p_birth_date IS DISTINCT FROM v_current_birth_date)
     OR NULLIF(pg_catalog.btrim(COALESCE(p_phone, '')), '')
        IS DISTINCT FROM NULLIF(pg_catalog.btrim(COALESCE(v_current_phone, '')), '') THEN
    RAISE EXCEPTION 'identity_edit_not_allowed' USING ERRCODE = '42501';
  END IF;

  UPDATE public.service_students AS ss
  SET school = NULLIF(pg_catalog.btrim(COALESCE(p_school, '')), ''),
      grade = NULLIF(pg_catalog.btrim(COALESCE(p_grade, '')), ''),
      is_deacon = COALESCE(p_is_deacon, false),
      enrollment_date = COALESCE(p_enrollment_date, ss.enrollment_date),
      notes = NULLIF(pg_catalog.btrim(COALESCE(p_notes, '')), ''),
      updated_at = pg_catalog.now()
  WHERE ss.id = p_membership_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'membership_update_not_authorized'
      USING ERRCODE = '42501';
  END IF;
END;
$function$;

REVOKE ALL ON FUNCTION public.update_service_student(
  uuid, text, date, text, text, text, text, boolean, timestamptz, text
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.update_service_student(
  uuid, text, date, text, text, text, text, boolean, timestamptz, text
) TO authenticated, service_role;

-- This is the sole cross-service insert path. The app.* settings are transaction-local
-- and bound to the exact student and destination service checked by this function.
CREATE OR REPLACE FUNCTION public.register_service_student_v2(
  p_service_id uuid,
  p_decision text,
  p_existing_student_id uuid,
  p_name text,
  p_birth_date date,
  p_phone text,
  p_photo_path text,
  p_school text,
  p_grade text,
  p_is_deacon boolean,
  p_enrollment_date timestamptz,
  p_status text,
  p_idempotency_key uuid,
  p_class_id uuid DEFAULT NULL,
  p_proposed_class_id uuid DEFAULT NULL,
  p_notes text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_actor_id uuid;
  v_is_super_admin boolean;
  v_is_overall_admin boolean;
  v_class_access boolean;
  v_student_id uuid;
  v_membership_id uuid;
  v_review_request_id uuid;
  v_existing_event public.student_identity_link_events%ROWTYPE;
  v_existing_request public.student_identity_review_requests%ROWTYPE;
  v_fingerprint text;
  v_normalized_name text;
  v_normalized_phone text;
  v_strong_student_id uuid;
  v_candidate_ids uuid[];
  v_match_score numeric;
  v_previous_link_flag text;
  v_previous_student_id text;
  v_previous_service_id text;
BEGIN
  v_actor_id := (SELECT auth.uid());
  IF v_actor_id IS NULL THEN
    RAISE EXCEPTION 'authentication_required' USING ERRCODE = '42501';
  END IF;
  IF p_idempotency_key IS NULL THEN
    RAISE EXCEPTION 'idempotency_key_required' USING ERRCODE = '22023';
  END IF;
  IF p_decision NOT IN ('link_existing', 'create_new', 'send_for_review') THEN
    RAISE EXCEPTION 'invalid_identity_decision' USING ERRCODE = '22023';
  END IF;
  IF p_service_id IS NULL
     OR NOT (SELECT private.can_access_service(p_service_id)) THEN
    RAISE EXCEPTION 'service_access_required' USING ERRCODE = '42501';
  END IF;
  IF NULLIF(pg_catalog.btrim(p_name), '') IS NULL
     OR p_birth_date IS NULL
     OR NULLIF(pg_catalog.btrim(p_grade), '') IS NULL
     OR p_enrollment_date IS NULL THEN
    RAISE EXCEPTION 'required_student_fields_missing' USING ERRCODE = '22023';
  END IF;
  IF p_status NOT IN ('pending', 'active') THEN
    RAISE EXCEPTION 'invalid_initial_membership_status' USING ERRCODE = '22023';
  END IF;
  IF p_status = 'pending'
     AND (p_proposed_class_id IS NULL OR p_class_id IS NOT NULL) THEN
    RAISE EXCEPTION 'pending_membership_requires_proposed_class' USING ERRCODE = '23514';
  END IF;
  IF p_status = 'active'
     AND (p_class_id IS NULL OR p_proposed_class_id IS NOT NULL) THEN
    RAISE EXCEPTION 'active_membership_requires_current_class' USING ERRCODE = '23514';
  END IF;

  v_is_super_admin := (SELECT private.is_super_admin());
  v_is_overall_admin :=
    (SELECT private.is_overall_admin_for_service(p_service_id));
  v_class_access := (SELECT private.can_access_class(
    COALESCE(p_class_id, p_proposed_class_id)
  ));
  IF NOT v_is_super_admin AND NOT v_is_overall_admin AND NOT v_class_access THEN
    RAISE EXCEPTION 'membership_write_not_authorized' USING ERRCODE = '42501';
  END IF;

  IF p_class_id IS NOT NULL AND NOT (SELECT private.can_access_class(p_class_id))
     AND NOT v_is_super_admin AND NOT v_is_overall_admin THEN
    RAISE EXCEPTION 'membership_class_not_authorized' USING ERRCODE = '42501';
  END IF;
  IF p_proposed_class_id IS NOT NULL
     AND NOT (SELECT private.can_access_class(p_proposed_class_id))
     AND NOT v_is_super_admin AND NOT v_is_overall_admin THEN
    RAISE EXCEPTION 'membership_class_not_authorized' USING ERRCODE = '42501';
  END IF;

  v_normalized_name := private.normalize_ar_name(p_name);
  v_normalized_phone := private.normalize_phone(p_phone);
  v_fingerprint := pg_catalog.md5(
    pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
      'service_id', p_service_id,
      'decision', p_decision,
      'existing_student_id', p_existing_student_id,
      'name', v_normalized_name,
      'birth_date', p_birth_date,
      'phone', v_normalized_phone,
      'photo_path', p_photo_path,
      'school', p_school,
      'grade', p_grade,
      'is_deacon', p_is_deacon,
      'enrollment_date', p_enrollment_date,
      'status', p_status,
      'class_id', p_class_id,
      'proposed_class_id', p_proposed_class_id,
      'notes', p_notes
    ))::text
  );

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_actor_id::text || p_idempotency_key::text, 0)
  );

  SELECT e.* INTO v_existing_event
  FROM public.student_identity_link_events AS e
  WHERE e.decided_by = v_actor_id
    AND e.idempotency_key = p_idempotency_key
  FOR UPDATE;

  IF FOUND THEN
    IF v_existing_event.request_fingerprint <> v_fingerprint THEN
      RAISE EXCEPTION 'idempotency_key_reused_with_different_payload'
        USING ERRCODE = '22023';
    END IF;
    IF v_existing_event.action = 'sent_for_review' THEN
      RETURN pg_catalog.jsonb_build_object(
        'decision', 'send_for_review',
        'status', 'pending',
        'student_id', NULL,
        'membership_id', NULL,
        'review_request_id', v_existing_event.review_request_id
      );
    END IF;
    RETURN pg_catalog.jsonb_build_object(
      'decision', v_existing_event.action,
      'status', 'complete',
      'student_id', v_existing_event.student_id,
      'membership_id', v_existing_event.membership_id,
      'review_request_id', NULL
    );
  END IF;

  IF p_decision = 'send_for_review' THEN
    SELECT COALESCE(
      pg_catalog.array_agg(c.student_id ORDER BY c.match_score DESC, c.student_id),
      ARRAY[]::uuid[]
    )
    INTO v_candidate_ids
    FROM public.find_student_candidates(
      p_service_id, p_name, p_birth_date, p_phone
    ) AS c;

    INSERT INTO public.student_identity_review_requests (
      service_id, requested_by, proposed_student_data, candidate_student_ids,
      idempotency_key, request_fingerprint
    )
    VALUES (
      p_service_id,
      v_actor_id,
      pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
        'name', pg_catalog.btrim(p_name),
        'birth_date', p_birth_date,
        'phone', NULLIF(pg_catalog.btrim(COALESCE(p_phone, '')), ''),
        'photo_path', NULLIF(pg_catalog.btrim(COALESCE(p_photo_path, '')), ''),
        'school', NULLIF(pg_catalog.btrim(COALESCE(p_school, '')), ''),
        'grade', pg_catalog.btrim(p_grade),
        'is_deacon', COALESCE(p_is_deacon, false),
        'enrollment_date', p_enrollment_date,
        'status', p_status,
        'class_id', p_class_id,
        'proposed_class_id', p_proposed_class_id
      )),
      v_candidate_ids,
      p_idempotency_key,
      v_fingerprint
    )
    ON CONFLICT (requested_by, idempotency_key) DO NOTHING
    RETURNING id INTO v_review_request_id;

    IF v_review_request_id IS NULL THEN
      SELECT r.* INTO v_existing_request
      FROM public.student_identity_review_requests AS r
      WHERE r.requested_by = v_actor_id
        AND r.idempotency_key = p_idempotency_key
      FOR UPDATE;
      IF v_existing_request.request_fingerprint <> v_fingerprint THEN
        RAISE EXCEPTION 'idempotency_key_reused_with_different_payload'
          USING ERRCODE = '22023';
      END IF;
      v_review_request_id := v_existing_request.id;
    END IF;

    INSERT INTO public.student_identity_link_events (
      service_id, action, decided_by, match_basis,
      request_fingerprint, idempotency_key, review_request_id
    )
    VALUES (
      p_service_id,
      'sent_for_review',
      v_actor_id,
      pg_catalog.jsonb_build_object(
        'candidate_count', pg_catalog.cardinality(v_candidate_ids),
        'sensitive_data_included', false
      ),
      v_fingerprint,
      p_idempotency_key,
      v_review_request_id
    );

    RETURN pg_catalog.jsonb_build_object(
      'decision', 'send_for_review',
      'status', 'pending',
      'student_id', NULL,
      'membership_id', NULL,
      'review_request_id', v_review_request_id
    );
  END IF;

  IF p_decision = 'link_existing' THEN
    IF p_existing_student_id IS NULL THEN
      RAISE EXCEPTION 'existing_student_id_required' USING ERRCODE = '22023';
    END IF;

    SELECT c.match_score INTO v_match_score
    FROM public.find_student_candidates(
      p_service_id, p_name, p_birth_date, p_phone
    ) AS c
    WHERE c.student_id = p_existing_student_id;

    IF v_match_score IS NULL OR v_match_score < 60 THEN
      RAISE EXCEPTION 'candidate_no_longer_matches' USING ERRCODE = '23514';
    END IF;

    IF EXISTS (
      SELECT 1 FROM public.service_students AS ss
      WHERE ss.student_id = p_existing_student_id
        AND ss.service_id = p_service_id
    ) THEN
      RAISE EXCEPTION 'student_already_in_service' USING ERRCODE = '23505';
    END IF;

    v_student_id := p_existing_student_id;
    v_membership_id := pg_catalog.gen_random_uuid();
    v_previous_link_flag := pg_catalog.current_setting('app.verified_link', true);
    v_previous_student_id := pg_catalog.current_setting('app.verified_student_id', true);
    v_previous_service_id := pg_catalog.current_setting('app.verified_service_id', true);
    PERFORM pg_catalog.set_config('app.verified_link', 'on', true);
    PERFORM pg_catalog.set_config('app.verified_student_id', v_student_id::text, true);
    PERFORM pg_catalog.set_config('app.verified_service_id', p_service_id::text, true);

    INSERT INTO public.service_students (
      id, student_id, service_id, class_id, proposed_class_id, enrollment_date,
      status, school, grade, is_deacon, notes
    )
    VALUES (
      v_membership_id, v_student_id, p_service_id, p_class_id, p_proposed_class_id,
      p_enrollment_date, p_status,
      NULLIF(pg_catalog.btrim(COALESCE(p_school, '')), ''),
      pg_catalog.btrim(p_grade),
      COALESCE(p_is_deacon, false),
      NULLIF(pg_catalog.btrim(COALESCE(p_notes, '')), '')
    );

    PERFORM pg_catalog.set_config(
      'app.verified_link', COALESCE(v_previous_link_flag, 'off'), true
    );
    PERFORM pg_catalog.set_config(
      'app.verified_student_id', COALESCE(v_previous_student_id, ''), true
    );
    PERFORM pg_catalog.set_config(
      'app.verified_service_id', COALESCE(v_previous_service_id, ''), true
    );

    INSERT INTO public.student_identity_link_events (
      student_id, service_id, membership_id, action, decided_by,
      match_basis, request_fingerprint, idempotency_key
    )
    VALUES (
      v_student_id, p_service_id, v_membership_id, 'linked_existing', v_actor_id,
      pg_catalog.jsonb_build_object(
        'server_reverified_candidate', true,
        'name_similarity', v_match_score,
        'birth_date_match', EXISTS (
          SELECT 1 FROM public.students AS s
          WHERE s.id = v_student_id AND s.birth_date = p_birth_date
        ),
        'phone_match', EXISTS (
          SELECT 1 FROM public.students AS s
          WHERE s.id = v_student_id
            AND private.normalize_phone(s.phone) = v_normalized_phone
            AND v_normalized_phone IS NOT NULL
        ),
        'sensitive_data_included', false
      ),
      v_fingerprint,
      p_idempotency_key
    );
  ELSE
    IF p_existing_student_id IS NOT NULL THEN
      RAISE EXCEPTION 'existing_student_id_not_allowed_for_create_new'
        USING ERRCODE = '22023';
    END IF;

    SELECT s.id INTO v_strong_student_id
    FROM public.students AS s
    WHERE (
      s.normalized_name = v_normalized_name
      AND s.birth_date = p_birth_date
    )
    OR (
      v_normalized_phone IS NOT NULL
      AND private.normalize_phone(s.phone) = v_normalized_phone
    )
    ORDER BY
      CASE
        WHEN s.normalized_name = v_normalized_name
          AND s.birth_date = p_birth_date THEN 0
        ELSE 1
      END,
      s.id
    LIMIT 1;

    IF v_strong_student_id IS NOT NULL THEN
      IF EXISTS (
        SELECT 1 FROM public.students AS s
        WHERE s.id = v_strong_student_id
          AND s.normalized_name = v_normalized_name
          AND s.birth_date = p_birth_date
      ) THEN
        -- The universal unique index is the final duplicate barrier, including
        -- for super-admins. A phone-only match can be overridden by a human admin.
        RAISE EXCEPTION 'possible_duplicate' USING ERRCODE = '23505';
      ELSIF NOT v_is_super_admin THEN
        RAISE EXCEPTION 'possible_duplicate' USING ERRCODE = '23505';
      END IF;
    END IF;

    v_student_id := pg_catalog.gen_random_uuid();
    v_membership_id := pg_catalog.gen_random_uuid();

    BEGIN
      INSERT INTO public.students (
        id, service_id, current_class_id, proposed_class_id, name, birth_date,
        phone, school, grade, enrollment_at, approval_status, photo_path, notes,
        is_deacon
      )
      VALUES (
        v_student_id, p_service_id, p_class_id, p_proposed_class_id,
        pg_catalog.btrim(p_name), p_birth_date,
        NULLIF(pg_catalog.btrim(COALESCE(p_phone, '')), ''),
        COALESCE(NULLIF(pg_catalog.btrim(COALESCE(p_school, '')), ''), ''),
        pg_catalog.btrim(p_grade), p_enrollment_date,
        CASE WHEN p_status = 'active'
          THEN 'approved'::public.student_approval_status
          ELSE 'pending'::public.student_approval_status END,
        NULLIF(pg_catalog.btrim(COALESCE(p_photo_path, '')), ''),
        NULLIF(pg_catalog.btrim(COALESCE(p_notes, '')), ''),
        COALESCE(p_is_deacon, false)
      );
    EXCEPTION WHEN unique_violation THEN
      RAISE EXCEPTION 'possible_duplicate' USING ERRCODE = '23505';
    END;

    INSERT INTO public.service_students (
      id, student_id, service_id, class_id, proposed_class_id, enrollment_date,
      status, school, grade, is_deacon, notes
    )
    VALUES (
      v_membership_id, v_student_id, p_service_id, p_class_id, p_proposed_class_id,
      p_enrollment_date, p_status,
      NULLIF(pg_catalog.btrim(COALESCE(p_school, '')), ''),
      pg_catalog.btrim(p_grade),
      COALESCE(p_is_deacon, false),
      NULLIF(pg_catalog.btrim(COALESCE(p_notes, '')), '')
    );

    INSERT INTO public.student_identity_link_events (
      student_id, service_id, membership_id, action, decided_by,
      match_basis, request_fingerprint, idempotency_key
    )
    VALUES (
      v_student_id, p_service_id, v_membership_id, 'created_new', v_actor_id,
      pg_catalog.jsonb_build_object(
        'strong_phone_match_overridden', v_strong_student_id IS NOT NULL,
        'super_admin_override', v_strong_student_id IS NOT NULL AND v_is_super_admin,
        'sensitive_data_included', false
      ),
      v_fingerprint,
      p_idempotency_key
    );
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'decision', p_decision,
    'status', 'complete',
    'student_id', v_student_id,
    'membership_id', v_membership_id,
    'review_request_id', NULL
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.register_service_student_v2(
  uuid, text, uuid, text, date, text, text, text, text, boolean,
  timestamptz, text, uuid, uuid, uuid, text
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.register_service_student_v2(
  uuid, text, uuid, text, date, text, text, text, text, boolean,
  timestamptz, text, uuid, uuid, uuid, text
) TO authenticated;

CREATE OR REPLACE FUNCTION public.resolve_identity_review(
  p_request_id uuid,
  p_decision text,
  p_student_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_actor_id uuid;
  v_request public.student_identity_review_requests%ROWTYPE;
  v_existing_event public.student_identity_link_events%ROWTYPE;
  v_student_id uuid;
  v_membership_id uuid;
  v_identity_service_id uuid;
  v_match_score numeric;
  v_name text;
  v_birth_date date;
  v_phone text;
  v_photo_path text;
  v_school text;
  v_grade text;
  v_is_deacon boolean;
  v_enrollment_date timestamptz;
  v_status text;
  v_class_id uuid;
  v_proposed_class_id uuid;
  v_previous_link_flag text;
  v_previous_student_id text;
  v_previous_service_id text;
  v_normalized_phone text;
BEGIN
  v_actor_id := (SELECT auth.uid());
  IF v_actor_id IS NULL OR NOT (SELECT private.is_super_admin()) THEN
    RAISE EXCEPTION 'super_admin_required' USING ERRCODE = '42501';
  END IF;
  IF p_decision NOT IN ('link_existing', 'create_new', 'rejected') THEN
    RAISE EXCEPTION 'invalid_review_decision' USING ERRCODE = '22023';
  END IF;

  SELECT r.* INTO v_request
  FROM public.student_identity_review_requests AS r
  WHERE r.id = p_request_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'identity_review_not_found' USING ERRCODE = 'P0002';
  END IF;

  IF v_request.status <> 'pending' THEN
    SELECT e.* INTO v_existing_event
    FROM public.student_identity_link_events AS e
    WHERE e.review_request_id = p_request_id
      AND e.action IN ('linked_existing', 'created_new')
    ORDER BY e.created_at DESC
    LIMIT 1;
    IF FOUND AND v_existing_event.action =
       CASE WHEN p_decision = 'link_existing' THEN 'linked_existing'
            WHEN p_decision = 'create_new' THEN 'created_new'
            ELSE '' END THEN
      RETURN pg_catalog.jsonb_build_object(
        'decision', p_decision,
        'status', v_request.status,
        'student_id', v_existing_event.student_id,
        'membership_id', v_existing_event.membership_id,
        'review_request_id', p_request_id
      );
    END IF;
    IF v_request.status = 'rejected' AND p_decision = 'rejected' THEN
      RETURN pg_catalog.jsonb_build_object(
        'decision', 'rejected',
        'status', 'rejected',
        'student_id', NULL,
        'membership_id', NULL,
        'review_request_id', p_request_id
      );
    END IF;
    RAISE EXCEPTION 'identity_review_already_resolved' USING ERRCODE = '23514';
  END IF;

  IF p_decision = 'rejected' THEN
    UPDATE public.student_identity_review_requests
    SET status = 'rejected', resolved_by = v_actor_id, resolved_at = pg_catalog.now()
    WHERE id = p_request_id;
    RETURN pg_catalog.jsonb_build_object(
      'decision', 'rejected',
      'status', 'rejected',
      'student_id', NULL,
      'membership_id', NULL,
      'review_request_id', p_request_id
    );
  END IF;

  v_name := v_request.proposed_student_data ->> 'name';
  v_birth_date := (v_request.proposed_student_data ->> 'birth_date')::date;
  v_phone := v_request.proposed_student_data ->> 'phone';
  v_photo_path := v_request.proposed_student_data ->> 'photo_path';
  v_school := v_request.proposed_student_data ->> 'school';
  v_grade := v_request.proposed_student_data ->> 'grade';
  v_is_deacon := COALESCE(
    (v_request.proposed_student_data ->> 'is_deacon')::boolean,
    false
  );
  v_enrollment_date :=
    (v_request.proposed_student_data ->> 'enrollment_date')::timestamptz;
  v_status := v_request.proposed_student_data ->> 'status';
  v_class_id := NULLIF(v_request.proposed_student_data ->> 'class_id', '')::uuid;
  v_proposed_class_id :=
    NULLIF(v_request.proposed_student_data ->> 'proposed_class_id', '')::uuid;

  IF p_decision = 'link_existing' THEN
    IF p_student_id IS NULL
       OR NOT (p_student_id = ANY(v_request.candidate_student_ids)) THEN
      RAISE EXCEPTION 'student_not_in_review_candidates' USING ERRCODE = '23514';
    END IF;

    SELECT c.match_score INTO v_match_score
    FROM public.find_student_candidates(
      v_request.service_id, v_name, v_birth_date, v_phone
    ) AS c
    WHERE c.student_id = p_student_id;
    IF v_match_score IS NULL OR v_match_score < 60 THEN
      RAISE EXCEPTION 'candidate_no_longer_matches' USING ERRCODE = '23514';
    END IF;

    IF EXISTS (
      SELECT 1 FROM public.service_students AS ss
      WHERE ss.student_id = p_student_id
        AND ss.service_id = v_request.service_id
    ) THEN
      RAISE EXCEPTION 'student_already_in_service' USING ERRCODE = '23505';
    END IF;

    v_student_id := p_student_id;
    v_membership_id := pg_catalog.gen_random_uuid();
    v_previous_link_flag := pg_catalog.current_setting('app.verified_link', true);
    v_previous_student_id := pg_catalog.current_setting('app.verified_student_id', true);
    v_previous_service_id := pg_catalog.current_setting('app.verified_service_id', true);
    PERFORM pg_catalog.set_config('app.verified_link', 'on', true);
    PERFORM pg_catalog.set_config('app.verified_student_id', v_student_id::text, true);
    PERFORM pg_catalog.set_config('app.verified_service_id', v_request.service_id::text, true);

    INSERT INTO public.service_students (
      id, student_id, service_id, class_id, proposed_class_id, enrollment_date,
      status, school, grade, is_deacon
    )
    VALUES (
      v_membership_id, v_student_id, v_request.service_id, v_class_id,
      v_proposed_class_id, v_enrollment_date, v_status,
      NULLIF(pg_catalog.btrim(COALESCE(v_school, '')), ''),
      pg_catalog.btrim(v_grade), v_is_deacon
    );

    PERFORM pg_catalog.set_config(
      'app.verified_link', COALESCE(v_previous_link_flag, 'off'), true
    );
    PERFORM pg_catalog.set_config(
      'app.verified_student_id', COALESCE(v_previous_student_id, ''), true
    );
    PERFORM pg_catalog.set_config(
      'app.verified_service_id', COALESCE(v_previous_service_id, ''), true
    );

    SELECT s.service_id INTO v_identity_service_id
    FROM public.students AS s
    WHERE s.id = v_student_id;

    UPDATE public.student_identity_review_requests
    SET status = 'linked', resolved_by = v_actor_id, resolved_at = pg_catalog.now()
    WHERE id = p_request_id;

    INSERT INTO public.student_identity_link_events (
      student_id, service_id, membership_id, action, decided_by,
      match_basis, request_fingerprint, review_request_id
    )
    VALUES (
      v_student_id, v_request.service_id, v_membership_id, 'linked_existing',
      v_actor_id,
      pg_catalog.jsonb_build_object(
        'resolved_from_review', true,
        'identity_owner_service_id', v_identity_service_id,
        'server_reverified_candidate', true,
        'name_similarity', v_match_score,
        'sensitive_data_included', false
      ),
      v_request.request_fingerprint,
      p_request_id
    );
  ELSE
    v_normalized_phone := private.normalize_phone(v_phone);
    v_student_id := pg_catalog.gen_random_uuid();
    v_membership_id := pg_catalog.gen_random_uuid();

    BEGIN
      INSERT INTO public.students (
        id, service_id, current_class_id, proposed_class_id, name, birth_date,
        phone, school, grade, enrollment_at, approval_status, photo_path, is_deacon
      )
      VALUES (
        v_student_id, v_request.service_id, v_class_id, v_proposed_class_id,
        pg_catalog.btrim(v_name), v_birth_date,
        NULLIF(pg_catalog.btrim(COALESCE(v_phone, '')), ''),
        COALESCE(NULLIF(pg_catalog.btrim(COALESCE(v_school, '')), ''), ''),
        pg_catalog.btrim(v_grade), v_enrollment_date,
        CASE WHEN v_status = 'active'
          THEN 'approved'::public.student_approval_status
          ELSE 'pending'::public.student_approval_status END,
        NULLIF(pg_catalog.btrim(COALESCE(v_photo_path, '')), ''),
        v_is_deacon
      );
    EXCEPTION WHEN unique_violation THEN
      RAISE EXCEPTION 'possible_duplicate' USING ERRCODE = '23505';
    END;

    INSERT INTO public.service_students (
      id, student_id, service_id, class_id, proposed_class_id, enrollment_date,
      status, school, grade, is_deacon
    )
    VALUES (
      v_membership_id, v_student_id, v_request.service_id, v_class_id,
      v_proposed_class_id, v_enrollment_date, v_status,
      NULLIF(pg_catalog.btrim(COALESCE(v_school, '')), ''),
      pg_catalog.btrim(v_grade), v_is_deacon
    );

    UPDATE public.student_identity_review_requests
    SET status = 'new_person', resolved_by = v_actor_id, resolved_at = pg_catalog.now()
    WHERE id = p_request_id;

    INSERT INTO public.student_identity_link_events (
      student_id, service_id, membership_id, action, decided_by,
      match_basis, request_fingerprint, review_request_id
    )
    VALUES (
      v_student_id, v_request.service_id, v_membership_id, 'created_new',
      v_actor_id,
      pg_catalog.jsonb_build_object(
        'resolved_from_review', true,
        'sensitive_data_included', false
      ),
      v_request.request_fingerprint,
      p_request_id
    );
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'decision', p_decision,
    'status', CASE WHEN p_decision = 'link_existing' THEN 'linked' ELSE 'new_person' END,
    'student_id', v_student_id,
    'membership_id', v_membership_id,
    'review_request_id', p_request_id
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.resolve_identity_review(uuid, text, uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.resolve_identity_review(uuid, text, uuid)
  TO authenticated;

CREATE OR REPLACE FUNCTION private.enforce_verified_student_membership_link()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_identity_service_id uuid;
BEGIN
  SELECT s.service_id INTO v_identity_service_id
  FROM public.students AS s
  WHERE s.id = NEW.student_id;

  IF v_identity_service_id IS NULL THEN
    RAISE EXCEPTION 'global_student_identity_not_found'
      USING ERRCODE = '23503';
  END IF;

  IF v_identity_service_id <> NEW.service_id
     AND (
       pg_catalog.current_setting('app.verified_link', true) IS DISTINCT FROM 'on'
       OR pg_catalog.current_setting('app.verified_student_id', true)
          IS DISTINCT FROM NEW.student_id::text
       OR pg_catalog.current_setting('app.verified_service_id', true)
          IS DISTINCT FROM NEW.service_id::text
     ) THEN
    RAISE EXCEPTION 'cross_service_identity_link_requires_verified_workflow'
      USING ERRCODE = '42501';
  END IF;

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.enforce_verified_student_membership_link()
  FROM PUBLIC, anon, authenticated, service_role;

DROP TRIGGER IF EXISTS trg_verified_student_membership_link
  ON public.service_students;
CREATE TRIGGER trg_verified_student_membership_link
BEFORE INSERT OR UPDATE OF student_id, service_id
ON public.service_students
FOR EACH ROW
EXECUTE FUNCTION private.enforce_verified_student_membership_link();
