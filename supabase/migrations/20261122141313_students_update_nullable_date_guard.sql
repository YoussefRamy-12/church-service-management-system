-- Keep required global identity dates when optional edit fields are omitted.
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
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_student_id uuid;
BEGIN
  SELECT ss.student_id INTO v_student_id
  FROM public.service_students ss
  WHERE ss.id = p_membership_id
  FOR UPDATE;
  IF v_student_id IS NULL THEN
    RAISE EXCEPTION 'membership_not_found_or_not_authorized' USING ERRCODE = '42501';
  END IF;

  -- Shared identity edits are allowed only through the legacy owning service
  -- during the compatibility window. Other memberships edit their own fields.
  UPDATE public.students s
  SET name = btrim(p_name),
      birth_date = coalesce(p_birth_date, s.birth_date),
      phone = nullif(btrim(coalesce(p_phone, '')), ''),
      photo_path = nullif(btrim(coalesce(p_photo_path, '')), ''),
      updated_at = now()
  WHERE s.id = v_student_id
    AND s.service_id = (SELECT ss.service_id FROM public.service_students ss WHERE ss.id = p_membership_id);

  UPDATE public.service_students ss
  SET school = nullif(btrim(p_school), ''),
      grade = nullif(btrim(p_grade), ''),
      is_deacon = coalesce(p_is_deacon, false),
      enrollment_date = coalesce(p_enrollment_date, ss.enrollment_date),
      notes = nullif(btrim(coalesce(p_notes, '')), ''),
      updated_at = now()
  WHERE ss.id = p_membership_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'membership_update_not_authorized' USING ERRCODE = '42501';
  END IF;
END;
$function$;

REVOKE ALL ON FUNCTION public.update_service_student(uuid,text,date,text,text,text,text,boolean,timestamptz,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.update_service_student(uuid,text,date,text,text,text,text,boolean,timestamptz,text) TO authenticated, service_role;
