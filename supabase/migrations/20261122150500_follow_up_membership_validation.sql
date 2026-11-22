-- Resolve follow-up ownership from the creator's service profile, not from
-- the global student's legacy owner-service columns.
CREATE OR REPLACE FUNCTION private.populate_service_membership_reference()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF TG_TABLE_NAME = 'attendance_records' THEN
    IF NEW.service_id IS NULL THEN
      SELECT m.service_id INTO NEW.service_id
      FROM public.meetings m
      WHERE m.id = NEW.meeting_id;
    END IF;
  ELSIF TG_TABLE_NAME = 'follow_up_records' THEN
    IF NEW.service_id IS NULL THEN
      SELECT sp.service_id INTO NEW.service_id
      FROM public.servant_profiles sp
      WHERE sp.id = NEW.created_by;
    END IF;
  END IF;

  IF NEW.service_student_id IS NULL THEN
    SELECT ss.id INTO NEW.service_student_id
    FROM public.service_students ss
    WHERE ss.student_id = NEW.student_id
      AND ss.service_id = NEW.service_id;
  END IF;

  IF NEW.service_id IS NULL OR NEW.service_student_id IS NULL THEN
    RAISE EXCEPTION 'valid_service_membership_required'
      USING ERRCODE = '23503';
  END IF;

  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION private.validate_follow_up_case_membership()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_student_id uuid;
  v_service_id uuid;
  v_class_id uuid;
  v_proposed_class_id uuid;
BEGIN
  IF TG_OP = 'UPDATE' AND (
    NEW.student_id IS DISTINCT FROM OLD.student_id
    OR NEW.service_id IS DISTINCT FROM OLD.service_id
    OR NEW.service_student_id IS DISTINCT FROM OLD.service_student_id
    OR NEW.class_id IS DISTINCT FROM OLD.class_id
  ) THEN
    RAISE EXCEPTION 'Follow-up case identity and membership fields are immutable'
      USING ERRCODE = '23514';
  END IF;

  SELECT ss.student_id, ss.service_id, ss.class_id, ss.proposed_class_id
    INTO v_student_id, v_service_id, v_class_id, v_proposed_class_id
  FROM public.service_students ss
  WHERE ss.id = NEW.service_student_id;

  IF v_student_id IS NULL THEN
    RAISE EXCEPTION 'follow_up_case_membership_not_found'
      USING ERRCODE = '23503';
  END IF;

  IF v_student_id <> NEW.student_id OR v_service_id <> NEW.service_id THEN
    RAISE EXCEPTION 'Follow-up case student and service must match the membership'
      USING ERRCODE = '23514';
  END IF;

  IF NEW.class_id IS DISTINCT FROM v_class_id
     AND NOT (v_class_id IS NULL AND NEW.class_id = v_proposed_class_id) THEN
    RAISE EXCEPTION 'Follow-up case class must match the service membership class'
      USING ERRCODE = '23514';
  END IF;

  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_follow_up_case_membership_integrity
  ON public.follow_up_cases;
CREATE TRIGGER trg_follow_up_case_membership_integrity
BEFORE INSERT OR UPDATE OF student_id, service_id, service_student_id, class_id
ON public.follow_up_cases
FOR EACH ROW
EXECUTE FUNCTION private.validate_follow_up_case_membership();
