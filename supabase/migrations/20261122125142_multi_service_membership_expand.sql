-- Multi-Service Architecture v2.0 — additive membership expansion.
-- Applied to the connected Supabase project as migration 20261122125142.
-- Legacy student columns remain during the dual-read/dual-write compatibility window.

ALTER TABLE public.classes ADD COLUMN IF NOT EXISTS service_id uuid;
UPDATE public.classes c SET service_id = st.service_id
FROM public.stages st WHERE st.id = c.stage_id AND c.service_id IS NULL;
ALTER TABLE public.classes ALTER COLUMN service_id SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='stages_id_service_unique') THEN
    ALTER TABLE public.stages ADD CONSTRAINT stages_id_service_unique UNIQUE (id, service_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='classes_id_service_unique') THEN
    ALTER TABLE public.classes ADD CONSTRAINT classes_id_service_unique UNIQUE (id, service_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='classes_stage_service_fk') THEN
    ALTER TABLE public.classes ADD CONSTRAINT classes_stage_service_fk
      FOREIGN KEY (stage_id, service_id) REFERENCES public.stages(id, service_id) ON DELETE RESTRICT;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.service_students (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  service_id uuid NOT NULL REFERENCES public.services(id) ON DELETE RESTRICT,
  class_id uuid,
  proposed_class_id uuid,
  enrollment_date timestamptz NOT NULL DEFAULT now(),
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','active','inactive','graduated','rejected')),
  school text,
  grade text,
  is_deacon boolean NOT NULL DEFAULT false,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT service_students_student_service_unique UNIQUE (student_id, service_id),
  CONSTRAINT service_students_id_service_unique UNIQUE (id, service_id),
  CONSTRAINT service_students_class_service_fk
    FOREIGN KEY (class_id, service_id) REFERENCES public.classes(id, service_id) ON DELETE RESTRICT,
  CONSTRAINT service_students_proposed_class_service_fk
    FOREIGN KEY (proposed_class_id, service_id) REFERENCES public.classes(id, service_id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_service_students_service_status ON public.service_students(service_id, status);
CREATE INDEX IF NOT EXISTS idx_service_students_class_status ON public.service_students(service_id, class_id, status);
CREATE INDEX IF NOT EXISTS idx_service_students_student ON public.service_students(student_id);

INSERT INTO public.service_students
  (student_id, service_id, class_id, proposed_class_id, enrollment_date, status,
   school, grade, is_deacon, notes, created_at, updated_at)
SELECT s.id, s.service_id, s.current_class_id, s.proposed_class_id,
       s.enrollment_at,
       CASE WHEN s.approval_status::text = 'pending' THEN 'pending' ELSE 'active' END,
       s.school, s.grade, s.is_deacon, s.notes, s.created_at, s.updated_at
FROM public.students s
ON CONFLICT (student_id, service_id) DO NOTHING;

ALTER TABLE public.attendance_records
  ADD COLUMN IF NOT EXISTS service_id uuid,
  ADD COLUMN IF NOT EXISTS service_student_id uuid;
UPDATE public.attendance_records ar
SET service_id = m.service_id
FROM public.meetings m WHERE m.id = ar.meeting_id AND ar.service_id IS NULL;
UPDATE public.attendance_records ar
SET service_student_id = ss.id
FROM public.service_students ss
WHERE ss.student_id = ar.student_id AND ss.service_id = ar.service_id
  AND ar.service_student_id IS NULL;
ALTER TABLE public.attendance_records ALTER COLUMN service_id SET NOT NULL;
ALTER TABLE public.attendance_records ALTER COLUMN service_student_id SET NOT NULL;

ALTER TABLE public.follow_up_records
  ADD COLUMN IF NOT EXISTS service_id uuid,
  ADD COLUMN IF NOT EXISTS service_student_id uuid;
UPDATE public.follow_up_records f
SET service_id = s.service_id FROM public.students s
WHERE s.id = f.student_id AND f.service_id IS NULL;
UPDATE public.follow_up_records f
SET service_student_id = ss.id FROM public.service_students ss
WHERE ss.student_id = f.student_id AND ss.service_id = f.service_id
  AND f.service_student_id IS NULL;
ALTER TABLE public.follow_up_records ALTER COLUMN service_id SET NOT NULL;
ALTER TABLE public.follow_up_records ALTER COLUMN service_student_id SET NOT NULL;

ALTER TABLE public.follow_up_cases ADD COLUMN IF NOT EXISTS service_student_id uuid;
UPDATE public.follow_up_cases c
SET service_student_id = ss.id FROM public.service_students ss
WHERE ss.student_id = c.student_id AND ss.service_id = c.service_id
  AND c.service_student_id IS NULL;
ALTER TABLE public.follow_up_cases ALTER COLUMN service_student_id SET NOT NULL;

ALTER TABLE public.spiritual_notebook_submissions ADD COLUMN IF NOT EXISTS service_student_id uuid;
UPDATE public.spiritual_notebook_submissions n
SET service_student_id = ss.id FROM public.service_students ss
WHERE ss.student_id = n.student_id AND ss.service_id = n.service_id
  AND n.service_student_id IS NULL;
ALTER TABLE public.spiritual_notebook_submissions ALTER COLUMN service_student_id SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='attendance_records_service_fk') THEN
    ALTER TABLE public.attendance_records ADD CONSTRAINT attendance_records_service_fk
      FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE RESTRICT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='attendance_records_membership_service_fk') THEN
    ALTER TABLE public.attendance_records ADD CONSTRAINT attendance_records_membership_service_fk
      FOREIGN KEY (service_student_id, service_id) REFERENCES public.service_students(id, service_id) ON DELETE RESTRICT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='follow_up_records_service_fk') THEN
    ALTER TABLE public.follow_up_records ADD CONSTRAINT follow_up_records_service_fk
      FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE RESTRICT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='follow_up_records_membership_service_fk') THEN
    ALTER TABLE public.follow_up_records ADD CONSTRAINT follow_up_records_membership_service_fk
      FOREIGN KEY (service_student_id, service_id) REFERENCES public.service_students(id, service_id) ON DELETE RESTRICT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='follow_up_cases_membership_service_fk') THEN
    ALTER TABLE public.follow_up_cases ADD CONSTRAINT follow_up_cases_membership_service_fk
      FOREIGN KEY (service_student_id, service_id) REFERENCES public.service_students(id, service_id) ON DELETE RESTRICT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='follow_up_cases_class_service_fk') THEN
    ALTER TABLE public.follow_up_cases ADD CONSTRAINT follow_up_cases_class_service_fk
      FOREIGN KEY (class_id, service_id) REFERENCES public.classes(id, service_id) ON DELETE RESTRICT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='spiritual_notebook_membership_service_fk') THEN
    ALTER TABLE public.spiritual_notebook_submissions ADD CONSTRAINT spiritual_notebook_membership_service_fk
      FOREIGN KEY (service_student_id, service_id) REFERENCES public.service_students(id, service_id) ON DELETE RESTRICT;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_attendance_membership_meeting ON public.attendance_records(service_student_id, meeting_id);
