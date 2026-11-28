-- Phase 2: shared servant person identity with service-scoped assignments.
-- Expand-only: legacy personal fields remain on servant_profiles and are dual-written.
-- Conflicting backfill values are recorded for review; latest updated profile supplies
-- the initial person snapshot. Duplicate phones across auth accounts are reported, not blocked.

CREATE OR REPLACE FUNCTION private.normalize_servant_name(p_value text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT pg_catalog.btrim(pg_catalog.lower(
    pg_catalog.regexp_replace(
      pg_catalog.regexp_replace(
        pg_catalog.translate(pg_catalog.btrim(COALESCE(p_value, '')), 'أإآىة', 'ااايه'),
        '[ً-ٟـٰ]', '', 'g'
      ),
      '[[:space:]]+', ' ', 'g'
    )
  ));
$$;

CREATE OR REPLACE FUNCTION private.normalize_servant_phone(p_value text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
SET search_path = ''
AS $$
DECLARE v_digits text;
BEGIN
  v_digits := pg_catalog.translate(
    COALESCE(p_value, ''),
    '٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹',
    '01234567890123456789'
  );
  v_digits := pg_catalog.regexp_replace(v_digits, '[^0-9]', '', 'g');
  IF v_digits = '' THEN RETURN NULL; END IF;
  IF v_digits ~ '^0020[0-9]{10}$' THEN
    RETURN '0' || pg_catalog.substring(v_digits FROM 5);
  ELSIF v_digits ~ '^20[0-9]{10}$' THEN
    RETURN '0' || pg_catalog.substring(v_digits FROM 3);
  ELSIF v_digits ~ '^[1-9][0-9]{9}$' THEN
    RETURN '0' || v_digits;
  END IF;
  RETURN v_digits;
END;
$$;
REVOKE ALL ON FUNCTION private.normalize_servant_name(text)
  FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.normalize_servant_phone(text)
  FROM PUBLIC, anon, authenticated, service_role;

CREATE TABLE IF NOT EXISTS public.servant_persons (
  auth_user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text NOT NULL,
  phone text,
  birth_date date,
  work_study text,
  photo_path text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.servant_persons ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.servant_persons FROM PUBLIC, anon, authenticated, service_role;
GRANT SELECT ON TABLE public.servant_persons TO authenticated;
GRANT UPDATE (full_name, phone, birth_date, work_study, photo_path)
  ON TABLE public.servant_persons TO authenticated;

CREATE TABLE IF NOT EXISTS public.servant_person_backfill_conflicts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conflict_type text NOT NULL CHECK (conflict_type IN (
    'conflicting_personal_values', 'phone_shared_by_multiple_accounts'
  )),
  auth_user_ids uuid[] NOT NULL,
  profile_ids uuid[] NOT NULL DEFAULT ARRAY[]::uuid[],
  conflicting_fields text[] NOT NULL DEFAULT ARRAY[]::text[],
  observed_values jsonb NOT NULL DEFAULT '[]'::jsonb
    CHECK (jsonb_typeof(observed_values) = 'array'),
  detected_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.servant_person_backfill_conflicts ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.servant_person_backfill_conflicts
  FROM PUBLIC, anon, authenticated, service_role;
GRANT SELECT ON TABLE public.servant_person_backfill_conflicts TO authenticated;
DROP POLICY IF EXISTS servant_person_backfill_conflicts_super_admin_read
  ON public.servant_person_backfill_conflicts;
CREATE POLICY servant_person_backfill_conflicts_super_admin_read
  ON public.servant_person_backfill_conflicts
  FOR SELECT TO authenticated
  USING ((SELECT private.is_super_admin()));

-- Populate each person from the most recently updated assignment. The conflict
-- report stores every disagreeing source row so the selected snapshot is reviewable.
INSERT INTO public.servant_persons (
  auth_user_id, full_name, phone, birth_date, work_study, created_at, updated_at
)
SELECT DISTINCT ON (sp.auth_user_id)
  sp.auth_user_id, sp.name, sp.phone, sp.birth_date, sp.work_study,
  COALESCE(sp.created_at, now()), COALESCE(sp.updated_at, now())
FROM public.servant_profiles AS sp
WHERE sp.auth_user_id IS NOT NULL
ORDER BY sp.auth_user_id, sp.updated_at DESC, sp.created_at DESC, sp.id
ON CONFLICT (auth_user_id) DO NOTHING;

INSERT INTO public.servant_person_backfill_conflicts (
  conflict_type, auth_user_ids, profile_ids, conflicting_fields, observed_values
)
SELECT
  'conflicting_personal_values',
  ARRAY[l.auth_user_id],
  array_agg(sp.id ORDER BY sp.updated_at DESC, sp.id),
  array_remove(ARRAY[
    CASE WHEN count(DISTINCT private.normalize_servant_name(sp.name)) > 1
      THEN 'full_name' END,
    CASE WHEN count(DISTINCT private.normalize_servant_phone(sp.phone)) > 1
      THEN 'phone' END,
    CASE WHEN count(DISTINCT sp.birth_date) > 1 THEN 'birth_date' END,
    CASE WHEN count(DISTINCT sp.work_study) > 1 THEN 'work_study' END
  ], NULL),
  jsonb_agg(jsonb_build_object(
    'profile_id', sp.id, 'updated_at', sp.updated_at, 'name', sp.name,
    'phone', sp.phone, 'birth_date', sp.birth_date, 'work_study', sp.work_study
  ) ORDER BY sp.updated_at DESC, sp.id)
FROM public.servant_profiles AS sp
JOIN (
  SELECT DISTINCT ON (auth_user_id) auth_user_id, id
  FROM public.servant_profiles
  WHERE auth_user_id IS NOT NULL
  ORDER BY auth_user_id, updated_at DESC, created_at DESC, id
) AS l ON l.auth_user_id = sp.auth_user_id
WHERE sp.auth_user_id IS NOT NULL
GROUP BY l.auth_user_id
HAVING count(DISTINCT private.normalize_servant_name(sp.name)) > 1
    OR count(DISTINCT private.normalize_servant_phone(sp.phone)) > 1
    OR count(DISTINCT sp.birth_date) > 1
    OR count(DISTINCT sp.work_study) > 1;

-- Existing scoped phone uniqueness would reject another auth account with the same
-- phone in a service. Replace it with a lookup index; duplicate phones are reported.
ALTER TABLE public.servant_profiles
  DROP CONSTRAINT IF EXISTS servant_profiles_service_phone_unique;
CREATE INDEX IF NOT EXISTS servant_profiles_service_phone_lookup_idx
  ON public.servant_profiles (service_id, phone);

CREATE INDEX IF NOT EXISTS servant_persons_phone_lookup_idx
  ON public.servant_persons (private.normalize_servant_phone(phone))
  WHERE phone IS NOT NULL;

INSERT INTO public.servant_person_backfill_conflicts (
  conflict_type, auth_user_ids, conflicting_fields, observed_values
)
SELECT
  'phone_shared_by_multiple_accounts',
  array_agg(p.auth_user_id ORDER BY p.auth_user_id),
  ARRAY['phone']::text[],
  jsonb_agg(jsonb_build_object(
    'auth_user_id', p.auth_user_id,
    'full_name', p.full_name,
    'phone', p.phone
  ) ORDER BY p.auth_user_id)
FROM public.servant_persons AS p
WHERE private.normalize_servant_phone(p.phone) IS NOT NULL
GROUP BY private.normalize_servant_phone(p.phone)
HAVING count(DISTINCT p.auth_user_id) > 1;

-- Every existing service profile now points to its canonical person row.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.servant_profiles'::regclass
      AND conname = 'servant_profiles_person_fkey'
  ) THEN
    ALTER TABLE public.servant_profiles
      ADD CONSTRAINT servant_profiles_person_fkey
      FOREIGN KEY (auth_user_id)
      REFERENCES public.servant_persons(auth_user_id)
      ON DELETE RESTRICT NOT VALID;
  END IF;
END;
$$;
ALTER TABLE public.servant_profiles
  VALIDATE CONSTRAINT servant_profiles_person_fkey;

DROP POLICY IF EXISTS servant_persons_read
  ON public.servant_persons;
CREATE POLICY servant_persons_read
  ON public.servant_persons
  FOR SELECT TO authenticated
  USING (
    auth_user_id = (SELECT auth.uid())
    OR (SELECT private.is_super_admin())
    OR EXISTS (
      SELECT 1
      FROM public.servant_profiles AS sp
      WHERE sp.auth_user_id = servant_persons.auth_user_id
        AND (SELECT private.is_overall_admin_for_service(sp.service_id))
    )
  );

DROP POLICY IF EXISTS servant_persons_update
  ON public.servant_persons;
CREATE POLICY servant_persons_update
  ON public.servant_persons
  FOR UPDATE TO authenticated
  USING (
    auth_user_id = (SELECT auth.uid())
    OR (SELECT private.is_super_admin())
    OR EXISTS (
      SELECT 1
      FROM public.servant_profiles AS sp
      WHERE sp.auth_user_id = servant_persons.auth_user_id
        AND (SELECT private.is_overall_admin_for_service(sp.service_id))
    )
  )
  WITH CHECK (
    auth_user_id = (SELECT auth.uid())
    OR (SELECT private.is_super_admin())
    OR EXISTS (
      SELECT 1
      FROM public.servant_profiles AS sp
      WHERE sp.auth_user_id = servant_persons.auth_user_id
        AND (SELECT private.is_overall_admin_for_service(sp.service_id))
    )
  );

CREATE OR REPLACE FUNCTION private.sync_servant_profile_person_fields()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_previous text;
  v_person public.servant_persons%ROWTYPE;
BEGIN
  IF pg_catalog.current_setting('app.syncing_servant_person', true) = 'on'
     OR NEW.auth_user_id IS NULL THEN
    RETURN NEW;
  END IF;
  IF TG_OP = 'UPDATE'
     AND NEW.name IS NOT DISTINCT FROM OLD.name
     AND NEW.phone IS NOT DISTINCT FROM OLD.phone
     AND NEW.birth_date IS NOT DISTINCT FROM OLD.birth_date
     AND NEW.work_study IS NOT DISTINCT FROM OLD.work_study THEN
    RETURN NEW;
  END IF;

  v_previous := pg_catalog.current_setting('app.syncing_servant_person', true);
  PERFORM pg_catalog.set_config('app.syncing_servant_person', 'on', true);

  SELECT p.* INTO v_person
  FROM public.servant_persons AS p
  WHERE p.auth_user_id = NEW.auth_user_id;

  IF TG_OP = 'INSERT' AND FOUND THEN
    -- Existing people keep their canonical fields when a service assignment is added.
    UPDATE public.servant_profiles
    SET name = v_person.full_name,
        phone = COALESCE(v_person.phone, ''),
        birth_date = COALESCE(v_person.birth_date, NEW.birth_date),
        work_study = COALESCE(v_person.work_study, NEW.work_study)
    WHERE id = NEW.id
      AND (name, phone, birth_date, work_study) IS DISTINCT FROM
          (v_person.full_name, COALESCE(v_person.phone, ''),
           COALESCE(v_person.birth_date, NEW.birth_date),
           COALESCE(v_person.work_study, NEW.work_study));
  ELSIF TG_OP = 'INSERT' THEN
    INSERT INTO public.servant_persons (
      auth_user_id, full_name, phone, birth_date, work_study
    ) VALUES (
      NEW.auth_user_id, NEW.name, NEW.phone, NEW.birth_date, NEW.work_study
    )
    ON CONFLICT (auth_user_id) DO NOTHING;
  ELSE
    INSERT INTO public.servant_persons (
      auth_user_id, full_name, phone, birth_date, work_study
    ) VALUES (
      NEW.auth_user_id, NEW.name, NEW.phone, NEW.birth_date, NEW.work_study
    )
    ON CONFLICT (auth_user_id) DO UPDATE SET
      full_name = EXCLUDED.full_name,
      phone = EXCLUDED.phone,
      birth_date = EXCLUDED.birth_date,
      work_study = EXCLUDED.work_study,
      updated_at = now()
    WHERE (public.servant_persons.full_name, public.servant_persons.phone,
           public.servant_persons.birth_date, public.servant_persons.work_study)
      IS DISTINCT FROM
          (EXCLUDED.full_name, EXCLUDED.phone,
           EXCLUDED.birth_date, EXCLUDED.work_study);
  END IF;

  PERFORM pg_catalog.set_config(
    'app.syncing_servant_person', COALESCE(v_previous, 'off'), true
  );
  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION private.sync_servant_profile_person_fields()
  FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION private.sync_servant_person_profile_fields()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_previous text;
BEGIN
  IF TG_OP = 'UPDATE'
     AND NEW.full_name IS NOT DISTINCT FROM OLD.full_name
     AND NEW.phone IS NOT DISTINCT FROM OLD.phone
     AND NEW.birth_date IS NOT DISTINCT FROM OLD.birth_date
     AND NEW.work_study IS NOT DISTINCT FROM OLD.work_study
     AND NEW.photo_path IS NOT DISTINCT FROM OLD.photo_path THEN
    RETURN NEW;
  END IF;
  v_previous := pg_catalog.current_setting('app.syncing_servant_person', true);
  PERFORM pg_catalog.set_config('app.syncing_servant_person', 'on', true);
  UPDATE public.servant_profiles AS sp
  SET name = NEW.full_name,
      phone = COALESCE(NEW.phone, ''),
      birth_date = COALESCE(NEW.birth_date, sp.birth_date),
      work_study = COALESCE(NEW.work_study, ''),
      updated_at = now()
  WHERE sp.auth_user_id = NEW.auth_user_id
    AND (sp.name, sp.phone, sp.birth_date, sp.work_study) IS DISTINCT FROM
        (NEW.full_name, COALESCE(NEW.phone, ''), COALESCE(NEW.birth_date, sp.birth_date),
         COALESCE(NEW.work_study, ''));
  PERFORM pg_catalog.set_config(
    'app.syncing_servant_person', COALESCE(v_previous, 'off'), true
  );
  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION private.sync_servant_person_profile_fields()
  FROM PUBLIC, anon, authenticated, service_role;

DROP TRIGGER IF EXISTS servant_profile_person_fields_sync
  ON public.servant_profiles;
CREATE TRIGGER servant_profile_person_fields_sync
AFTER INSERT OR UPDATE OF name, phone, birth_date, work_study
ON public.servant_profiles
FOR EACH ROW EXECUTE FUNCTION private.sync_servant_profile_person_fields();

DROP TRIGGER IF EXISTS servant_person_profile_fields_sync
  ON public.servant_persons;
CREATE TRIGGER servant_person_profile_fields_sync
AFTER UPDATE OF full_name, phone, birth_date, work_study, photo_path
ON public.servant_persons
FOR EACH ROW EXECUTE FUNCTION private.sync_servant_person_profile_fields();

CREATE OR REPLACE FUNCTION public.find_servant_candidates(
  p_name text,
  p_phone text
)
RETURNS TABLE (
  auth_user_id uuid,
  full_name text,
  phone_suffix text,
  service_names text[]
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_name text;
  v_phone text;
BEGIN
  IF (SELECT auth.uid()) IS NULL
     OR (
       NOT (SELECT private.is_super_admin())
       AND NOT EXISTS (
         SELECT 1
         FROM public.servant_profiles AS mine
         WHERE mine.auth_user_id = (SELECT auth.uid())
           AND (SELECT private.is_overall_admin_for_service(mine.service_id))
       )
     ) THEN
    RAISE EXCEPTION 'overall_admin_required' USING ERRCODE = '42501';
  END IF;

  v_name := private.normalize_servant_name(p_name);
  v_phone := private.normalize_servant_phone(p_phone);
  IF COALESCE(pg_catalog.char_length(v_name), 0) < 3
     AND COALESCE(pg_catalog.char_length(v_phone), 0) < 7 THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT p.auth_user_id, p.full_name,
         CASE WHEN p.phone IS NULL THEN NULL
              ELSE pg_catalog.right(private.normalize_servant_phone(p.phone), 4) END,
         COALESCE(array_agg(DISTINCT s.name ORDER BY s.name)
           FILTER (WHERE s.id IS NOT NULL), ARRAY[]::text[])
  FROM public.servant_persons AS p
  LEFT JOIN public.servant_profiles AS sp ON sp.auth_user_id = p.auth_user_id
  LEFT JOIN public.services AS s ON s.id = sp.service_id
  WHERE (
    COALESCE(pg_catalog.char_length(v_name), 0) >= 3
    AND pg_catalog.position(v_name IN private.normalize_servant_name(p.full_name)) > 0
  ) OR (
    COALESCE(pg_catalog.char_length(v_phone), 0) >= 7
    AND private.normalize_servant_phone(p.phone) LIKE v_phone || '%'
  )
  GROUP BY p.auth_user_id, p.full_name, p.phone
  ORDER BY p.full_name, p.auth_user_id
  LIMIT 10;
END;
$$;
REVOKE ALL ON FUNCTION public.find_servant_candidates(text, text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.find_servant_candidates(text, text)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.assign_servant_to_service(
  p_auth_user_id uuid,
  p_service_id uuid,
  p_role text,
  p_stage_id uuid,
  p_class_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_person public.servant_persons%ROWTYPE;
  v_profile_id uuid;
BEGIN
  IF (SELECT auth.uid()) IS NULL
     OR (
       NOT (SELECT private.is_super_admin())
       AND NOT (SELECT private.is_overall_admin_for_service(p_service_id))
     ) THEN
    RAISE EXCEPTION 'overall_admin_required_for_service' USING ERRCODE = '42501';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.services WHERE id = p_service_id) THEN
    RAISE EXCEPTION 'service_not_found' USING ERRCODE = '22023';
  END IF;
  IF p_auth_user_id IS NULL THEN
    RAISE EXCEPTION 'auth_user_id_required' USING ERRCODE = '22023';
  END IF;
  SELECT p.* INTO v_person
  FROM public.servant_persons AS p
  WHERE p.auth_user_id = p_auth_user_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'servant_person_not_found' USING ERRCODE = 'P0002';
  END IF;
  IF COALESCE(NULLIF(pg_catalog.btrim(v_person.full_name), ''), '') = ''
     OR COALESCE(NULLIF(pg_catalog.btrim(v_person.phone), ''), '') = ''
     OR v_person.birth_date IS NULL
     OR COALESCE(NULLIF(pg_catalog.btrim(v_person.work_study), ''), '') = '' THEN
    RAISE EXCEPTION 'servant_profile_incomplete' USING ERRCODE = '22023';
  END IF;

  IF p_role IN ('overall_leader', 'overall_helper') THEN
    IF p_stage_id IS NOT NULL OR p_class_id IS NOT NULL THEN
      RAISE EXCEPTION 'service_wide_role_has_no_stage_or_class' USING ERRCODE = '23514';
    END IF;
  ELSIF p_role = 'stage_leader' THEN
    IF p_stage_id IS NULL OR p_class_id IS NOT NULL OR NOT EXISTS (
      SELECT 1 FROM public.stages
      WHERE id = p_stage_id AND service_id = p_service_id
    ) THEN
      RAISE EXCEPTION 'stage_must_belong_to_service' USING ERRCODE = '23514';
    END IF;
  ELSIF p_role IN ('class_leader', 'class_servant') THEN
    IF p_class_id IS NULL OR p_stage_id IS NOT NULL OR NOT EXISTS (
      SELECT 1 FROM public.classes AS c
      JOIN public.stages AS st ON st.id = c.stage_id
      WHERE c.id = p_class_id AND st.service_id = p_service_id
    ) THEN
      RAISE EXCEPTION 'class_must_belong_to_service' USING ERRCODE = '23514';
    END IF;
  ELSE
    RAISE EXCEPTION 'invalid_servant_role' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.servant_profiles (
    auth_user_id, service_id, name, phone, birth_date, work_study,
    role, stage_id, class_id, account_status
  ) VALUES (
    p_auth_user_id, p_service_id, v_person.full_name,
    COALESCE(v_person.phone, ''), v_person.birth_date,
    COALESCE(v_person.work_study, ''), p_role::public.servant_role,
    p_stage_id, p_class_id, 'active'::public.servant_account_status
  )
  ON CONFLICT (auth_user_id, service_id) DO UPDATE SET
    name = EXCLUDED.name,
    phone = EXCLUDED.phone,
    birth_date = EXCLUDED.birth_date,
    work_study = EXCLUDED.work_study,
    role = EXCLUDED.role,
    stage_id = EXCLUDED.stage_id,
    class_id = EXCLUDED.class_id,
    account_status = 'active'::public.servant_account_status,
    updated_at = now()
  RETURNING id INTO v_profile_id;

  RETURN v_profile_id;
END;
$$;
REVOKE ALL ON FUNCTION public.assign_servant_to_service(uuid, uuid, text, uuid, uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.assign_servant_to_service(uuid, uuid, text, uuid, uuid)
  TO authenticated;

COMMENT ON TABLE public.servant_persons IS
  'Shared servant identity. Legacy servant_profiles personal fields remain dual-written during migration.';
COMMENT ON TABLE public.servant_person_backfill_conflicts IS
  'Review-only report of disagreeing legacy identity values and phone numbers shared by different auth accounts.';
