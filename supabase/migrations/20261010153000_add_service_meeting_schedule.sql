alter table public.services
  add column if not exists meeting_frequency text not null default 'weekly'
    check (meeting_frequency in ('weekly', 'monthly')),
  add column if not exists meeting_weekday smallint not null default 5
    check (meeting_weekday between 1 and 7),
  add column if not exists meeting_month_day smallint not null default 1
    check (meeting_month_day between 1 and 31);

create or replace function public.is_active_service_schedule_leader(p_service_id text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.servant_profiles as servant
    where servant.auth_user_id = (select auth.uid())
      and servant.service_id::text = p_service_id
      and servant.role in ('overall_leader', 'overall_helper')
      and servant.account_status = 'active'
  );
$$;

revoke all on function public.is_active_service_schedule_leader(text) from public;
grant execute on function public.is_active_service_schedule_leader(text) to authenticated;

drop policy if exists "active overall leaders can update service schedules"
  on public.services;

create policy "active overall leaders can update service schedules"
  on public.services
  for update
  to authenticated
  using ((select public.is_active_service_schedule_leader(id::text)))
  with check ((select public.is_active_service_schedule_leader(id::text)));
