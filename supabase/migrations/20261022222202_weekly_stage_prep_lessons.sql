create table if not exists public.weekly_lessons (
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references public.services(id) on delete cascade,
  stage_id uuid not null references public.stages(id) on delete cascade,
  week_start date not null,
  storage_path text not null unique,
  file_name text not null,
  uploaded_by uuid not null default auth.uid() references auth.users(id),
  updated_at timestamptz not null default now(),
  constraint weekly_lessons_monday check (extract(isodow from week_start) = 1),
  constraint weekly_lessons_stage_week_unique unique(stage_id, week_start)
);

create index if not exists weekly_lessons_service_week_idx
  on public.weekly_lessons(service_id, week_start desc);

alter table public.weekly_lessons enable row level security;
grant select, insert, update, delete on public.weekly_lessons to authenticated;

create or replace function private.can_manage_weekly_stage(p_stage_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select public.is_active_system_admin())
    or exists (
      select 1
      from public.stages st
      join public.servant_profiles sp
        on sp.service_id = st.service_id
       and sp.auth_user_id = (select auth.uid())
       and sp.account_status = 'active'
      where st.id = p_stage_id
        and (
          sp.role = 'overall_leader'::public.servant_role
          or (sp.role = 'stage_leader'::public.servant_role and sp.stage_id = st.id)
        )
    );
$$;

create or replace function private.can_read_weekly_stage(p_stage_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select public.is_active_system_admin())
    or exists (
      select 1
      from public.stages st
      join public.servant_profiles sp
        on sp.service_id = st.service_id
       and sp.auth_user_id = (select auth.uid())
       and sp.account_status = 'active'
      where st.id = p_stage_id
        and (
          sp.role = 'overall_leader'::public.servant_role
          or (sp.role = 'stage_leader'::public.servant_role and sp.stage_id = st.id)
          or (sp.role in ('class_servant'::public.servant_role, 'class_leader'::public.servant_role)
              and exists (
                select 1 from public.classes c
                where c.id = sp.class_id and c.stage_id = st.id
              ))
        )
    );
$$;

revoke all on function private.can_manage_weekly_stage(uuid) from public, anon;
revoke all on function private.can_read_weekly_stage(uuid) from public, anon;
grant execute on function private.can_manage_weekly_stage(uuid) to authenticated;
grant execute on function private.can_read_weekly_stage(uuid) to authenticated;

create policy weekly_lessons_read_assigned_stage on public.weekly_lessons
  for select to authenticated
  using (
    (select private.can_manage_weekly_stage(weekly_lessons.stage_id))
    or (
      weekly_lessons.week_start = date_trunc('week', now() at time zone 'Africa/Cairo')::date
      and (select private.can_read_weekly_stage(weekly_lessons.stage_id))
    )
  );

create policy weekly_lessons_insert_leader on public.weekly_lessons
  for insert to authenticated
  with check (
    service_id = (select st.service_id from public.stages st where st.id = weekly_lessons.stage_id)
    and (select private.can_manage_weekly_stage(weekly_lessons.stage_id))
    and uploaded_by = (select auth.uid())
  );

create policy weekly_lessons_update_leader on public.weekly_lessons
  for update to authenticated
  using ((select private.can_manage_weekly_stage(weekly_lessons.stage_id)))
  with check (
    service_id = (select st.service_id from public.stages st where st.id = weekly_lessons.stage_id)
    and (select private.can_manage_weekly_stage(weekly_lessons.stage_id))
  );

create policy weekly_lessons_delete_leader on public.weekly_lessons
  for delete to authenticated
  using ((select private.can_manage_weekly_stage(weekly_lessons.stage_id)));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('weekly-lessons', 'weekly-lessons', false, 26214400, array['application/pdf'])
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy weekly_lessons_storage_read on storage.objects
  for select to authenticated
  using (
    bucket_id = 'weekly-lessons'
    and exists (
      select 1
      from public.weekly_lessons wl
      where wl.storage_path = storage.objects.name
        and wl.week_start = date_trunc('week', now() at time zone 'Africa/Cairo')::date
        and (select private.can_read_weekly_stage(wl.stage_id))
    )
  );

create policy weekly_lessons_storage_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'weekly-lessons'
    and array_length(storage.foldername(storage.objects.name), 1) >= 2
    and (select private.can_manage_weekly_stage((storage.foldername(storage.objects.name))[2]::uuid))
  );

create policy weekly_lessons_storage_update on storage.objects
  for update to authenticated
  using (
    bucket_id = 'weekly-lessons'
    and array_length(storage.foldername(storage.objects.name), 1) >= 2
    and (select private.can_manage_weekly_stage((storage.foldername(storage.objects.name))[2]::uuid))
  )
  with check (
    bucket_id = 'weekly-lessons'
    and array_length(storage.foldername(storage.objects.name), 1) >= 2
    and (select private.can_manage_weekly_stage((storage.foldername(storage.objects.name))[2]::uuid))
  );

create policy weekly_lessons_storage_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'weekly-lessons'
    and array_length(storage.foldername(storage.objects.name), 1) >= 2
    and (select private.can_manage_weekly_stage((storage.foldername(storage.objects.name))[2]::uuid))
  );
