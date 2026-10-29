create table if not exists public.weekly_lesson_preparations (
  weekly_lesson_id uuid not null references public.weekly_lessons(id) on delete cascade,
  servant_profile_id uuid not null references public.servant_profiles(id) on delete cascade,
  prepared boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (weekly_lesson_id, servant_profile_id)
);

alter table public.weekly_lesson_preparations enable row level security;
grant select, insert, update on public.weekly_lesson_preparations to authenticated;

drop policy if exists weekly_lessons_read_assigned_stage on public.weekly_lessons;
create policy weekly_lessons_read_assigned_stage on public.weekly_lessons
  for select to authenticated
  using (
    (select private.can_manage_weekly_stage(weekly_lessons.stage_id))
    or (select private.can_read_weekly_stage(weekly_lessons.stage_id))
  );

drop policy if exists weekly_lessons_storage_read on storage.objects;
create policy weekly_lessons_storage_read on storage.objects
  for select to authenticated
  using (
    bucket_id = 'weekly-lessons'
    and exists (
      select 1
      from public.weekly_lessons wl
      where wl.storage_path = storage.objects.name
        and (select private.can_read_weekly_stage(wl.stage_id))
    )
  );

create policy weekly_lesson_preparations_read_self on public.weekly_lesson_preparations
  for select to authenticated
  using (
    exists (
      select 1 from public.servant_profiles sp
      where sp.id = weekly_lesson_preparations.servant_profile_id
        and sp.auth_user_id = (select auth.uid())
        and sp.account_status = 'active'
    )
  );

create policy weekly_lesson_preparations_insert_self on public.weekly_lesson_preparations
  for insert to authenticated
  with check (
    exists (
      select 1 from public.servant_profiles sp
      where sp.id = weekly_lesson_preparations.servant_profile_id
        and sp.auth_user_id = (select auth.uid())
        and sp.account_status = 'active'
    )
    and exists (
      select 1 from public.weekly_lessons wl
      where wl.id = weekly_lesson_preparations.weekly_lesson_id
        and wl.week_start = date_trunc('week', now() at time zone 'Africa/Cairo')::date
        and (select private.can_read_weekly_stage(wl.stage_id))
    )
  );

create policy weekly_lesson_preparations_update_self on public.weekly_lesson_preparations
  for update to authenticated
  using (
    exists (
      select 1 from public.servant_profiles sp
      where sp.id = weekly_lesson_preparations.servant_profile_id
        and sp.auth_user_id = (select auth.uid())
        and sp.account_status = 'active'
    )
  )
  with check (
    exists (
      select 1 from public.servant_profiles sp
      where sp.id = weekly_lesson_preparations.servant_profile_id
        and sp.auth_user_id = (select auth.uid())
        and sp.account_status = 'active'
    )
    and exists (
      select 1 from public.weekly_lessons wl
      where wl.id = weekly_lesson_preparations.weekly_lesson_id
        and wl.week_start = date_trunc('week', now() at time zone 'Africa/Cairo')::date
        and (select private.can_read_weekly_stage(wl.stage_id))
    )
  );
