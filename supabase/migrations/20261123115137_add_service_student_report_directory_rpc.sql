-- Reports need historical memberships (inactive/graduated) while the
-- interactive student directory intentionally returns only active/pending.
-- Keep the report projection service- and class-scoped and expose only fields
-- required by report aggregation.

CREATE OR REPLACE FUNCTION public.get_service_student_report_directory(
  p_service_id uuid
)
RETURNS TABLE (
  membership_id uuid,
  student_id uuid,
  service_id uuid,
  class_id uuid,
  enrollment_date timestamptz,
  membership_status text,
  student_name text
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
  SELECT
    ss.id,
    ss.student_id,
    ss.service_id,
    ss.class_id,
    ss.enrollment_date,
    ss.status,
    s.name
  FROM public.service_students AS ss
  JOIN public.students AS s ON s.id = ss.student_id
  WHERE ss.service_id = p_service_id
    AND ss.status NOT IN ('pending', 'rejected')
    AND ss.class_id IS NOT NULL
    AND (
      (SELECT private.is_overall_admin_for_service(p_service_id))
      OR (SELECT private.can_access_class(ss.class_id))
    );
END;
$function$;

REVOKE ALL ON FUNCTION public.get_service_student_report_directory(uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_service_student_report_directory(uuid)
  TO authenticated;
