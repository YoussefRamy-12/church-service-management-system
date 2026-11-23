-- Attendance class snapshots must validate against the service membership,
-- not the global identity's legacy owner-service columns.
CREATE OR REPLACE FUNCTION private.validate_attendance_class_snapshot()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_membership_service uuid;
  v_membership_class uuid;
  v_membership_proposed_class uuid;
  v_meeting_service uuid;
BEGIN
  SELECT ss.service_id, ss.class_id, ss.proposed_class_id
    INTO v_membership_service, v_membership_class, v_membership_proposed_class
  FROM public.service_students ss
  WHERE ss.id = NEW.service_student_id
    AND ss.student_id = NEW.student_id
    AND ss.service_id = NEW.service_id;

  SELECT m.service_id
    INTO v_meeting_service
  FROM public.meetings m
  WHERE m.id = NEW.meeting_id;

  IF v_membership_service IS NULL OR v_meeting_service IS NULL THEN
    RAISE EXCEPTION 'Invalid attendance membership or meeting reference'
      USING ERRCODE = '23503';
  END IF;

  IF v_membership_service <> v_meeting_service THEN
    RAISE EXCEPTION 'Attendance membership and meeting must belong to the same service'
      USING ERRCODE = '23514';
  END IF;

  IF NEW.class_id_at_attendance IS NULL THEN
    RAISE EXCEPTION 'class_id_at_attendance is required'
      USING ERRCODE = '23502';
  END IF;

  IF NOT (
    NEW.class_id_at_attendance = v_membership_class
    OR (
      v_membership_class IS NULL
      AND NEW.class_id_at_attendance = v_membership_proposed_class
    )
  ) THEN
    RAISE EXCEPTION 'Attendance class snapshot must match the service membership current class or proposed class'
      USING ERRCODE = '23514';
  END IF;

  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.prevent_attendance_identity_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NEW.meeting_id IS DISTINCT FROM OLD.meeting_id
     OR NEW.student_id IS DISTINCT FROM OLD.student_id
     OR NEW.service_student_id IS DISTINCT FROM OLD.service_student_id
     OR NEW.service_id IS DISTINCT FROM OLD.service_id
     OR NEW.class_id_at_attendance IS DISTINCT FROM OLD.class_id_at_attendance
     OR NEW.recorded_by IS DISTINCT FROM OLD.recorded_by
     OR NEW.client_operation_id IS DISTINCT FROM OLD.client_operation_id THEN
    RAISE EXCEPTION 'Attendance identity and membership snapshot fields are immutable'
      USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$function$;
