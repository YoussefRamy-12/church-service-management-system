-- Spiritual Notebook membership-first cutover.
-- Preserve student identity and historical score snapshots; scope each weekly
-- submission to one service membership and its class at submission time.

ALTER TABLE public.spiritual_notebook_submissions
  ADD COLUMN IF NOT EXISTS class_id_at_submission uuid;

UPDATE public.spiritual_notebook_submissions s
SET class_id_at_submission = ss.class_id
FROM public.service_students ss
WHERE ss.id = s.service_student_id
  AND ss.service_id = s.service_id
  AND s.class_id_at_submission IS NULL;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.spiritual_notebook_submissions
    WHERE service_student_id IS NULL OR class_id_at_submission IS NULL
  ) THEN
    RAISE EXCEPTION 'Notebook membership/class backfill incomplete; refusing NOT NULL cutover';
  END IF;
END $$;

ALTER TABLE public.spiritual_notebook_submissions
  ALTER COLUMN service_student_id SET NOT NULL,
  ALTER COLUMN class_id_at_submission SET NOT NULL;

ALTER TABLE public.spiritual_notebook_submissions
  DROP CONSTRAINT IF EXISTS spiritual_submission_student_period_unique;

ALTER TABLE public.spiritual_notebook_submissions
  ADD CONSTRAINT spiritual_submission_membership_period_unique
  UNIQUE (service_student_id, period_start);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'spiritual_notebook_class_membership_service_fk'
      AND conrelid = 'public.spiritual_notebook_submissions'::regclass
  ) THEN
    ALTER TABLE public.spiritual_notebook_submissions
      ADD CONSTRAINT spiritual_notebook_class_membership_service_fk
      FOREIGN KEY (class_id_at_submission, service_id)
      REFERENCES public.classes(id, service_id)
      ON DELETE RESTRICT;
  END IF;
END $$;

DROP POLICY IF EXISTS notebook_submissions_read ON public.spiritual_notebook_submissions;
CREATE POLICY notebook_submissions_read
ON public.spiritual_notebook_submissions
FOR SELECT TO authenticated
USING (
  (SELECT private.can_access_service(service_id))
  AND EXISTS (
    SELECT 1
    FROM public.service_students ss
    WHERE ss.id = spiritual_notebook_submissions.service_student_id
      AND ss.student_id = spiritual_notebook_submissions.student_id
      AND ss.service_id = spiritual_notebook_submissions.service_id
      AND (SELECT private.can_access_class(
        spiritual_notebook_submissions.class_id_at_submission
      ))
  )
);

DROP POLICY IF EXISTS notebook_items_read ON public.spiritual_notebook_submission_items;
CREATE POLICY notebook_items_read
ON public.spiritual_notebook_submission_items
FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.spiritual_notebook_submissions s
    JOIN public.service_students ss
      ON ss.id = s.service_student_id
     AND ss.student_id = s.student_id
     AND ss.service_id = s.service_id
    WHERE s.id = spiritual_notebook_submission_items.submission_id
      AND (SELECT private.can_access_service(s.service_id))
      AND (SELECT private.can_access_class(s.class_id_at_submission))
  )
);

DROP FUNCTION IF EXISTS public.submit_spiritual_notebook(uuid,date,uuid[],integer,text,uuid);

