-- A servant has one profile per service, so phone uniqueness must be scoped
-- to a service instead of blocking the same servant across services.
alter table public.servant_profiles
  drop constraint if exists servant_profiles_phone_key;

alter table public.servant_profiles
  add constraint servant_profiles_service_phone_unique unique (service_id, phone);

-- Enroll all selected service assignments and update the request in one
-- transaction. The admin check is explicit because this definer function
-- bypasses table RLS.
create or replace function public.enroll_servant_to_services(
  p_auth_user_id uuid,
  p_assignments jsonb
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  registration public.servant_registration_requests%rowtype;
  assignment jsonb;
  assignment_count integer;
  v_service_id uuid;
  selected_role text;
  v_stage_id uuid;
  v_class_id uuid;
begin
  if (select auth.uid()) is null
     or not (select public.is_active_system_admin()) then
    raise exception 'Only an active system administrator can enroll servants.'
      using errcode = '42501';
  end if;

  if p_auth_user_id is null or p_assignments is null
     or jsonb_typeof(p_assignments) is distinct from 'array'
     or jsonb_array_length(p_assignments) = 0 then
    raise exception 'Select at least one service assignment.' using errcode = '22023';
  end if;

  select requests.* into registration
  from public.servant_registration_requests as requests
  where requests.auth_user_id = p_auth_user_id
    and requests.status in ('pending', 'enrolled')
  for update;

  if not found then
    raise exception 'The servant registration request is unavailable.' using errcode = 'P0002';
  end if;
  if nullif(trim(registration.full_name), '') is null
     or nullif(trim(registration.phone), '') is null
     or registration.birth_date is null
     or nullif(trim(registration.work_study), '') is null then
    raise exception 'The servant must complete all required profile fields.' using errcode = '22023';
  end if;

  select count(*) into assignment_count from jsonb_array_elements(p_assignments);
  if assignment_count <> (
    select count(distinct item->>'service_id')
    from jsonb_array_elements(p_assignments) as items(item)
  ) then
    raise exception 'A service can only be selected once.' using errcode = '22023';
  end if;

  for assignment in select value from jsonb_array_elements(p_assignments)
  loop
    begin
      v_service_id := (assignment->>'service_id')::uuid;
      selected_role := assignment->>'role';
      v_stage_id := nullif(assignment->>'stage_id', '')::uuid;
      v_class_id := nullif(assignment->>'class_id', '')::uuid;
    exception when invalid_text_representation then
      raise exception 'A service, role, stage, or class selection is invalid.' using errcode = '22023';
    end;

    if not exists (select 1 from public.services as s where s.id = v_service_id) then
      raise exception 'A selected service no longer exists.' using errcode = '22023';
    end if;

    if selected_role in ('overall_leader', 'overall_helper') then
      if v_stage_id is not null or v_class_id is not null then
        raise exception 'Service-wide roles cannot be assigned to a stage or class.' using errcode = '23514';
      end if;
    elsif selected_role = 'stage_leader' then
      if v_stage_id is null or v_class_id is not null or not exists (
        select 1 from public.stages as s where s.id = v_stage_id and s.service_id = v_service_id
      ) then
        raise exception 'Choose a valid stage belonging to the selected service.' using errcode = '23514';
      end if;
    elsif selected_role in ('class_leader', 'class_servant') then
      if v_class_id is null or v_stage_id is not null or not exists (
        select 1 from public.classes as c
        join public.stages as s on s.id = c.stage_id
        where c.id = v_class_id and s.service_id = v_service_id
      ) then
        raise exception 'Choose a valid class belonging to the selected service.' using errcode = '23514';
      end if;
    else
      raise exception 'The selected servant role is invalid.' using errcode = '22023';
    end if;
  end loop;

  insert into public.servant_profiles (
    auth_user_id, service_id, name, phone, birth_date, work_study,
    role, stage_id, class_id, account_status
  )
  select p_auth_user_id,
         (item->>'service_id')::uuid,
         registration.full_name,
         registration.phone,
         registration.birth_date,
         registration.work_study,
         (item->>'role')::public.servant_role,
         nullif(item->>'stage_id', '')::uuid,
         nullif(item->>'class_id', '')::uuid,
         'active'::public.servant_account_status
  from jsonb_array_elements(p_assignments) as assignments(item)
  on conflict (auth_user_id, service_id) do update
    set name = excluded.name,
        phone = excluded.phone,
        birth_date = excluded.birth_date,
        work_study = excluded.work_study,
        role = excluded.role,
        stage_id = excluded.stage_id,
        class_id = excluded.class_id,
        account_status = 'active'::public.servant_account_status,
        updated_at = now();

  update public.servant_registration_requests
  set status = 'enrolled', reviewed_at = now(), reviewed_by = (select auth.uid())
  where auth_user_id = p_auth_user_id;

  return assignment_count;
end;
$$;

revoke all on function public.enroll_servant_to_services(uuid, jsonb)
  from public, anon, authenticated;
grant execute on function public.enroll_servant_to_services(uuid, jsonb)
  to authenticated;
