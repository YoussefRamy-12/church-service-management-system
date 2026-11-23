-- Migration: 20261111230000_weekly_prep_review_system.sql
-- Description: Implement review-based weekly preparation (تحضيري) system:
--   1. Fix can_manage_weekly_stage and can_read_weekly_stage to include overall_helper
--   2. Extend weekly_lesson_preparations with review status, timestamps, reviewer, note
--   3. Create weekly_lesson_preparation_reviews history table
--   4. Implement secure server-side review RPC function (prevents self-review, enforces state transitions)
--   5. Update RLS policies for servant and leadership access

-- 1. Fix private.can_manage_weekly_stage to include overall_helper
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
          sp.role in ('overall_leader'::public.servant_role, 'overall_helper'::public.servant_role)
          or (sp.role = 'stage_leader'::public.servant_role and sp.stage_id = st.id)
        )
    );
$$;

-- 2. Fix private.can_read_weekly_stage to include overall_helper
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
          sp.role in ('overall_leader'::public.servant_role, 'overall_helper'::public.servant_role)
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

-- 3. Extend weekly_lesson_preparations table
alter table public.weekly_lesson_preparations
  add column if not exists status text not null default 'not_submitted',
  add column if not exists submitted_at timestamptz,
  add column if not exists reviewed_at timestamptz,
  add column if not exists reviewed_by uuid references public.servant_profiles(id) on delete set null,
  add column if not exists review_note text;

-- Add check constraint for valid status values
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'weekly_lesson_preparations_status_check'
  ) then
    alter table public.weekly_lesson_preparations
      add constraint weekly_lesson_preparations_status_check
      check (status in ('not_submitted', 'submitted', 'approved', 'needs_revision'));
  end if;
end $$;

-- 4. Migrate existing data safely without inventing review history
update public.weekly_lesson_preparations
set status = case
  when prepared = true then 'submitted'
  else 'not_submitted'
end
where status = 'not_submitted' and prepared = true;

-- 5. Create weekly_lesson_preparation_reviews (history table)
create table if not exists public.weekly_lesson_preparation_reviews (
  id uuid primary key default gen_random_uuid(),
  weekly_lesson_id uuid not null,
  servant_profile_id uuid not null,
  reviewer_id uuid not null references public.servant_profiles(id) on delete cascade,
  action text not null check (action in ('approved', 'needs_revision')),
  note text,
  reviewed_at timestamptz not null default now(),
  constraint fk_prep_review_parent
    foreign key (weekly_lesson_id, servant_profile_id)
    references public.weekly_lesson_preparations(weekly_lesson_id, servant_profile_id)
    on delete cascade
);

create index if not exists weekly_lesson_prep_reviews_idx
  on public.weekly_lesson_preparation_reviews(weekly_lesson_id, servant_profile_id, reviewed_at desc);

create index if not exists weekly_lesson_preparations_status_idx
  on public.weekly_lesson_preparations(status);

alter table public.weekly_lesson_preparation_reviews enable row level security;
grant select on public.weekly_lesson_preparation_reviews to authenticated;

-- 6. RLS on weekly_lesson_preparation_reviews
drop policy if exists weekly_lesson_prep_reviews_read on public.weekly_lesson_preparation_reviews;
create policy weekly_lesson_prep_reviews_read on public.weekly_lesson_preparation_reviews
  for select to authenticated
  using (
    -- Servant reads their own review history
    exists (
      select 1 from public.servant_profiles sp
      where sp.id = weekly_lesson_preparation_reviews.servant_profile_id
        and sp.auth_user_id = (select auth.uid())
        and sp.account_status = 'active'
    )
    or
    -- In-scope leader reads review history
    exists (
      select 1 from public.weekly_lessons wl
      where wl.id = weekly_lesson_preparation_reviews.weekly_lesson_id
        and (select private.can_manage_weekly_stage(wl.stage_id))
    )
  );

-- Direct client INSERT into reviews table is blocked; insertion is handled exclusively via review RPC
drop policy if exists weekly_lesson_prep_reviews_insert_rpc_only on public.weekly_lesson_preparation_reviews;
create policy weekly_lesson_prep_reviews_insert_rpc_only on public.weekly_lesson_preparation_reviews
  for insert to authenticated
  with check (false);

-- 7. Update RLS policies on weekly_lesson_preparations