CREATE INDEX IF NOT EXISTS idx_follow_up_records_membership ON public.follow_up_records(service_student_id, follow_up_date DESC);
CREATE INDEX IF NOT EXISTS idx_follow_up_cases_membership ON public.follow_up_cases(service_student_id);
CREATE INDEX IF NOT EXISTS idx_notebook_submissions_membership ON public.spiritual_notebook_submissions(service_student_id, period_start);

ALTER TABLE public.service_students ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE ON public.service_students TO authenticated;
GRANT ALL ON public.service_students TO service_role;

DROP POLICY IF EXISTS service_students_select ON public.service_students;
CREATE POLICY service_students_select ON public.service_students FOR SELECT TO authenticated
USING (
  (SELECT private.is_super_admin())
  OR ((SELECT private.can_access_service(service_id))
      AND ((SELECT private.is_overall_admin_for_service(service_id))
           OR (SELECT private.can_access_class(coalesce(class_id, proposed_class_id)))))
);

DROP POLICY IF EXISTS service_students_insert ON public.service_students;
CREATE POLICY service_students_insert ON public.service_students FOR INSERT TO authenticated
WITH CHECK (
  (SELECT private.is_super_admin())
  OR ((SELECT private.is_overall_admin_for_service(service_id))
      AND (class_id IS NULL OR (SELECT private.can_access_class(class_id)))
      AND (proposed_class_id IS NULL OR (SELECT private.can_access_class(proposed_class_id))))
);

