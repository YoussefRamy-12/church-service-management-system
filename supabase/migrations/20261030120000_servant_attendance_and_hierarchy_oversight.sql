-- Servant attendance is separate from student attendance.
-- Writes are restricted at the database layer to active overall leaders.

create table if not exists public.servant_attendance_records (
  id uuid primary key default gen_random_uuid(),
  meeting_id uuid not null references public.meetings(id) on delete cascade,
  servant_profile_id uuid not null references public.servant_profiles(id) on delete cascade,
  checked_in_at timestamptz not null default now(),
  recorded_by uuid not null references public.servant_profiles(id),
  created_at timestamptz not null default now(),
  constraint servant_attendance_meeting_servant_unique
    unique (meeting_id, servant_profile_id)
);

create index if not exists servant_attendance_servant_date_idx
  on public.servant_attendance_records(servant_profile_id, checked_in_at desc);

alter table public.servant_attendance_records enable row level security;
grant select, insert, update, delete on public.servant_attendance_records to authenticated;

drop policy if exists servant_attendance_read_self_or_overall_leader
  on public.servant_attendance_records;
create policy servant_attendance_read_self_or_overall_leader
  on public.servant_attendance_records
  for select to authenticated
  using (
    exists (
      select 1
      from public.servant_profiles target
      where target.id = servant_attendance_records.servant_profile_id
        and target.auth_user_id = (select auth.uid())
        and target.account_status = 'active'
    )
    or exists (
      select 1
      from public.servant_profiles actor
      join public.meetings m on m.service_id = actor.service_id
      join public.servant_profiles target
        on target.id = servant_attendance_records.servant_profile_id
       and target.service_id = actor.service_id
      where actor.auth_user_id = (select auth.uid())
        and actor.account_status = 'active'
        and m.id = servant_attendance_records.meeting_id
        and (
          actor.role in (
            'overall_leader'::public.servant_role,
            'overall_helper'::public.servant_role
          )
          or (
            actor.role = 'stage_leader'::public.servant_role
            and actor.stage_id = target.stage_id
          )
          or (
            actor.role = 'class_leader'::public.servant_role
            and actor.class_id is not null
            and actor.class_id = target.class_id
          )
        )
    )
  );

drop policy if exists servant_attendance_insert_overall_leader
  on public.servant_attendance_records;
create policy servant_attendance_insert_overall_leader
  on public.servant_attendance_records
  for insert to authenticated
  with check (
    exists (
      select 1
      from public.servant_profiles actor
      join public.meetings m on m.service_id = actor.service_id
      join public.servant_profiles target
        on target.id = servant_attendance_records.servant_profile_id
       and target.service_id = actor.service_id
      where actor.id = servant_attendance_records.recorded_by
        and actor.auth_user_id = (select auth.uid())
        and actor.account_status = 'active'
        and actor.role = 'overall_leader'::public.servant_role
        and m.id = servant_attendance_records.meeting_id
    )
  );

drop policy if exists servant_attendance_update_overall_leader
  on public.servant_attendance_records;
create policy servant_attendance_update_overall_leader
  on public.servant_attendance_records
  for update to authenticated
  using (
    exists (
      select 1
      from public.servant_profiles actor
      join public.meetings m on m.service_id = actor.service_id
      join public.servant_profiles target
        on target.id = servant_attendance_records.servant_profile_id
       and target.service_id = actor.service_id
      where actor.auth_user_id = (select auth.uid())
        and actor.account_status = 'active'
        and actor.role = 'overall_leader'::public.servant_role
        and m.id = servant_attendance_records.meeting_id
    )
  )
  with check (
    exists (
      select 1
      from public.servant_profiles actor
      join public.meetings m on m.service_id = actor.service_id
      join public.servant_profiles target
        on target.id = servant_attendance_records.servant_profile_id
       and target.service_id = actor.service_id
      where actor.id = servant_attendance_records.recorded_by
        and actor.auth_user_id = (select auth.uid())
        and actor.account_status = 'active'
        and actor.role = 'overall_leader'::public.servant_role
        and m.id = servant_attendance_records.meeting_id
    )
  );

drop policy if exists servant_attendance_delete_overall_leader
  on public.servant_attendance_records;
create policy servant_attendance_delete_overall_leader
  on public.servant_attendance_records
  for delete to authenticated
  using (
    exists (
      select 1
      from public.servant_profiles actor
      join public.meetings m on m.service_id = actor.service_id
      join public.servant_profiles target
        on target.id = servant_attendance_records.servant_profile_id
       and target.service_id = actor.service_id
      where actor.auth_user_id = (select auth.uid())
        and actor.account_status = 'active'
        and actor.role = 'overall_leader'::public.servant_role
        and m.id = servant_attendance_records.meeting_id
    )
  );

-- Managers can see preparation status for servants within their hierarchy:
-- overall leader: entire service; stage leader: own stage; class leader: own class.
drop policy if exists weekly_lesson_preparations_read_hierarchy
  on public.weekly_lesson_preparations;
create policy weekly_lesson_preparations_read_hierarchy
  on public.weekly_lesson_preparations
  for select to authenticated
  using (
    exists (
      select 1
      from public.weekly_lessons wl
      join public.stages st on st.id = wl.stage_id
      join public.servant_profiles target
        on target.id = weekly_lesson_preparations.servant_profile_id
       and target.service_id = wl.service_id
      join public.servant_profiles actor
        on actor.service_id = target.service_id
       and actor.auth_user_id = (select auth.uid())
       and actor.account_status = 'active'
      where wl.id = weekly_lesson_preparations.weekly_lesson_id
        and (
          actor.role in (
            'overall_leader'::public.servant_role,
            'overall_helper'::public.servant_role
          )
          or (
            actor.role = 'stage_leader'::public.servant_role
            and actor.stage_id = st.id
            and target.stage_id = st.id
          )
          or (
            actor.role = 'class_leader'::public.servant_role
            and actor.class_id is not null
            and actor.class_id = target.class_id
          )
        )
    )
  );

-- The overall helper shares oversight visibility with the overall leader.
drop policy if exists weekly_lessons_read_overall_helper on public.weekly_lessons;
create policy weekly_lessons_read_overall_helper
  on public.weekly_lessons for select to authenticated
  using (
    exists (
      select 1
      from public.servant_profiles actor
      join public.stages st on st.service_id = actor.service_id
      where actor.auth_user_id = (select auth.uid())
        and actor.account_status = 'active'
        and actor.role = 'overall_helper'::public.servant_role
        and st.id = weekly_lessons.stage_id
    )
  );
