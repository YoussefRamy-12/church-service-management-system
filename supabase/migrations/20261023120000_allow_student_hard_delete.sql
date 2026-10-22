-- Allow authorized service staff to permanently remove a student and cascade
-- all student-owned records (attendance, follow-up, and sensitive data).
-- Existing foreign keys to students are updated without changing other FK
-- behavior in the schema.
do $$
declare
  student_fk record;
  constraint_definition text;
begin
  for student_fk in
    select c.oid, c.conrelid, c.conname
    from pg_constraint c
    where c.contype = 'f'
      and c.confrelid = 'public.students'::regclass
  loop
    constraint_definition := pg_get_constraintdef(student_fk.oid);
    if position('ON DELETE CASCADE' in upper(constraint_definition)) > 0 then
      continue;
    end if;

    if position('ON DELETE' in upper(constraint_definition)) > 0 then
      constraint_definition := regexp_replace(
        constraint_definition,
        ' ON DELETE (NO ACTION|RESTRICT|SET NULL|SET DEFAULT)',
        ' ON DELETE CASCADE',
        'i'
      );
    else
      constraint_definition := constraint_definition || ' ON DELETE CASCADE';
    end if;

    execute format(
      'alter table %s drop constraint %I',
      student_fk.conrelid::regclass,
      student_fk.conname
    );
    execute format(
      'alter table %s add constraint %I %s',
      student_fk.conrelid::regclass,
      student_fk.conname,
      constraint_definition
    );
  end loop;
end;
$$;

-- Keep hard deletion within the same service/class scope used for editing.
drop policy if exists students_delete on public.students;
create policy students_delete on public.students
  for delete to authenticated
  using (
    (select private.can_access_service(students.service_id))
    and (
      (select private.is_overall_admin_for_service(students.service_id))
      or (select private.can_access_class(students.current_class_id))
      or (
        approval_status = 'pending'::public.student_approval_status
        and (select private.can_access_class(students.proposed_class_id))
      )
    )
  );