DROP POLICY IF EXISTS service_students_update ON public.service_students;
CREATE POLICY service_students_update ON public.service_students FOR UPDATE TO authenticated
USING (
  (SELECT private.is_super_admin())
  OR ((SELECT private.can_access_service(service_id))
      AND ((SELECT private.is_overall_admin_for_service(service_id))
           OR (SELECT private.can_access_class(coalesce(class_id, proposed_class_id)))))
)
WITH CHECK (
  (SELECT private.is_super_admin())
  OR ((SELECT private.is_overall_admin_for_service(service_id))
      AND (class_id IS NULL OR (SELECT private.can_access_class(class_id)))
      AND (proposed_class_id IS NULL OR (SELECT private.can_access_class(proposed_class_id))))
);

CREATE OR REPLACE FUNCTION private.populate_service_membership_reference()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF TG_TABLE_NAME = 'attendance_records' AND NEW.service_id IS NULL THEN
    SELECT m.service_id INTO NEW.service_id FROM public.meetings m WHERE m.id = NEW.meeting_id;
  ELSIF TG_TABLE_NAME = 'follow_up_records' AND NEW.service_id IS NULL THEN
    SELECT s.service_id INTO NEW.service_id FROM public.students s WHERE s.id = NEW.student_id;
  END IF;
  IF NEW.service_student_id IS NULL THEN
    SELECT ss.id INTO NEW.service_student_id
    FROM public.service_students ss
    WHERE ss.student_id = NEW.student_id AND ss.service_id = NEW.service_id;
  END IF;
  IF NEW.service_id IS NULL OR NEW.service_student_id IS NULL THEN
    RAISE EXCEPTION 'valid_service_membership_required' USING ERRCODE = '23503';
  END IF;
  RETURN NEW;
END;
$function$;
REVOKE ALL ON FUNCTION private.populate_service_membership_reference() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS aaa_populate_attendance_membership ON public.attendance_records;
CREATE TRIGGER aaa_populate_attendance_membership
BEFORE INSERT OR UPDATE OF meeting_id, student_id, service_id, service_student_id
ON public.attendance_records FOR EACH ROW EXECUTE FUNCTION private.populate_service_membership_reference();

DROP TRIGGER IF EXISTS aaa_populate_follow_up_membership ON public.follow_up_records;
CREATE TRIGGER aaa_populate_follow_up_membership
BEFORE INSERT OR UPDATE OF student_id, service_id, service_student_id
ON public.follow_up_records FOR EACH ROW EXECUTE FUNCTION private.populate_service_membership_reference();

DROP TRIGGER IF EXISTS aaa_populate_follow_up_case_membership ON public.follow_up_cases;
CREATE TRIGGER aaa_populate_follow_up_case_membership
BEFORE INSERT OR UPDATE OF student_id, service_id, service_student_id
ON public.follow_up_cases FOR EACH ROW EXECUTE FUNCTION private.populate_service_membership_reference();

DROP TRIGGER IF EXISTS aaa_populate_notebook_membership ON public.spiritual_notebook_submissions;
CREATE TRIGGER aaa_populate_notebook_membership
BEFORE INSERT OR UPDATE OF student_id, service_id, service_student_id
ON public.spiritual_notebook_submissions FOR EACH ROW EXECUTE FUNCTION private.populate_service_membership_reference();

