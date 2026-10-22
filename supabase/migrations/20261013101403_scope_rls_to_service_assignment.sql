-- Multi-service accounts need authorization to be evaluated against the
-- service/class on the row, never an arbitrary first profile for auth.uid().
create or replace function private.is_overall_admin_for_service(p_service_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select private.is_super_admin())
    or exists (
      select 1
      from public.servant_profiles sp
      where sp.auth_user_id = (select auth.uid())
        and sp.service_id = p_service_id
        and sp.account_status = 'active'
        and sp.role in ('overall_leader'::public.servant_role, 'overall_helper'::public.servant_role)
    );
$$;

create or replace function private.can_access_service(p_service_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select private.is_super_admin())
    or exists (
      select 1 from public.servant_profiles sp
      where sp.auth_user_id = (select auth.uid())
        and sp.service_id = p_service_id
        and sp.account_status = 'active'
    );
$$;

create or replace function private.can_access_stage(p_stage_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select private.is_super_admin())
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
          or (sp.role in ('class_leader'::public.servant_role, 'class_servant'::public.servant_role)
              and exists (
                select 1 from public.classes c
                where c.id = sp.class_id and c.stage_id = st.id
              ))
        )
    );
$$;

create or replace function private.can_access_class(p_class_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select private.is_super_admin())
    or exists (
      select 1
      from public.classes c
      join public.stages st on st.id = c.stage_id
      join public.servant_profiles sp
        on sp.service_id = st.service_id
       and sp.auth_user_id = (select auth.uid())
       and sp.account_status = 'active'
      where c.id = p_class_id
        and (
          sp.role in ('overall_leader'::public.servant_role, 'overall_helper'::public.servant_role)
          or (sp.role = 'stage_leader'::public.servant_role and sp.stage_id = st.id)
          or (sp.role in ('class_leader'::public.servant_role, 'class_servant'::public.servant_role)
              and sp.class_id = c.id)
        )
    );
$$;

revoke all on function private.is_overall_admin_for_service(uuid) from public, anon;
revoke all on function private.can_access_service(uuid) from public, anon;
revoke all on function private.can_access_stage(uuid) from public, anon;
revoke all on function private.can_access_class(uuid) from public, anon;
grant execute on function private.is_overall_admin_for_service(uuid) to authenticated;
grant execute on function private.can_access_service(uuid) to authenticated;
grant execute on function private.can_access_stage(uuid) to authenticated;
grant execute on function private.can_access_class(uuid) to authenticated;

-- Service and structure management must use the servant's role in that same
-- service. Existing SELECT policies now use the row-aware access helpers above.
drop policy if exists services_admin_update_service_scope on public.services;
create policy services_admin_update_service_scope on public.services
  for update to authenticated
  using ((select private.is_overall_admin_for_service(services.id)))
  with check ((select private.is_overall_admin_for_service(services.id)));

drop policy if exists stages_admin_insert on public.stages;
create policy stages_admin_insert on public.stages
  for insert to authenticated
  with check ((select private.is_overall_admin_for_service(stages.service_id)));
drop policy if exists stages_admin_update on public.stages;
create policy stages_admin_update on public.stages
  for update to authenticated
  using ((select private.is_overall_admin_for_service(stages.service_id)))
  with check ((select private.is_overall_admin_for_service(stages.service_id)));

drop policy if exists classes_admin_insert on public.classes;
create policy classes_admin_insert on public.classes
  for insert to authenticated
  with check (exists (
    select 1 from public.stages st
    where st.id = classes.stage_id
      and (select private.is_overall_admin_for_service(st.service_id))
  ));
drop policy if exists classes_admin_update on public.classes;
create policy classes_admin_update on public.classes
  for update to authenticated
  using (exists (
    select 1 from public.stages st
    where st.id = classes.stage_id
      and (select private.is_overall_admin_for_service(st.service_id))
  ))
  with check (exists (
    select 1 from public.stages st
    where st.id = classes.stage_id
      and (select private.is_overall_admin_for_service(st.service_id))
  ));

drop policy if exists servant_profiles_select on public.servant_profiles;
create policy servant_profiles_select on public.servant_profiles
  for select to authenticated
  using (
    auth_user_id = (select auth.uid())
    or (select private.is_super_admin())
    or (select private.is_overall_admin_for_service(servant_profiles.service_id))
    or (
      account_status = 'active'::public.servant_account_status
      and role = 'stage_leader'::public.servant_role
      and (select private.can_access_stage(servant_profiles.stage_id))
    )
    or (
      account_status = 'active'::public.servant_account_status
      and role = 'class_leader'::public.servant_role
      and (select private.can_access_class(servant_profiles.class_id))
    )
  );

drop policy if exists servant_profiles_insert_admin on public.servant_profiles;
create policy servant_profiles_insert_admin on public.servant_profiles
  for insert to authenticated
  with check ((select private.is_overall_admin_for_service(servant_profiles.service_id)));
