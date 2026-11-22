-- Students feature: service-membership-first lifecycle RPCs.
-- SECURITY INVOKER is intentional: table grants and RLS remain authoritative.

CREATE OR REPLACE FUNCTION public.register_service_student(
  p_student_id uuid,
  p_membership_id uuid,
  p_service_id uuid,
  p_name text,
  p_birth_date date,
  p_phone text,
  p_photo_path text,
  p_school text,
  p_grade text,
  p_is_deacon boolean,
  p_enrollment_date timestamptz,
  p_status text,
  p_class_id uuid DEFAULT NULL,
  p_proposed_class_id uuid DEFAULT NULL,
  p_notes text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'authentication_required' USING ERRCODE = '42501';
  END IF;
  IF p_status NOT IN ('pending', 'active') THEN
    RAISE EXCEPTION 'invalid_initial_membership_status';
  END IF;
  IF nullif(btrim(p_name), '') IS NULL OR p_birth_date IS NULL
     OR nullif(btrim(p_grade), '') IS NULL OR p_enrollment_date IS NULL THEN
    RAISE EXCEPTION 'required_student_fields_missing';
  END IF;
  IF p_status = 'pending' AND (p_proposed_class_id IS NULL OR p_class_id IS NOT NULL) THEN
    RAISE EXCEPTION 'pending_membership_requires_proposed_class';
  END IF;
  IF p_status = 'active' AND (p_class_id IS NULL OR p_proposed_class_id IS NOT NULL) THEN
    RAISE EXCEPTION 'active_membership_requires_current_class';
  END IF;

  -- A completed retry is safe only when both stable client-generated IDs match.
  IF EXISTS (
    SELECT 1 FROM public.service_students ss
    WHERE ss.id = p_membership_id
      AND ss.student_id = p_student_id
      AND ss.service_id = p_service_id
  ) THEN
    RETURN p_membership_id;
  END IF;

  INSERT INTO public.students (
    id, service_id, current_class_id, proposed_class_id, name, birth_date,
    phone, school, grade, enrollment_at, approval_status, photo_path, notes, is_deacon
  ) VALUES (
    p_student_id, p_service_id, p_class_id, p_proposed_class_id, btrim(p_name),
    p_birth_date, nullif(btrim(coalesce(p_phone, '')), ''),
    coalesce(nullif(btrim(p_school), ''), ''),
    btrim(p_grade), p_enrollment_date,
    CASE WHEN p_status = 'active' THEN 'approved'::public.student_approval_status
         ELSE 'pending'::public.student_approval_status END,
    nullif(btrim(coalesce(p_photo_path, '')), ''),
    nullif(btrim(coalesce(p_notes, '')), ''),
    coalesce(p_is_deacon, false)
  );

  INSERT INTO public.service_students (
    id, student_id, service_id, class_id, proposed_class_id, enrollment_date,
    status, school, grade, is_deacon, notes
  ) VALUES (
    p_membership_id, p_student_id, p_service_id, p_class_id, p_proposed_class_id,
    p_enrollment_date, p_status, nullif(btrim(p_school), ''),
    btrim(p_grade), coalesce(p_is_deacon, false),
    nullif(btrim(coalesce(p_notes, '')), '')
  );

  RETURN p_membership_id;
END;
$function$;

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

  UPDATE public.students
  SET name = btrim(p_name),
      birth_date = p_birth_date,
      phone = nullif(btrim(coalesce(p_phone, '')), ''),
      photo_path = nullif(btrim(coalesce(p_photo_path, '')), ''),
      school = coalesce(nullif(btrim(p_school), ''), ''),
      grade = coalesce(nullif(btrim(p_grade), ''), ''),
      is_deacon = coalesce(p_is_deacon, false),
      enrollment_at = p_enrollment_date,
      notes = nullif(btrim(coalesce(p_notes, '')), ''),
      updated_at = now()
  WHERE id = v_student_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'global_identity_update_not_authorized' USING ERRCODE = '42501';
  END IF;

  UPDATE public.service_students
  SET school = nullif(btrim(p_school), ''),
      grade = nullif(btrim(p_grade), ''),
      is_deacon = coalesce(p_is_deacon, false),
      enrollment_date = p_enrollment_date,
      notes = nullif(btrim(coalesce(p_notes, '')), ''),
      updated_at = now()
  WHERE id = p_membership_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'membership_update_not_authorized' USING ERRCODE = '42501';
  END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION public.approve_service_student(p_membership_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
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

  UPDATE public.students
  SET approval_status = 'approved'::public.student_approval_status,
      current_class_id = v_class_id, proposed_class_id = NULL, updated_at = now()
  WHERE id = v_student_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.assign_service_student_class(
  p_membership_id uuid,
  p_class_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_student_id uuid;
  v_status text;
BEGIN
  SELECT ss.student_id, ss.status INTO v_student_id, v_status
  FROM public.service_students ss
  WHERE ss.id = p_membership_id
    AND ss.status IN ('pending', 'active')
  FOR UPDATE;

  IF v_student_id IS NULL THEN
    RAISE EXCEPTION 'active_membership_not_found';
  END IF;

  IF v_status = 'pending' THEN
    UPDATE public.service_students
    SET proposed_class_id = p_class_id, class_id = NULL, updated_at = now()
    WHERE id = p_membership_id;
    UPDATE public.students
    SET proposed_class_id = p_class_id, current_class_id = NULL, updated_at = now()
    WHERE id = v_student_id;
  ELSE
    UPDATE public.service_students
    SET class_id = p_class_id, proposed_class_id = NULL, updated_at = now()
    WHERE id = p_membership_id;
    UPDATE public.students
    SET current_class_id = p_class_id, proposed_class_id = NULL, updated_at = now()
    WHERE id = v_student_id;
  END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION public.archive_service_student(p_membership_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  UPDATE public.service_students
  SET status = 'inactive', updated_at = now()
  WHERE id = p_membership_id
    AND status NOT IN ('inactive', 'graduated', 'rejected');
  IF NOT FOUND THEN
    RAISE EXCEPTION 'membership_not_found_or_already_archived';
  END IF;
END;
$function$;

REVOKE ALL ON FUNCTION public.register_service_student(uuid,uuid,uuid,text,date,text,text,text,text,boolean,timestamptz,text,uuid,uuid,text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.update_service_student(uuid,text,date,text,text,text,text,boolean,timestamptz,text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.approve_service_student(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.assign_service_student_class(uuid,uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.archive_service_student(uuid) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.register_service_student(uuid,uuid,uuid,text,date,text,text,text,text,boolean,timestamptz,text,uuid,uuid,text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.update_service_student(uuid,text,date,text,text,text,text,boolean,timestamptz,text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.approve_service_student(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.assign_service_student_class(uuid,uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.archive_service_student(uuid) TO authenticated, service_role;
