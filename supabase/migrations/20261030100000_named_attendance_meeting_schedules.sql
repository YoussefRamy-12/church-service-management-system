create table if not exists public.meeting_schedules (
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references public.services(id) on delete cascade,
  name text not null check (length(btrim(name)) between 2 and 80),
  frequency text not null default 'weekly' check (frequency in ('weekly', 'monthly')),
  weekday smallint not null default 5 check (weekday between 1 and 7),
  month_day smallint not null default 1 check (month_day between 1 and 31),
  start_time text not null default '15:00',
  is_active boolean not null default true,
  created_by uuid default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists meeting_schedules_service_name_unique
  on public.meeting_schedules(service_id, lower(name));

alter table public.meetings
  add column if not exists name text not null default 'اجتماع الخدمة',
  add column if not exists schedule_id uuid references public.meeting_schedules(id) on delete set null;

-- The former one-meeting-per-date constraint prevents two differently named
-- service meetings from happening on the same day. Remove only that constraint.
do $$
declare
  constraint_name text;
begin
  for constraint_name in
    select c.conname
    from pg_constraint c
    where c.conrelid = 'public.meetings'::regclass
      and c.contype = 'u'
      and (
        select array_agg(a.attname::text order by a.attname::text)
        from unnest(c.conkey) as key(attnum)
        join pg_attribute a
          on a.attrelid = c.conrelid and a.attnum = key.attnum
      ) = array['meeting_date', 'service_id']::text[]
  loop
    execute format('alter table public.meetings drop constraint %I', constraint_name);
  end loop;
end $$;

-- Preserve the existing single service schedule as a named default schedule.
insert into public.meeting_schedules (
  service_id, name, frequency, weekday, month_day, start_time
)
select
  s.id,
  'اجتماع الخدمة',
  coalesce(s.meeting_frequency, 'weekly'),
  coalesce(s.meeting_weekday, 5),
  coalesce(s.meeting_month_day, 1),
  coalesce(s.meeting_start_time, '15:00')
from public.services s
where not exists (
  select 1 from public.meeting_schedules ms
  where ms.service_id = s.id and lower(ms.name) = lower('اجتماع الخدمة')
);

update public.meetings m
set schedule_id = ms.id,
    name = coalesce(nullif(btrim(m.name), ''), ms.name)
from public.meeting_schedules ms
where m.service_id = ms.service_id
  and lower(ms.name) = lower('اجتماع الخدمة')
  and m.schedule_id is null;

create unique index if not exists meetings_schedule_date_unique
  on public.meetings(schedule_id, meeting_date)
  where schedule_id is not null;

create index if not exists meeting_schedules_service_active_idx
  on public.meeting_schedules(service_id, is_active);

alter table public.meeting_schedules enable row level security;
grant select, insert, update, delete on public.meeting_schedules to authenticated;

drop policy if exists meeting_schedules_read_assigned_service on public.meeting_schedules;
create policy meeting_schedules_read_assigned_service
  on public.meeting_schedules for select to authenticated
  using (
    exists (
      select 1 from public.servant_profiles sp
      where sp.service_id = meeting_schedules.service_id
        and sp.auth_user_id = (select auth.uid())
        and sp.account_status = 'active'
    )
    or (select public.is_active_system_admin())
  );

drop policy if exists meeting_schedules_manage_overall_leaders on public.meeting_schedules;
create policy meeting_schedules_manage_overall_leaders
  on public.meeting_schedules for all to authenticated
  using (
    (select public.is_active_system_admin())
    or (select public.is_active_service_schedule_leader(meeting_schedules.service_id::text))
  )
  with check (
    (select public.is_active_system_admin())
    or (select public.is_active_service_schedule_leader(meeting_schedules.service_id::text))
  );

-- Existing meeting access policies remain in place. New named meetings are
-- still ordinary rows in public.meetings, so attendance keeps its existing RLS.
