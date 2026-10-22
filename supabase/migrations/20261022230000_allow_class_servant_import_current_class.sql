  -- Migration: Allow class servants and leaders to insert students directly into current_class_id
  -- Timestamp: 2026-10-22 23:00:00
  -- Purpose: Permit authorized class leaders and servants to insert students directly
  --          into current_class_id for classes they can access, while preserving
  --          overall admin privileges and pending proposal workflows.

  drop policy if exists students_insert on public.students;
  create policy students_insert on public.students
    for insert to authenticated
    with check (
      (select private.can_access_service(students.service_id))
      and (
        (select private.is_overall_admin_for_service(students.service_id))
        or (
          students.current_class_id is not null
          and (select private.can_access_class(students.current_class_id))
        )
        or (
          approval_status = 'pending'::public.student_approval_status
          and current_class_id is null
          and (select private.can_access_class(students.proposed_class_id))
        )
      )
    );