CREATE OR REPLACE FUNCTION public.validate_hierarchy_integrity()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF TG_TABLE_NAME = 'servant_profiles' THEN
    IF NEW.stage_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM public.stages s WHERE s.id = NEW.stage_id AND s.service_id = NEW.service_id
    ) THEN RAISE EXCEPTION 'Servant stage must belong to the same service'; END IF;
    IF NEW.class_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM public.classes c WHERE c.id = NEW.class_id AND c.service_id = NEW.service_id
    ) THEN RAISE EXCEPTION 'Servant class must belong to the same service'; END IF;
  ELSIF TG_TABLE_NAME = 'students' THEN
    IF NEW.current_class_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM public.classes c WHERE c.id = NEW.current_class_id AND c.service_id = NEW.service_id
    ) THEN RAISE EXCEPTION 'Student current class must belong to the same service'; END IF;
    IF NEW.proposed_class_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM public.classes c WHERE c.id = NEW.proposed_class_id AND c.service_id = NEW.service_id
    ) THEN RAISE EXCEPTION 'Student proposed class must belong to the same service'; END IF;
  ELSIF TG_TABLE_NAME = 'attendance_records' THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.meetings m
      JOIN public.service_students ss ON ss.id = NEW.service_student_id
        AND ss.student_id = NEW.student_id AND ss.service_id = NEW.service_id
      JOIN public.classes c ON c.id = NEW.class_id_at_attendance AND c.service_id = NEW.service_id
      WHERE m.id = NEW.meeting_id AND m.service_id = NEW.service_id
    ) THEN RAISE EXCEPTION 'Attendance meeting, membership and class must belong to the same service'; END IF;
  ELSIF TG_TABLE_NAME = 'follow_up_records' THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.service_students ss
      JOIN public.servant_profiles sp ON sp.id = NEW.created_by AND sp.service_id = NEW.service_id
      WHERE ss.id = NEW.service_student_id AND ss.student_id = NEW.student_id AND ss.service_id = NEW.service_id
    ) THEN RAISE EXCEPTION 'Follow-up membership and creator must belong to the same service'; END IF;
  ELSIF TG_TABLE_NAME = 'reporting_periods' THEN
    IF NOT EXISTS (SELECT 1 FROM public.services s WHERE s.id = NEW.service_id) THEN
      RAISE EXCEPTION 'Reporting period service does not exist';
    END IF;
  END IF;
  RETURN NEW;
END;
$function$;

DROP POLICY IF EXISTS attendance_membership_select ON public.attendance_records;
CREATE POLICY attendance_membership_select ON public.attendance_records FOR SELECT TO authenticated
USING (EXISTS (
  SELECT 1 FROM public.service_students ss
  JOIN public.meetings m ON m.id = attendance_records.meeting_id
  WHERE ss.id = attendance_records.service_student_id
    AND ss.service_id = attendance_records.service_id
    AND ss.student_id = attendance_records.student_id
    AND m.service_id = attendance_records.service_id
    AND (SELECT private.can_access_service(attendance_records.service_id))
    AND ((SELECT private.is_overall_admin_for_service(attendance_records.service_id))
         OR (SELECT private.can_access_class(attendance_records.class_id_at_attendance)))
));

DROP POLICY IF EXISTS attendance_membership_insert ON public.attendance_records;
CREATE POLICY attendance_membership_insert ON public.attendance_records FOR INSERT TO authenticated
WITH CHECK (EXISTS (
  SELECT 1 FROM public.service_students ss
  JOIN public.meetings m ON m.id = attendance_records.meeting_id
  JOIN public.servant_profiles sp ON sp.id = attendance_records.recorded_by
    AND sp.auth_user_id = (SELECT auth.uid())
    AND sp.service_id = attendance_records.service_id
    AND sp.account_status = 'active'
  WHERE ss.id = attendance_records.service_student_id
    AND ss.service_id = attendance_records.service_id
    AND ss.student_id = attendance_records.student_id
    AND m.service_id = attendance_records.service_id
    AND (SELECT private.can_access_service(attendance_records.service_id))
    AND (SELECT private.can_access_class(attendance_records.class_id_at_attendance))
));

