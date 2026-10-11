-- Let active system administrators create service records from the admin UI.
-- The SECURITY DEFINER helper reads the admin registry without depending on
-- client-facing SELECT policies on system_administrators.
create or replace function public.is_active_system_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.system_administrators as administrators
    where administrators.auth_user_id = (select auth.uid())
      and administrators.status = 'active'
  );
$$;

revoke all on function public.is_active_system_admin() from public;
grant execute on function public.is_active_system_admin() to authenticated;

drop policy if exists "active system administrators can create services"
  on public.services;

create policy "active system administrators can create services"
  on public.services
  for insert
  to authenticated
  with check ((select public.is_active_system_admin()));