CREATE OR REPLACE FUNCTION public.submit_spiritual_notebook(
  p_service_student_id uuid,
  p_period_start date,
  p_activity_ids uuid[],
  p_bonus_points integer DEFAULT 0,
  p_bonus_reason text DEFAULT NULL,
  p_operation_id uuid DEFAULT gen_random_uuid()
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_membership public.service_students%rowtype;
  v_actor public.servant_profiles%rowtype;
  v_settings public.spiritual_notebook_settings%rowtype;
  v_submission_id uuid;
  v_activity_points integer;
  v_activity_ids uuid[] := coalesce(p_activity_ids, '{}'::uuid[]);
  v_bonus_points integer := coalesce(p_bonus_points, 0);
BEGIN
  IF (SELECT auth.uid()) IS NULL THEN
    RAISE EXCEPTION 'authentication_required' USING ERRCODE = '28000';
  END IF;

  IF p_service_student_id IS NULL OR p_period_start IS NULL OR p_operation_id IS NULL THEN
    RAISE EXCEPTION 'required_submission_fields_missing' USING ERRCODE = '22023';
  END IF;

  SELECT ss.* INTO v_membership
  FROM public.service_students ss
  WHERE ss.id = p_service_student_id
    AND ss.status = 'active'
  FOR SHARE;

  IF v_membership.id IS NULL THEN
    RAISE EXCEPTION 'active_service_membership_not_found' USING ERRCODE = '42501';
  END IF;

  SELECT sp.* INTO v_actor
  FROM public.servant_profiles sp
  WHERE sp.auth_user_id = (SELECT auth.uid())
    AND sp.service_id = v_membership.service_id
    AND sp.account_status = 'active'
  LIMIT 1;

  IF v_actor.id IS NULL THEN
    RAISE EXCEPTION 'service_access_denied' USING ERRCODE = '42501';
  END IF;

  IF v_actor.role NOT IN (
    'overall_leader', 'overall_helper', 'stage_leader', 'class_leader', 'class_servant'
  ) THEN
    RAISE EXCEPTION 'role_not_allowed' USING ERRCODE = '42501';
  END IF;

  IF v_membership.class_id IS NULL
     OR NOT (SELECT private.can_access_class(v_membership.class_id)) THEN
    RAISE EXCEPTION 'student_out_of_scope' USING ERRCODE = '42501';
  END IF;

  IF extract(isodow FROM p_period_start) <> 5 THEN
    RAISE EXCEPTION 'invalid_period' USING ERRCODE = '22023';
  END IF;

  IF p_period_start < ((now() AT TIME ZONE 'Africa/Cairo')::date - 7)
     OR p_period_start > (now() AT TIME ZONE 'Africa/Cairo')::date THEN
    RAISE EXCEPTION 'period_out_of_range' USING ERRCODE = '22023';
  END IF;

  SELECT * INTO v_settings
  FROM public.spiritual_notebook_settings
  WHERE service_id = v_membership.service_id;

  IF v_settings.service_id IS NULL THEN
    RAISE EXCEPTION 'notebook_not_configured';
  END IF;

  IF v_bonus_points < 0 OR v_bonus_points > v_settings.max_bonus_points THEN
    RAISE EXCEPTION 'invalid_bonus' USING ERRCODE = '22023';
  END IF;

  IF v_bonus_points > 0
     AND (
       NOT (v_actor.role = ANY(v_settings.bonus_roles))
       OR nullif(btrim(p_bonus_reason), '') IS NULL
     ) THEN
    RAISE EXCEPTION 'bonus_not_authorized' USING ERRCODE = '42501';
  END IF;

  IF cardinality(v_activity_ids) = 0 AND NOT v_settings.allow_zero_submissions THEN
    RAISE EXCEPTION 'activity_required' USING ERRCODE = '22023';
  END IF;

  SELECT coalesce(sum(a.points), 0) INTO v_activity_points
  FROM public.spiritual_notebook_activities a
  WHERE a.service_id = v_membership.service_id
    AND a.is_active
    AND a.id = ANY(v_activity_ids);

  IF cardinality(v_activity_ids) <> (
    SELECT count(*)
    FROM public.spiritual_notebook_activities a
    WHERE a.service_id = v_membership.service_id
      AND a.is_active
      AND a.id = ANY(v_activity_ids)
  ) THEN
    RAISE EXCEPTION 'invalid_activity_selection' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.spiritual_notebook_submissions (
    id, service_id, student_id, service_student_id, class_id_at_submission,
    period_start, period_end, period_id, submitted_by,
    activity_points, bonus_points, bonus_reason, total_points
  )
  VALUES (
    p_operation_id, v_membership.service_id, v_membership.student_id,
    v_membership.id, v_membership.class_id,
    p_period_start, p_period_start + 6,
    to_char(p_period_start, 'YYYY-MM-DD') || '_' || to_char(p_period_start + 6, 'YYYY-MM-DD'),
    v_actor.id, v_activity_points, v_bonus_points,
    nullif(btrim(p_bonus_reason), ''), v_activity_points + v_bonus_points
  )
  ON CONFLICT (service_student_id, period_start) DO NOTHING
  RETURNING id INTO v_submission_id;

  IF v_submission_id IS NULL THEN
    SELECT s.id INTO v_submission_id
    FROM public.spiritual_notebook_submissions s
    WHERE s.service_student_id = v_membership.id
      AND s.period_start = p_period_start;

    IF v_submission_id <> p_operation_id THEN
      RAISE EXCEPTION 'already_submitted' USING ERRCODE = '23505';
    END IF;
    RETURN v_submission_id;
  END IF;

  INSERT INTO public.spiritual_notebook_submission_items (
    submission_id, activity_id, activity_name_snapshot,
    points_snapshot, category_name_snapshot
  )
  SELECT v_submission_id, a.id, a.name, a.points, c.name
  FROM public.spiritual_notebook_activities a
  LEFT JOIN public.spiritual_notebook_categories c
    ON c.id = a.category_id
   AND c.service_id = a.service_id
  WHERE a.service_id = v_membership.service_id
    AND a.is_active
    AND a.id = ANY(v_activity_ids);

  RETURN v_submission_id;
END;
$function$;

REVOKE ALL ON FUNCTION public.submit_spiritual_notebook(uuid,date,uuid[],integer,text,uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_spiritual_notebook(uuid,date,uuid[],integer,text,uuid)
  TO authenticated, service_role;