DROP POLICY IF EXISTS attendance_membership_update ON public.attendance_records;
CREATE POLICY attendance_membership_update ON public.attendance_records FOR UPDATE TO authenticated
USING ((SELECT private.can_access_service(service_id))
  AND ((SELECT private.is_overall_admin_for_service(service_id))
       OR (SELECT private.can_access_class(class_id_at_attendance))))
WITH CHECK (EXISTS (
  SELECT 1 FROM public.service_students ss
  JOIN public.meetings m ON m.id = attendance_records.meeting_id
  WHERE ss.id = attendance_records.service_student_id
    AND ss.service_id = attendance_records.service_id
    AND ss.student_id = attendance_records.student_id
    AND m.service_id = attendance_records.service_id
    AND (SELECT private.can_access_service(attendance_records.service_id))
    AND ((SELECT private.is_overall_admin_for_service(attendance_records.service_id))
         OR (SELECT private.can_access_class(attendance_records.class_id_at_attendance)))
));

DROP POLICY IF EXISTS follow_up_records_membership_select ON public.follow_up_records;
CREATE POLICY follow_up_records_membership_select ON public.follow_up_records FOR SELECT TO authenticated
USING (EXISTS (
  SELECT 1 FROM public.service_students ss
  WHERE ss.id = follow_up_records.service_student_id
    AND ss.student_id = follow_up_records.student_id
    AND ss.service_id = follow_up_records.service_id
    AND (SELECT private.can_access_service(follow_up_records.service_id))
    AND ((SELECT private.is_overall_admin_for_service(follow_up_records.service_id))
         OR (SELECT private.can_access_class(coalesce(ss.class_id, ss.proposed_class_id))))
));

DROP POLICY IF EXISTS follow_up_records_membership_insert ON public.follow_up_records;
CREATE POLICY follow_up_records_membership_insert ON public.follow_up_records FOR INSERT TO authenticated
WITH CHECK (EXISTS (
  SELECT 1 FROM public.service_students ss
  JOIN public.servant_profiles sp ON sp.id = follow_up_records.created_by
    AND sp.auth_user_id = (SELECT auth.uid())
    AND sp.service_id = follow_up_records.service_id
    AND sp.account_status = 'active'
  WHERE ss.id = follow_up_records.service_student_id
    AND ss.student_id = follow_up_records.student_id
    AND ss.service_id = follow_up_records.service_id
    AND (SELECT private.can_access_service(follow_up_records.service_id))
    AND ((SELECT private.is_overall_admin_for_service(follow_up_records.service_id))
         OR (SELECT private.can_access_class(coalesce(ss.class_id, ss.proposed_class_id))))
));

DROP POLICY IF EXISTS follow_up_records_membership_update ON public.follow_up_records;
CREATE POLICY follow_up_records_membership_update ON public.follow_up_records FOR UPDATE TO authenticated
USING ((SELECT private.can_access_service(service_id))
  AND ((SELECT private.is_overall_admin_for_service(service_id))
       OR EXISTS (SELECT 1 FROM public.service_students ss WHERE ss.id = follow_up_records.service_student_id
         AND (SELECT private.can_access_class(coalesce(ss.class_id, ss.proposed_class_id))))))
WITH CHECK (EXISTS (
  SELECT 1 FROM public.service_students ss
  WHERE ss.id = follow_up_records.service_student_id
    AND ss.student_id = follow_up_records.student_id
    AND ss.service_id = follow_up_records.service_id
    AND (SELECT private.can_access_service(follow_up_records.service_id))
    AND ((SELECT private.is_overall_admin_for_service(follow_up_records.service_id))
         OR (SELECT private.can_access_class(coalesce(ss.class_id, ss.proposed_class_id))))
));

