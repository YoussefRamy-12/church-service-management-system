-- Spiritual Notebook: service-scoped, immutable weekly point records.
create table if not exists public.spiritual_notebook_settings (
  service_id uuid primary key references public.services(id) on delete cascade,
  allow_zero_submissions boolean not null default false,
  max_bonus_points integer not null default 0 check (max_bonus_points >= 0),
  bonus_roles public.servant_role[] not null default '{}'::public.servant_role[],
  updated_at timestamptz not null default now()
);

insert into public.spiritual_notebook_settings (service_id)
select id from public.services
on conflict (service_id) do nothing;

create table if not exists public.spiritual_notebook_categories (
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references public.services(id) on delete cascade,
  name text not null check (length(trim(name)) > 0),
  display_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(service_id, id)
);

create table if not exists public.spiritual_notebook_activities (
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references public.services(id) on delete cascade,
  category_id uuid,
  name text not null check (length(trim(name)) > 0),
  description text,
  points integer not null check (points >= 0),
  is_active boolean not null default true,
  display_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint spiritual_activity_category_service_fk
    foreign key(service_id, category_id)
    references public.spiritual_notebook_categories(service_id, id)
);

create table if not exists public.spiritual_notebook_submissions (
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references public.services(id),
  student_id uuid not null references public.students(id),
  period_start date not null,
  period_end date not null,
  period_id text not null,
  submitted_by uuid not null references public.servant_profiles(id),
  activity_points integer not null check (activity_points >= 0),
  bonus_points integer not null default 0 check (bonus_points >= 0),
  bonus_reason text,
  total_points integer not null check (total_points >= 0),
  submitted_at timestamptz not null default now(),
  constraint spiritual_submission_friday_week check (
    extract(isodow from period_start) = 5 and period_end = period_start + 6
  ),
  constraint spiritual_submission_student_period_unique unique(student_id, period_start)
);

create table if not exists public.spiritual_notebook_submission_items (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null references public.spiritual_notebook_submissions(id) on delete cascade,
  activity_id uuid not null references public.spiritual_notebook_activities(id),
  activity_name_snapshot text not null,
  points_snapshot integer not null check (points_snapshot >= 0),
  category_name_snapshot text,
  unique(submission_id, activity_id)
);

create index if not exists spiritual_submissions_service_week_idx
  on public.spiritual_notebook_submissions(service_id, period_start desc);
create index if not exists spiritual_submissions_student_idx
  on public.spiritual_notebook_submissions(student_id, period_start desc);
create index if not exists spiritual_activities_service_order_idx
  on public.spiritual_notebook_activities(service_id, is_active, display_order);

alter table public.spiritual_notebook_settings enable row level security;
alter table public.spiritual_notebook_categories enable row level security;
alter table public.spiritual_notebook_activities enable row level security;
alter table public.spiritual_notebook_submissions enable row level security;
alter table public.spiritual_notebook_submission_items enable row level security;

grant select, insert, update on public.spiritual_notebook_settings to authenticated;
grant select, insert, update on public.spiritual_notebook_categories to authenticated;
grant select, insert, update on public.spiritual_notebook_activities to authenticated;
grant select on public.spiritual_notebook_submissions, public.spiritual_notebook_submission_items to authenticated;

create policy notebook_settings_read on public.spiritual_notebook_settings for select to authenticated
  using ((select private.can_access_service(service_id)));
create policy notebook_settings_manage on public.spiritual_notebook_settings for all to authenticated
  using ((select private.is_overall_admin_for_service(service_id)))
  with check ((select private.is_overall_admin_for_service(service_id)));

create policy notebook_categories_read on public.spiritual_notebook_categories for select to authenticated
  using ((select private.can_access_service(service_id)));
create policy notebook_categories_manage on public.spiritual_notebook_categories for all to authenticated
  using ((select private.is_overall_admin_for_service(service_id)))
  with check ((select private.is_overall_admin_for_service(service_id)));
create policy notebook_activities_read on public.spiritual_notebook_activities for select to authenticated
  using ((select private.can_access_service(service_id)));
create policy notebook_activities_manage on public.spiritual_notebook_activities for all to authenticated
  using ((select private.is_overall_admin_for_service(service_id)))
  with check ((select private.is_overall_admin_for_service(service_id)));

create policy notebook_submissions_read on public.spiritual_notebook_submissions for select to authenticated
  using (
    (select private.can_access_service(service_id)) and exists (
      select 1 from public.students s where s.id = student_id
        and (select private.can_access_class(s.current_class_id))
    )
  );
create policy notebook_items_read on public.spiritual_notebook_submission_items for select to authenticated
  using (exists (
    select 1 from public.spiritual_notebook_submissions s
    where s.id = submission_id
      and (select private.can_access_service(s.service_id))
      and exists (select 1 from public.students st where st.id = s.student_id
        and (select private.can_access_class(st.current_class_id)))
  ));

