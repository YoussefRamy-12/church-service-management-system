-- Keep the shared student directory compatible with approval workflows.
-- Individual features apply their own membership lifecycle filters.
CREATE OR REPLACE FUNCTION public.get_service_student_directory(p_service_id uuid)
RETURNS TABLE (
  membership_id uuid,
  student_id uuid,
  service_id uuid,
  identity_service_id uuid,
  class_id uuid,
  proposed_class_id uuid,
  enrollment_date timestamptz,
  membership_status text,
  school text,
  grade text,
  is_deacon boolean,
  membership_notes text,
  student_name text,
  birth_date date,
  phone text,
  photo_path text
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT (SELECT private.can_access_service(p_service_id)) THEN
    RAISE EXCEPTION 'service_access_denied' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT ss.id, ss.student_id, ss.service_id, s.service_id, ss.class_id, ss.proposed_class_id,
         ss.enrollment_date, ss.status, ss.school, ss.grade, ss.is_deacon,
         ss.notes, s.name, s.birth_date, s.phone, s.photo_path
  FROM public.service_students ss
  JOIN public.students s ON s.id = ss.student_id
  WHERE ss.service_id = p_service_id
    AND ss.status IN ('active', 'pending')
    AND (
      (SELECT private.is_overall_admin_for_service(p_service_id))
      OR (SELECT private.can_access_class(coalesce(ss.class_id, ss.proposed_class_id)))
    );
END;
$function$;
REVOKE ALL ON FUNCTION public.get_service_student_directory(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_service_student_directory(uuid) TO authenticated, service_role;