drop policy if exists servant_profiles_update_admin on public.servant_profiles;
create policy servant_profiles_update_admin on public.servant_profiles
  for update to authenticated
  using ((select private.is_overall_admin_for_service(servant_profiles.service_id)))
  with check ((select private.is_overall_admin_for_service(servant_profiles.service_id)));
drop policy if exists servant_profiles_delete_admin on public.servant_profiles;
create policy servant_profiles_delete_admin on public.servant_profiles
  for delete to authenticated
  using ((select private.is_overall_admin_for_service(servant_profiles.service_id)));

-- Ensure system administrators and service leaders can manage roles without being blocked by self-escalation trigger
create or replace function public.prevent_servant_self_escalation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is not null
     and not (select public.is_active_system_admin())
     and not exists (
       select 1 from public.servant_profiles sp
       where sp.auth_user_id = (select auth.uid())
         and sp.service_id = new.service_id
         and sp.account_status = 'active'
         and sp.role in ('overall_leader', 'overall_helper')
     )
     and (
       new.auth_user_id is distinct from old.auth_user_id
       or new.service_id is distinct from old.service_id
       or new.role is distinct from old.role
       or new.stage_id is distinct from old.stage_id
       or new.class_id is distinct from old.class_id
       or new.account_status is distinct from old.account_status
       or new.must_change_password is distinct from old.must_change_password
     )
  then
    raise exception 'Authorization fields cannot be changed by this user';
  end if;
  return new;
end;
$$;

drop policy if exists meetings_admin_insert on public.meetings;
create policy meetings_admin_insert on public.meetings
  for insert to authenticated
  with check ((select private.is_overall_admin_for_service(meetings.service_id)));
drop policy if exists meetings_admin_update on public.meetings;
create policy meetings_admin_update on public.meetings
  for update to authenticated
  using ((select private.is_overall_admin_for_service(meetings.service_id)))
  with check ((select private.is_overall_admin_for_service(meetings.service_id)));

drop policy if exists reporting_periods_admin_insert on public.reporting_periods;
create policy reporting_periods_admin_insert on public.reporting_periods
  for insert to authenticated
  with check ((select private.is_overall_admin_for_service(reporting_periods.service_id)));
drop policy if exists reporting_periods_admin_update on public.reporting_periods;
create policy reporting_periods_admin_update on public.reporting_periods
  for update to authenticated
  using ((select private.is_overall_admin_for_service(reporting_periods.service_id)))
  with check ((select private.is_overall_admin_for_service(reporting_periods.service_id)));

-- Keep student and related data limited to the role assigned in the row's service.
drop policy if exists students_insert on public.students;
create policy students_insert on public.students
  for insert to authenticated
  with check (
    (select private.can_access_service(students.service_id))
    and (
      (select private.is_overall_admin_for_service(students.service_id))
      or (
        approval_status = 'pending'::public.student_approval_status
        and current_class_id is null
        and (select private.can_access_class(students.proposed_class_id))
      )
    )
  );
drop policy if exists students_select on public.students;
create policy students_select on public.students
  for select to authenticated
  using (
    (select private.can_access_service(students.service_id))
    and (
      (select private.is_overall_admin_for_service(students.service_id))
      or (select private.can_access_class(students.current_class_id))
      or (
        approval_status = 'pending'::public.student_approval_status
        and (select private.can_access_class(students.proposed_class_id))
      )
    )
  );
drop policy if exists students_update on public.students;
create policy students_update on public.students
  for update to authenticated
  using (
    (select private.can_access_service(students.service_id))
    and (
      (select private.is_overall_admin_for_service(students.service_id))
      or (select private.can_access_class(students.current_class_id))
      or (
        approval_status = 'pending'::public.student_approval_status
        and (select private.can_access_class(students.proposed_class_id))
      )
    )
  )
  with check (
    (select private.can_access_service(students.service_id))
    and (
      (select private.is_overall_admin_for_service(students.service_id))
      or (
        approval_status = 'pending'::public.student_approval_status
        and current_class_id is null
        and (select private.can_access_class(students.proposed_class_id))
      )
      or (select private.can_access_class(students.current_class_id))
    )
  );

drop policy if exists sensitive_select on public.student_sensitive_data;
create policy sensitive_select on public.student_sensitive_data
  for select to authenticated
  using (exists (
    select 1 from public.students s
    where s.id = student_sensitive_data.student_id
      and (select private.can_access_service(s.service_id))
      and (
        (select private.is_overall_admin_for_service(s.service_id))
        or (select private.can_access_class(coalesce(s.current_class_id, s.proposed_class_id)))
      )
  ));
drop policy if exists sensitive_insert on public.student_sensitive_data;
create policy sensitive_insert on public.student_sensitive_data
  for insert to authenticated
  with check (exists (
    select 1 from public.students s
    where s.id = student_sensitive_data.student_id
      and (select private.can_access_service(s.service_id))
      and (
        (select private.is_overall_admin_for_service(s.service_id))
        or (select private.can_access_class(coalesce(s.current_class_id, s.proposed_class_id)))
      )
  ));
