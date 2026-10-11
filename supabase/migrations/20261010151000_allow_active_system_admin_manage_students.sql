-- Allow active system administrators to create and approve students from
-- the admin UI. This is intentionally scoped to the system admin registry.
drop policy if exists "active system administrators can manage students"
  on public.students;

create policy "active system administrators can manage students"
  on public.students
  for all
  to authenticated
  using ((select public.is_active_system_admin()))
  with check ((select public.is_active_system_admin()));