-- SELECT: Servant reads own; Leaders read within their stage scope
drop policy if exists weekly_lesson_preparations_read_self on public.weekly_lesson_preparations;
drop policy if exists weekly_lesson_preparations_read on public.weekly_lesson_preparations;
create policy weekly_lesson_preparations_read on public.weekly_lesson_preparations
  for select to authenticated
  using (
    exists (
      select 1 from public.servant_profiles sp
      where sp.id = weekly_lesson_preparations.servant_profile_id
        and sp.auth_user_id = (select auth.uid())
        and sp.account_status = 'active'
    )
    or
    exists (
      select 1 from public.weekly_lessons wl
      where wl.id = weekly_lesson_preparations.weekly_lesson_id
        and (select private.can_manage_weekly_stage(wl.stage_id))
    )
  );

-- INSERT: Servant creates own preparation for readable stage
drop policy if exists weekly_lesson_preparations_insert_self on public.weekly_lesson_preparations;
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
        and (select private.can_read_weekly_stage(wl.stage_id))
    )
    -- Servant cannot directly insert as approved or needs_revision
    and weekly_lesson_preparations.status in ('not_submitted', 'submitted')
  );

-- UPDATE: Servant can submit or resubmit own preparation
drop policy if exists weekly_lesson_preparations_update_self on public.weekly_lesson_preparations;
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
    -- Servant can only transition to 'submitted' (never self-approve)
    and weekly_lesson_preparations.status = 'submitted'
  );

-- 8. Server-side review RPC function (SECURITY DEFINER)
create or replace function public.review_weekly_preparation(
  p_lesson_id uuid,
  p_servant_profile_id uuid,
  p_action text,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_reviewer_id uuid;
  v_current_status text;
  v_trimmed_note text;
begin
  -- Validate action
  if p_action not in ('approved', 'needs_revision') then
    raise exception 'invalid_action';
  end if;

  v_trimmed_note := trim(coalesce(p_note, ''));

  -- Mandatory feedback when returning for revision
  if p_action = 'needs_revision' and v_trimmed_note = '' then
    raise exception 'feedback_required';
  end if;

  -- Authenticate reviewer identity from auth.uid() server-side
  select id into v_reviewer_id
  from public.servant_profiles
  where auth_user_id = (select auth.uid())
    and account_status = 'active'
  limit 1;

  if v_reviewer_id is null then
    raise exception 'reviewer_not_found';
  end if;

  -- Prevent self-approval / self-review
  if v_reviewer_id = p_servant_profile_id then
    raise exception 'self_review_forbidden';
  end if;

  -- Verify reviewer has management authorization over lesson's stage
  if not exists (
    select 1 from public.weekly_lessons wl
    where wl.id = p_lesson_id
      and (select private.can_manage_weekly_stage(wl.stage_id))
  ) then
    raise exception 'unauthorized_scope';
  end if;

  -- Fetch current preparation record status
  select status into v_current_status
  from public.weekly_lesson_preparations
  where weekly_lesson_id = p_lesson_id
    and servant_profile_id = p_servant_profile_id;

  if v_current_status is null then
    raise exception 'preparation_not_found';
  end if;

  -- Only submissions currently awaiting review ('submitted') can be reviewed
  if v_current_status != 'submitted' then
    raise exception 'invalid_state_transition: current status is %', v_current_status;
  end if;

  -- 1. Insert review history record
  insert into public.weekly_lesson_preparation_reviews (
    id,
    weekly_lesson_id,
    servant_profile_id,
    reviewer_id,
    action,
    note,
    reviewed_at
  ) values (
    gen_random_uuid(),
    p_lesson_id,
    p_servant_profile_id,
    v_reviewer_id,
    p_action,
    case when v_trimmed_note = '' then null else v_trimmed_note end,
    now()
  );

  -- 2. Update preparation state
  update public.weekly_lesson_preparations
  set
    status = p_action,
    prepared = (p_action = 'approved'),
    reviewed_at = now(),
    reviewed_by = v_reviewer_id,
    review_note = case when v_trimmed_note = '' then null else v_trimmed_note end,
    updated_at = now()
  where weekly_lesson_id = p_lesson_id
    and servant_profile_id = p_servant_profile_id;
end;
$$;

revoke all on function public.review_weekly_preparation(uuid, uuid, text, text) from public, anon;
grant execute on function public.review_weekly_preparation(uuid, uuid, text, text) to authenticated;

