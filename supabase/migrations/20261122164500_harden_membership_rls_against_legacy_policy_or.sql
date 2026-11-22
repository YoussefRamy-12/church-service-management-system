-- Legacy permissive policies remain in place during the multi-service
-- expand/contract period. PostgreSQL combines permissive policies with OR,
-- so membership-aware policies alone cannot prevent a legacy policy from
-- authorizing a row through the global student owner-service.
--
-- These additive RESTRICTIVE policies make membership/service consistency a
-- mandatory condition while retaining existing permissive role grants.
-- Inactive/graduated memberships remain readable for historical reporting.

CREATE POLICY attendance_membership_scope_guard_select
ON public.attendance_records
AS RESTRICTIVE
FOR SELECT
TO authenticated
USING (
  public.is_active_system_admin()
  OR (SELECT private.is_super_admin())
  OR EXISTS (
    SELECT 1
    FROM public.service_students ss
    JOIN public.meetings m ON m.id = attendance_records.meeting_id
    WHERE ss.id = attendance_records.service_student_id
      AND ss.student_id = attendance_records.student_id
      AND ss.service_id = attendance_records.service_id
      AND m.service_id = attendance_records.service_id
      AND (SELECT private.can_access_service(attendance_records.service_id))
      AND (
        (SELECT private.is_overall_admin_for_service(attendance_records.service_id))
        OR (SELECT private.can_access_class(attendance_records.class_id_at_attendance))
      )
  )
);

CREATE POLICY attendance_membership_scope_guard_insert
ON public.attendance_records
AS RESTRICTIVE
FOR INSERT
TO authenticated
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
      AND (SELECT private.can_access_class(attendance_records.class_id_at_attendance))
  )
);

CREATE POLICY attendance_membership_scope_guard_update
ON public.attendance_records
AS RESTRICTIVE
FOR UPDATE
TO authenticated
USING (
  public.is_active_system_admin()
  OR (SELECT private.is_super_admin())
  OR EXISTS (
    SELECT 1
    FROM public.service_students ss
    JOIN public.meetings m ON m.id = attendance_records.meeting_id
    WHERE ss.id = attendance_records.service_student_id
      AND ss.student_id = attendance_records.student_id
      AND ss.service_id = attendance_records.service_id
      AND m.service_id = attendance_records.service_id
      AND (SELECT private.can_access_service(attendance_records.service_id))
      AND (
        (SELECT private.is_overall_admin_for_service(attendance_records.service_id))
        OR (SELECT private.can_access_class(attendance_records.class_id_at_attendance))
      )
  )
)
WITH CHECK (
  public.is_active_system_admin()
  OR (SELECT private.is_super_admin())
  OR EXISTS (
    SELECT 1
    FROM public.service_students ss
    JOIN public.meetings m ON m.id = attendance_records.meeting_id
    WHERE ss.id = attendance_records.service_student_id
      AND ss.student_id = attendance_records.student_id
      AND ss.service_id = attendance_records.service_id
      AND m.service_id = attendance_records.service_id
      AND (SELECT private.can_access_service(attendance_records.service_id))
      AND (
        (SELECT private.is_overall_admin_for_service(attendance_records.service_id))
        OR (SELECT private.can_access_class(attendance_records.class_id_at_attendance))
      )
  )
);

CREATE POLICY follow_up_membership_scope_guard_select
ON public.follow_up_records
AS RESTRICTIVE
FOR SELECT
TO authenticated
USING (
  public.is_active_system_admin()
  OR (SELECT private.is_super_admin())
  OR EXISTS (
    SELECT 1
    FROM public.service_students ss
    WHERE ss.id = follow_up_records.service_student_id
      AND ss.student_id = follow_up_records.student_id
      AND ss.service_id = follow_up_records.service_id
      AND (SELECT private.can_access_service(follow_up_records.service_id))
      AND (
        (SELECT private.is_overall_admin_for_service(follow_up_records.service_id))
        OR (SELECT private.can_access_class(COALESCE(ss.class_id, ss.proposed_class_id)))
      )
  )
);

CREATE POLICY follow_up_membership_scope_guard_insert
ON public.follow_up_records
AS RESTRICTIVE
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_active_system_admin()
  OR (SELECT private.is_super_admin())
  OR EXISTS (
    SELECT 1
    FROM public.service_students ss
    JOIN public.servant_profiles sp
      ON sp.id = follow_up_records.created_by
    WHERE ss.id = follow_up_records.service_student_id
      AND ss.student_id = follow_up_records.student_id
      AND ss.service_id = follow_up_records.service_id
      AND sp.auth_user_id = (SELECT auth.uid())
      AND sp.service_id = follow_up_records.service_id
      AND sp.account_status = 'active'
      AND (SELECT private.can_access_service(follow_up_records.service_id))
      AND (
        (SELECT private.is_overall_admin_for_service(follow_up_records.service_id))
        OR (SELECT private.can_access_class(COALESCE(ss.class_id, ss.proposed_class_id)))
      )
  )
);

CREATE POLICY follow_up_membership_scope_guard_update
ON public.follow_up_records
AS RESTRICTIVE
FOR UPDATE
TO authenticated
USING (
  public.is_active_system_admin()
  OR (SELECT private.is_super_admin())
  OR EXISTS (
    SELECT 1
    FROM public.service_students ss
    WHERE ss.id = follow_up_records.service_student_id
      AND ss.student_id = follow_up_records.student_id
      AND ss.service_id = follow_up_records.service_id
      AND (SELECT private.can_access_service(follow_up_records.service_id))
      AND (
        (SELECT private.is_overall_admin_for_service(follow_up_records.service_id))
        OR (SELECT private.can_access_class(COALESCE(ss.class_id, ss.proposed_class_id)))
      )
  )
)
WITH CHECK (
  public.is_active_system_admin()
  OR (SELECT private.is_super_admin())
  OR EXISTS (
    SELECT 1
    FROM public.service_students ss
    WHERE ss.id = follow_up_records.service_student_id
      AND ss.student_id = follow_up_records.student_id
      AND ss.service_id = follow_up_records.service_id
      AND (SELECT private.can_access_service(follow_up_records.service_id))
      AND (
        (SELECT private.is_overall_admin_for_service(follow_up_records.service_id))
        OR (SELECT private.can_access_class(COALESCE(ss.class_id, ss.proposed_class_id)))
      )
  )
);
