-- Run approve_service_student as SECURITY DEFINER while keeping the explicit
-- super_admin / overall_admin_for_service authorization check at entry.
CREATE OR REPLACE FUNCTION public.approve_service_student(p_membership_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_student_id uuid;
  v_service_id uuid;
  v_class_id uuid;
BEGIN
  SELECT ss.student_id, ss.service_id, ss.proposed_class_id
  INTO v_student_id, v_service_id, v_class_id
  FROM public.service_students ss
  WHERE ss.id = p_membership_id AND ss.status = 'pending'
  FOR UPDATE;

  IF v_student_id IS NULL OR v_class_id IS NULL THEN
    RAISE EXCEPTION 'pending_membership_not_found';
  END IF;

  IF NOT (SELECT private.is_super_admin())
     AND NOT (SELECT private.is_overall_admin_for_service(v_service_id)) THEN
    RAISE EXCEPTION 'approval_not_authorized' USING ERRCODE = '42501';
  END IF;

  UPDATE public.service_students
  SET status = 'active', class_id = v_class_id, proposed_class_id = NULL, updated_at = now()
  WHERE id = p_membership_id;

  UPDATE public.students s
  SET approval_status = 'approved'::public.student_approval_status,
      current_class_id = v_class_id, proposed_class_id = NULL, updated_at = now()
  WHERE s.id = v_student_id AND s.service_id = v_service_id;
END;
$function$;