drop policy if exists sensitive_update on public.student_sensitive_data;
create policy sensitive_update on public.student_sensitive_data
  for update to authenticated
  using (exists (
    select 1 from public.students s
    where s.id = student_sensitive_data.student_id
      and (select private.can_access_service(s.service_id))
      and (
        (select private.is_overall_admin_for_service(s.service_id))
        or (select private.can_access_class(coalesce(s.current_class_id, s.proposed_class_id)))
      )
  ))
  with check (exists (
    select 1 from public.students s
    where s.id = student_sensitive_data.student_id
      and (select private.can_access_service(s.service_id))
      and (
        (select private.is_overall_admin_for_service(s.service_id))
        or (select private.can_access_class(coalesce(s.current_class_id, s.proposed_class_id)))
      )
  ));

drop policy if exists follow_up_select on public.follow_up_records;
create policy follow_up_select on public.follow_up_records
  for select to authenticated
  using (exists (
    select 1 from public.students s
    where s.id = follow_up_records.student_id
      and (select private.can_access_service(s.service_id))
      and (
        (select private.is_overall_admin_for_service(s.service_id))
        or (select private.can_access_class(coalesce(s.current_class_id, s.proposed_class_id)))
      )
  ));
drop policy if exists follow_up_insert on public.follow_up_records;
create policy follow_up_insert on public.follow_up_records
  for insert to authenticated
  with check (exists (
    select 1
    from public.students s
    join public.servant_profiles sp
      on sp.auth_user_id = (select auth.uid())
     and sp.service_id = s.service_id
     and sp.account_status = 'active'
    where s.id = follow_up_records.student_id
      and follow_up_records.created_by = sp.id
      and s.approval_status = 'approved'::public.student_approval_status
      and (select private.can_access_service(s.service_id))
      and (
        (select private.is_overall_admin_for_service(s.service_id))
        or (select private.can_access_class(s.current_class_id))
      )
  ));
drop policy if exists follow_up_update on public.follow_up_records;
create policy follow_up_update on public.follow_up_records
  for update to authenticated
  using (exists (
    select 1 from public.students s
    where s.id = follow_up_records.student_id
      and (select private.can_access_service(s.service_id))
      and (
        (select private.is_overall_admin_for_service(s.service_id))
        or (select private.can_access_class(coalesce(s.current_class_id, s.proposed_class_id)))
      )
  ))
  with check (exists (
    select 1 from public.students s
    where s.id = follow_up_records.student_id
      and (select private.can_access_service(s.service_id))
      and (
        (select private.is_overall_admin_for_service(s.service_id))
        or (select private.can_access_class(coalesce(s.current_class_id, s.proposed_class_id)))
      )
  ));

drop policy if exists attendance_select on public.attendance_records;
create policy attendance_select on public.attendance_records
  for select to authenticated
  using (exists (
    select 1 from public.meetings m
    where m.id = attendance_records.meeting_id
      and (select private.can_access_service(m.service_id))
      and (
        (select private.is_overall_admin_for_service(m.service_id))
        or (select private.can_access_class(attendance_records.class_id_at_attendance))
      )
  ));
drop policy if exists attendance_update on public.attendance_records;
create policy attendance_update on public.attendance_records
  for update to authenticated
  using (exists (
    select 1 from public.meetings m
    where m.id = attendance_records.meeting_id
      and (select private.can_access_service(m.service_id))
      and (
        (select private.is_overall_admin_for_service(m.service_id))
        or (select private.can_access_class(attendance_records.class_id_at_attendance))
      )
  ))
  with check (exists (
    select 1 from public.meetings m
    where m.id = attendance_records.meeting_id
      and (select private.can_access_service(m.service_id))
      and (
        (select private.is_overall_admin_for_service(m.service_id))
        or (select private.can_access_class(attendance_records.class_id_at_attendance))
      )
  ));
drop policy if exists attendance_insert on public.attendance_records;
create policy attendance_insert on public.attendance_records
  for insert to authenticated
  with check (exists (
    select 1
    from public.meetings m
    join public.servant_profiles sp
      on sp.auth_user_id = (select auth.uid())
     and sp.service_id = m.service_id
     and sp.account_status = 'active'
    join public.students s on s.id = attendance_records.student_id
    where m.id = attendance_records.meeting_id
      and attendance_records.recorded_by = sp.id
      and s.service_id = m.service_id
      and (
        (s.approval_status = 'approved'::public.student_approval_status
         and s.current_class_id = attendance_records.class_id_at_attendance)
        or (s.approval_status = 'pending'::public.student_approval_status
            and s.current_class_id is null
            and s.proposed_class_id = attendance_records.class_id_at_attendance)
      )
      and (select private.can_access_class(attendance_records.class_id_at_attendance))
  ));

notify pgrst, 'reload schema';