-- No direct writes to submissions/items. All writes go through this validated,
-- idempotency-protected server transaction; submitted rows are immutable.
create or replace function public.submit_spiritual_notebook(
  p_student_id uuid,
  p_period_start date,
  p_activity_ids uuid[],
  p_bonus_points integer default 0,
  p_bonus_reason text default null,
  p_operation_id uuid default gen_random_uuid()
) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_actor public.servant_profiles%rowtype;
  v_student public.students%rowtype;
  v_settings public.spiritual_notebook_settings%rowtype;
  v_submission_id uuid;
  v_activity_points integer;
begin
  select * into v_actor from public.servant_profiles
   where auth_user_id = (select auth.uid()) and account_status = 'active'
     and service_id = (select service_id from public.students where id = p_student_id)
   limit 1;
  select * into v_student from public.students where id = p_student_id and approval_status = 'approved';
  if v_actor.id is null or v_student.id is null then raise exception 'student_not_accessible'; end if;
  if v_actor.role not in ('overall_leader','overall_helper','stage_leader','class_leader','class_servant') then
    raise exception 'role_not_allowed';
  end if;
  if v_student.current_class_id is null or not (select private.can_access_class(v_student.current_class_id)) then
    raise exception 'student_out_of_scope';
  end if;
  if extract(isodow from p_period_start) <> 5 then raise exception 'invalid_period'; end if;
  if p_period_start < ((now() at time zone 'Africa/Cairo')::date - 7)
     or p_period_start > (now() at time zone 'Africa/Cairo')::date then raise exception 'period_out_of_range'; end if;
  select * into v_settings from public.spiritual_notebook_settings where service_id = v_student.service_id;
  if v_settings.service_id is null then raise exception 'notebook_not_configured'; end if;
  if p_bonus_points < 0 or p_bonus_points > v_settings.max_bonus_points then raise exception 'invalid_bonus'; end if;
  if p_bonus_points > 0 and (not (v_actor.role = any(v_settings.bonus_roles)) or nullif(trim(p_bonus_reason), '') is null) then
    raise exception 'bonus_not_authorized';
  end if;
  select coalesce(sum(a.points),0) into v_activity_points
    from public.spiritual_notebook_activities a
   where a.service_id = v_student.service_id and a.is_active and a.id = any(coalesce(p_activity_ids, '{}'::uuid[]));
  if cardinality(coalesce(p_activity_ids, '{}'::uuid[])) = 0 and not v_settings.allow_zero_submissions then
    raise exception 'activity_required';
  end if;
  if v_activity_points <> (select coalesce(sum(points),0) from public.spiritual_notebook_activities a
    where a.service_id = v_student.service_id and a.is_active and a.id = any(coalesce(p_activity_ids, '{}'::uuid[]))) then
    raise exception 'invalid_activity_selection';
  end if;
  -- Ensure every submitted activity belongs to this service and is active.
  if cardinality(coalesce(p_activity_ids, '{}'::uuid[])) <> (select count(*) from public.spiritual_notebook_activities a
    where a.service_id = v_student.service_id and a.is_active and a.id = any(coalesce(p_activity_ids, '{}'::uuid[]))) then
    raise exception 'invalid_activity_selection';
  end if;
  insert into public.spiritual_notebook_submissions
    (id, service_id, student_id, period_start, period_end, period_id, submitted_by, activity_points, bonus_points, bonus_reason, total_points)
  values (p_operation_id, v_student.service_id, v_student.id, p_period_start, p_period_start + 6,
    to_char(p_period_start, 'YYYY-MM-DD') || '_' || to_char(p_period_start + 6, 'YYYY-MM-DD'),
    v_actor.id, v_activity_points, p_bonus_points, nullif(trim(p_bonus_reason), ''), v_activity_points + p_bonus_points)
  on conflict (student_id, period_start) do nothing returning id into v_submission_id;
  if v_submission_id is null then
    select id into v_submission_id from public.spiritual_notebook_submissions
      where student_id = p_student_id and period_start = p_period_start;
    if v_submission_id <> p_operation_id then raise exception 'already_submitted'; end if;
    return v_submission_id;
  end if;
  insert into public.spiritual_notebook_submission_items
    (submission_id, activity_id, activity_name_snapshot, points_snapshot, category_name_snapshot)
  select v_submission_id, a.id, a.name, a.points, c.name
    from public.spiritual_notebook_activities a left join public.spiritual_notebook_categories c on c.id = a.category_id
   where a.service_id = v_student.service_id and a.is_active and a.id = any(coalesce(p_activity_ids, '{}'::uuid[]));
  return v_submission_id;
end;
$$;
revoke all on function public.submit_spiritual_notebook(uuid,date,uuid[],integer,text,uuid) from public, anon;
grant execute on function public.submit_spiritual_notebook(uuid,date,uuid[],integer,text,uuid) to authenticated;
