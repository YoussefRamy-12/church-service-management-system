alter table public.follow_up_records
  add column if not exists assigned_to uuid references public.servant_profiles(id) on delete set null,
  add column if not exists is_request boolean not null default false,
  add column if not exists request_status text not null default 'open'
    check (request_status in ('open', 'in_progress', 'completed'));

create index if not exists follow_up_assigned_requests_idx
  on public.follow_up_records(assigned_to, request_status, follow_up_date)
  where is_request = true;

drop policy if exists follow_up_select on public.follow_up_records;
create policy follow_up_select on public.follow_up_records
  for select to authenticated
  using (exists (
    select 1
    from public.students s
    join public.servant_profiles sp
      on sp.auth_user_id = (select auth.uid())
     and sp.service_id = s.service_id
     and sp.account_status = 'active'
    where s.id = follow_up_records.student_id
      and (select private.can_access_service(s.service_id))
      and (
        (
          not follow_up_records.is_request
          and (
            (select private.is_overall_admin_for_service(s.service_id))
            or (select private.can_access_class(coalesce(s.current_class_id, s.proposed_class_id)))
          )
        )
        or (
          follow_up_records.is_request
          and (
            follow_up_records.assigned_to = sp.id
            or (
              sp.role::text in ('overall_leader', 'overall_helper', 'stage_leader', 'class_leader')
              and (
                (select private.is_overall_admin_for_service(s.service_id))
                or (select private.can_access_class(coalesce(s.current_class_id, s.proposed_class_id)))
              )
            )
          )
        )
      )
  ));

drop policy if exists follow_up_insert on public.follow_up_records;
create policy follow_up_insert on public.follow_up_records
  for insert to authenticated
  with check (exists (
    select 1
    from public.students s
    join public.servant_profiles creator
      on creator.auth_user_id = (select auth.uid())
     and creator.service_id = s.service_id
     and creator.account_status = 'active'
    where s.id = follow_up_records.student_id
      and follow_up_records.created_by = creator.id
      and s.approval_status = 'approved'::public.student_approval_status
      and (select private.can_access_service(s.service_id))
      and (
        (
          follow_up_records.is_request
          and creator.role::text in ('overall_leader', 'overall_helper', 'stage_leader', 'class_leader')
          and (
            (select private.is_overall_admin_for_service(s.service_id))
            or (select private.can_access_class(s.current_class_id))
          )
          and exists (
            select 1 from public.servant_profiles assignee
            where assignee.id = follow_up_records.assigned_to
              and assignee.service_id = s.service_id
              and assignee.account_status = 'active'
              and assignee.role::text = 'class_servant'
              and assignee.class_id = s.current_class_id
          )
        )
        or (
          not follow_up_records.is_request
          and creator.role::text = 'class_servant'
          and creator.class_id = s.current_class_id
          and follow_up_records.assigned_to = creator.id
          and (select private.can_access_class(s.current_class_id))
        )
      )
  ));

drop policy if exists follow_up_update on public.follow_up_records;
create policy follow_up_update on public.follow_up_records
  for update to authenticated
  using (exists (
    select 1
    from public.students s
    join public.servant_profiles actor
      on actor.auth_user_id = (select auth.uid())
     and actor.service_id = s.service_id
     and actor.account_status = 'active'
    where s.id = follow_up_records.student_id
      and (select private.can_access_service(s.service_id))
      and (
        (
          follow_up_records.is_request
          and (
            (follow_up_records.assigned_to = actor.id and actor.role::text = 'class_servant')
            or (
              actor.role::text in ('overall_leader', 'overall_helper', 'stage_leader', 'class_leader')
              and (
                (select private.is_overall_admin_for_service(s.service_id))
                or (select private.can_access_class(coalesce(s.current_class_id, s.proposed_class_id)))
              )
            )
          )
        )
        or (
          not follow_up_records.is_request
          and (
            (select private.is_overall_admin_for_service(s.service_id))
            or (select private.can_access_class(coalesce(s.current_class_id, s.proposed_class_id)))
          )
        )
      )
  ))
  with check (exists (
    select 1
    from public.students s
    join public.servant_profiles actor
      on actor.auth_user_id = (select auth.uid())
     and actor.service_id = s.service_id
     and actor.account_status = 'active'
    where s.id = follow_up_records.student_id
      and (select private.can_access_service(s.service_id))
      and (
        (
          follow_up_records.is_request
          and (
            (follow_up_records.assigned_to = actor.id and actor.role::text = 'class_servant')
            or (
              actor.role::text in ('overall_leader', 'overall_helper', 'stage_leader', 'class_leader')
              and (
                (select private.is_overall_admin_for_service(s.service_id))
                or (select private.can_access_class(coalesce(s.current_class_id, s.proposed_class_id)))
              )
            )
          )
        )
        or (
          not follow_up_records.is_request
          and (
            (select private.is_overall_admin_for_service(s.service_id))
            or (select private.can_access_class(coalesce(s.current_class_id, s.proposed_class_id)))
          )
        )
      )
  ));
