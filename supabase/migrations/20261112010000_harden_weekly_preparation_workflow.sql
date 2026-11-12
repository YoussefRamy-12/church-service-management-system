-- Harden weekly preparation state transitions at the database boundary.
-- Servants may submit a new preparation or resubmit only after revision feedback.
-- Reviewers may change submitted -> approved/needs_revision only through the RPC.
-- All other status and review metadata mutations are rejected.

create or replace function private.guard_weekly_preparation_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_profile_id uuid;
  v_is_admin boolean;
  v_lesson_stage_id uuid;
  v_lesson_week_start date;
  v_current_week_start date;
begin
  select sp.id
    into v_actor_profile_id
  from public.servant_profiles sp
  where sp.auth_user_id = (select auth.uid())
    and sp.account_status = 'active'
  limit 1;

  v_is_admin := coalesce((select public.is_active_system_admin()), false);

  select wl.stage_id, wl.week_start::date
    into v_lesson_stage_id, v_lesson_week_start
  from public.weekly_lessons wl
  where wl.id = new.weekly_lesson_id;

  if v_lesson_stage_id is null or v_lesson_week_start is null then
    raise exception 'weekly_lesson_not_found';
  end if;

  v_current_week_start :=
    (date_trunc('week', (now() at time zone 'Africa/Cairo'))::date);

  if tg_op = 'INSERT' then
    if new.status <> 'submitted'
       or new.prepared is distinct from false
       or new.reviewed_at is not null
       or new.reviewed_by is not null
       or new.review_note is not null then
      raise exception 'invalid_initial_preparation_state';
    end if;

    if v_actor_profile_id is null
       or new.servant_profile_id <> v_actor_profile_id then
      raise exception 'preparation_owner_mismatch';
    end if;

    if v_lesson_week_start <> v_current_week_start then
      raise exception 'historical_preparation_submission_forbidden';
    end if;

    new.submitted_at := coalesce(new.submitted_at, now());
    return new;
  end if;

  -- Identity columns must never be reassigned.
  if new.weekly_lesson_id <> old.weekly_lesson_id
     or new.servant_profile_id <> old.servant_profile_id then
    raise exception 'preparation_identity_immutable';
  end if;

  -- An uncertain network response may cause the same queued submission to
  -- be replayed after the server already accepted it. Treat submitted -> submitted
  -- as an idempotent no-op; never let it rewrite the original submission timestamp.
  if v_actor_profile_id is not null
     and new.servant_profile_id = v_actor_profile_id
     and old.status = 'submitted'
     and new.status = 'submitted' then
    return old;
  end if;

  -- A servant can only submit a new record or resubmit a returned one.
  if v_actor_profile_id is not null
     and new.servant_profile_id = v_actor_profile_id then
    if old.status not in ('not_submitted', 'needs_revision')
       or new.status <> 'submitted' then
      raise exception 'invalid_servant_preparation_transition';
    end if;

    if v_lesson_week_start <> v_current_week_start then
      raise exception 'historical_preparation_submission_forbidden';
    end if;

    if new.reviewed_at is distinct from old.reviewed_at
       or new.reviewed_by is distinct from old.reviewed_by
       or new.review_note is distinct from old.review_note
       or new.prepared is distinct from false then
      raise exception 'review_metadata_is_server_managed';
    end if;

    new.submitted_at := now();
    return new;
  end if;

  -- Leadership review transitions are only allowed for an authorized reviewer.
  if old.status <> 'submitted'
     or new.status not in ('approved', 'needs_revision') then
    raise exception 'invalid_reviewer_preparation_transition';
  end if;

  if not v_is_admin
     and not (select private.can_manage_weekly_stage(v_lesson_stage_id)) then
    raise exception 'unauthorized_scope';
  end if;

  if v_actor_profile_id is null
     or new.reviewed_by is distinct from v_actor_profile_id
     or new.reviewed_at is null then
    raise exception 'invalid_reviewer_metadata';
  end if;

  if new.status = 'approved' and new.prepared is distinct from true then
    raise exception 'approved_preparation_must_be_prepared';
  end if;

  if new.status = 'needs_revision'
     and (new.review_note is null or length(trim(new.review_note)) = 0) then
    raise exception 'feedback_required';
  end if;

  return new;
end;
$$;

revoke all on function private.guard_weekly_preparation_write() from public, anon, authenticated;

drop trigger if exists weekly_preparation_write_guard
  on public.weekly_lesson_preparations;

create trigger weekly_preparation_write_guard
before insert or update on public.weekly_lesson_preparations
for each row execute function private.guard_weekly_preparation_write();

-- Serialize reviews of the same preparation so two leaders cannot both review
-- the same submitted state and create duplicate history rows.
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
  v_stage_id uuid;
begin
  if p_action not in ('approved', 'needs_revision') then
    raise exception 'invalid_action';
  end if;

  v_trimmed_note := trim(coalesce(p_note, ''));

  if p_action = 'needs_revision' and v_trimmed_note = '' then
    raise exception 'feedback_required';
  end if;

  select sp.id
    into v_reviewer_id
  from public.servant_profiles sp
  where sp.auth_user_id = (select auth.uid())
    and sp.account_status = 'active'
  limit 1;

  if v_reviewer_id is null then
    raise exception 'reviewer_not_found';
  end if;

  if v_reviewer_id = p_servant_profile_id then
    raise exception 'self_review_forbidden';
  end if;

  select wl.stage_id
    into v_stage_id
  from public.weekly_lessons wl
  where wl.id = p_lesson_id;

  if v_stage_id is null then
    raise exception 'weekly_lesson_not_found';
  end if;

  if not coalesce((select public.is_active_system_admin()), false)
     and not (select private.can_manage_weekly_stage(v_stage_id)) then
    raise exception 'unauthorized_scope';
  end if;

  select p.status
    into v_current_status
  from public.weekly_lesson_preparations p
  where p.weekly_lesson_id = p_lesson_id
    and p.servant_profile_id = p_servant_profile_id
  for update;

  if v_current_status is null then
    raise exception 'preparation_not_found';
  end if;

  if v_current_status <> 'submitted' then
    raise exception 'invalid_state_transition: current status is %', v_current_status;
  end if;

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
