-- Until the identity verification UI exists, only platform super-admins may
-- link an existing global student identity into a different service.
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
  FROM public.students s
  WHERE s.id = NEW.student_id;

  IF v_identity_service_id IS NULL THEN
    RAISE EXCEPTION 'global_student_identity_not_found'
      USING ERRCODE = '23503';
  END IF;

  IF v_identity_service_id <> NEW.service_id
     AND NOT (SELECT private.is_super_admin()) THEN
    RAISE EXCEPTION 'cross_service_identity_link_requires_verified_workflow'
      USING ERRCODE = '42501';
  END IF;

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.enforce_verified_student_membership_link() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trg_verified_student_membership_link ON public.service_students;
CREATE TRIGGER trg_verified_student_membership_link
BEFORE INSERT OR UPDATE OF student_id, service_id
ON public.service_students
FOR EACH ROW
EXECUTE FUNCTION private.enforce_verified_student_membership_link();