DROP POLICY IF EXISTS "active system administrators can manage students" ON public.students;

REVOKE EXECUTE ON FUNCTION public.is_active_system_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_active_system_admin() TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.is_active_service_schedule_leader(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_active_service_schedule_leader(text) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.review_weekly_preparation(
  p_lesson_id uuid, p_servant_profile_id uuid, p_action text, p_note text DEFAULT NULL
)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_stage_id uuid;
  v_service_id uuid;
  v_preparer_service_id uuid;
  v_reviewer_id uuid;
  v_current_status text;
  v_trimmed_note text;
BEGIN
  IF p_action IS NULL OR p_action NOT IN ('approved', 'needs_revision') THEN RAISE EXCEPTION 'invalid_action'; END IF;
  v_trimmed_note := btrim(coalesce(p_note, ''));
  IF p_action = 'needs_revision' AND v_trimmed_note = '' THEN RAISE EXCEPTION 'feedback_required'; END IF;
  SELECT wl.stage_id INTO v_stage_id FROM public.weekly_lessons wl WHERE wl.id = p_lesson_id;
  IF v_stage_id IS NULL THEN RAISE EXCEPTION 'weekly_lesson_not_found'; END IF;
  SELECT st.service_id INTO v_service_id FROM public.stages st WHERE st.id = v_stage_id;
  IF v_service_id IS NULL THEN RAISE EXCEPTION 'weekly_lesson_service_not_found'; END IF;
  SELECT sp.service_id INTO v_preparer_service_id FROM public.servant_profiles sp WHERE sp.id = p_servant_profile_id;
  IF v_preparer_service_id IS NULL OR v_preparer_service_id <> v_service_id THEN RAISE EXCEPTION 'preparation_service_mismatch'; END IF;
  SELECT sp.id INTO v_reviewer_id FROM public.servant_profiles sp
    WHERE sp.auth_user_id = (SELECT auth.uid()) AND sp.service_id = v_service_id AND sp.account_status = 'active' LIMIT 1;
  IF v_reviewer_id IS NULL THEN RAISE EXCEPTION 'reviewer_not_found'; END IF;
  IF v_reviewer_id = p_servant_profile_id THEN RAISE EXCEPTION 'self_review_forbidden'; END IF;
  IF NOT coalesce((SELECT public.is_active_system_admin()), false)
     AND NOT (SELECT private.can_manage_weekly_stage(v_stage_id)) THEN RAISE EXCEPTION 'unauthorized_scope'; END IF;
  SELECT p.status INTO v_current_status FROM public.weekly_lesson_preparations p
    WHERE p.weekly_lesson_id = p_lesson_id AND p.servant_profile_id = p_servant_profile_id FOR UPDATE;
  IF v_current_status IS NULL THEN RAISE EXCEPTION 'preparation_not_found'; END IF;
  IF v_current_status <> 'submitted' THEN RAISE EXCEPTION 'invalid_state_transition: current status is %', v_current_status; END IF;
  INSERT INTO public.weekly_lesson_preparation_reviews
    (id, weekly_lesson_id, servant_profile_id, reviewer_id, action, note, reviewed_at)
  VALUES (gen_random_uuid(), p_lesson_id, p_servant_profile_id, v_reviewer_id, p_action, nullif(v_trimmed_note, ''), now());
  UPDATE public.weekly_lesson_preparations
  SET status = p_action, prepared = (p_action = 'approved'), reviewed_at = now(),
      reviewed_by = v_reviewer_id, review_note = nullif(v_trimmed_note, ''), updated_at = now()
  WHERE weekly_lesson_id = p_lesson_id AND servant_profile_id = p_servant_profile_id;
END;
$function$;
REVOKE ALL ON FUNCTION public.review_weekly_preparation(uuid, uuid, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.review_weekly_preparation(uuid, uuid, text, text) TO authenticated, service_role;
