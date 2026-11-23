-- Preserve the existing overall-service administrator capability while
-- keeping the membership/service/meeting consistency guard mandatory.
ALTER POLICY attendance_membership_scope_guard_insert
ON public.attendance_records
WITH CHECK (
  public.is_active_system_admin()
  OR (SELECT private.is_super_admin())
  OR EXISTS (
    SELECT 1
    FROM public.service_students ss
    JOIN public.meetings m ON m.id = attendance_records.meeting_id
    JOIN public.servant_profiles sp
      ON sp.id = attendance_records.recorded_by
    WHERE ss.id = attendance_records.service_student_id
      AND ss.student_id = attendance_records.student_id
      AND ss.service_id = attendance_records.service_id
      AND m.service_id = attendance_records.service_id
      AND sp.auth_user_id = (SELECT auth.uid())
      AND sp.service_id = attendance_records.service_id
      AND sp.account_status = 'active'
      AND (SELECT private.can_access_service(attendance_records.service_id))
      AND (
        (SELECT private.is_overall_admin_for_service(attendance_records.service_id))
        OR (SELECT private.can_access_class(attendance_records.class_id_at_attendance))
      )
  )
);
