-- Carry all servant_profiles NOT NULL profile fields through self-registration.
alter table public.servant_registration_requests
  add column if not exists birth_date date,
  add column if not exists work_study text;

create or replace function private.try_parse_date(value text)
returns date
language plpgsql
immutable
set search_path = ''
as $$
begin
  return nullif(value, '')::date;
exception when others then
  return null;
end;
$$;
revoke all on function private.try_parse_date(text)
  from public, anon, authenticated;

-- Preserve profile details for signup requests created before this migration.
insert into public.servant_registration_requests as requests (
  auth_user_id, full_name, email, phone, birth_date, work_study
)
select
  users.id,
  coalesce(nullif(trim(users.raw_user_meta_data ->> 'full_name'), ''), 'خادم جديد'),
  users.email,
  users.raw_user_meta_data ->> 'phone',
  private.try_parse_date(users.raw_user_meta_data ->> 'birth_date'),
  nullif(trim(users.raw_user_meta_data ->> 'work_study'), '')
from auth.users as users
where users.raw_user_meta_data ->> 'signup_type' = 'servant'
on conflict (auth_user_id) do update
set birth_date = coalesce(
      requests.birth_date,
      excluded.birth_date
    ),
    work_study = coalesce(
      requests.work_study,
      excluded.work_study
    );

create or replace function private.create_servant_registration_request()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.raw_user_meta_data ->> 'signup_type' = 'servant' then
    insert into public.servant_registration_requests (
      auth_user_id, full_name, email, phone, birth_date, work_study
    ) values (
      new.id,
      coalesce(nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''), 'خادم جديد'),
      new.email,
      new.raw_user_meta_data ->> 'phone',
      private.try_parse_date(new.raw_user_meta_data ->> 'birth_date'),
      nullif(trim(new.raw_user_meta_data ->> 'work_study'), '')
    )
    on conflict (auth_user_id) do update
      set full_name = excluded.full_name,
          email = excluded.email,
          phone = excluded.phone,
          birth_date = excluded.birth_date,
          work_study = excluded.work_study;
  end if;
  return new;
end;
$$;

revoke all on function private.create_servant_registration_request()
  from public, anon, authenticated;

-- Keep profile reads restricted to the owning servant and administrators.
grant select on public.servant_profiles to authenticated;
