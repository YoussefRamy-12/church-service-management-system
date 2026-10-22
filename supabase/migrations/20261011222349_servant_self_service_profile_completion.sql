-- Let a servant fill only their own pending registration profile fields.
-- The function cannot change name, phone, account status, review state, or role.
create or replace function public.complete_servant_registration_profile(
  p_birth_date date,
  p_work_study text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then
    raise exception 'Authentication is required.' using errcode = '28000';
  end if;

  if p_birth_date is null or nullif(trim(p_work_study), '') is null then
    raise exception 'Birth date and work/study are required.' using errcode = '22023';
  end if;

  update public.servant_registration_requests as requests
  set birth_date = p_birth_date,
      work_study = trim(p_work_study)
  where requests.auth_user_id = (select auth.uid())
    and requests.status = 'pending';

  if not found then
    raise exception 'No pending servant registration belongs to this account.'
      using errcode = '42501';
  end if;
end;
$$;

revoke all on function public.complete_servant_registration_profile(date, text)
  from public, anon, authenticated;
grant execute on function public.complete_servant_registration_profile(date, text)
  to authenticated;
