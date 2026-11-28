-- Permit class-scoped servants to create and update memberships only inside
-- their assigned class/service. Overall leaders retain service-wide access.
DROP POLICY IF EXISTS service_students_insert ON public.service_students;
CREATE POLICY service_students_insert ON public.service_students
FOR INSERT TO authenticated
WITH CHECK (
  (SELECT private.is_super_admin())
  OR (
    (SELECT private.can_access_service(service_id))
    AND (
      (SELECT private.is_overall_admin_for_service(service_id))
      OR (SELECT private.can_access_class(coalesce(class_id, proposed_class_id)))
    )
  )
);

DROP POLICY IF EXISTS service_students_update ON public.service_students;
CREATE POLICY service_students_update ON public.service_students
FOR UPDATE TO authenticated
USING (
  (SELECT private.is_super_admin())
  OR (
    (SELECT private.can_access_service(service_id))
    AND (
      (SELECT private.is_overall_admin_for_service(service_id))
      OR (SELECT private.can_access_class(coalesce(class_id, proposed_class_id)))
    )
  )
)
WITH CHECK (
  (SELECT private.is_super_admin())
  OR (
    (SELECT private.can_access_service(service_id))
    AND (
      (SELECT private.is_overall_admin_for_service(service_id))
      OR (SELECT private.can_access_class(coalesce(class_id, proposed_class_id)))
    )
  )
);
