-- Self-registration is kept separate from service access. A registration only
-- becomes usable after a system administrator creates a servant profile.
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table if not exists public.servant_registration_requests (
  auth_user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  email text,
  phone text,
  status text not null default 'pending'
    check (status in ('pending', 'enrolled', 'rejected')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references auth.users(id) on delete set null
);

-- Accounts created before this migration did not run the signup trigger.
insert into public.servant_registration_requests (
  auth_user_id, full_name, email, phone
)
select
  users.id,
  coalesce(nullif(trim(users.raw_user_meta_data ->> 'full_name'), ''), 'خادم جديد'),
  users.email,
  users.raw_user_meta_data ->> 'phone'
from auth.users as users
where users.raw_user_meta_data ->> 'signup_type' = 'servant'
on conflict (auth_user_id) do nothing;

alter table public.servant_registration_requests enable row level security;
grant select on public.servant_registration_requests to authenticated;

drop policy if exists "servants can read own registration request"
  on public.servant_registration_requests;
create policy "servants can read own registration request"
  on public.servant_registration_requests
  for select to authenticated
  using ((select auth.uid()) = auth_user_id);

drop policy if exists "active system administrators manage servant registrations"
  on public.servant_registration_requests;
create policy "active system administrators manage servant registrations"
  on public.servant_registration_requests
  for all to authenticated
  using ((select public.is_active_system_admin()))
  with check ((select public.is_active_system_admin()));

grant insert, update, delete on public.servant_registration_requests to authenticated;

create or replace function private.create_servant_registration_request()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.raw_user_meta_data ->> 'signup_type' = 'servant' then
    insert into public.servant_registration_requests (
      auth_user_id, full_name, email, phone
    ) values (
      new.id,
      coalesce(nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''), 'خادم جديد'),
      new.email,
      new.raw_user_meta_data ->> 'phone'
    )
    on conflict (auth_user_id) do update
      set full_name = excluded.full_name,
          email = excluded.email,
          phone = excluded.phone;
  end if;
  return new;
end;
$$;

revoke all on function private.create_servant_registration_request() from public, anon, authenticated;
drop trigger if exists on_auth_user_servant_registration on auth.users;
create trigger on_auth_user_servant_registration
  after insert on auth.users
  for each row execute function private.create_servant_registration_request();

-- A servant can have a separate role and stage/class assignment in each service.
do $$
declare
  unique_constraint record;
  unique_index record;
begin
  for unique_constraint in
    select conname
    from pg_constraint
    where conrelid = 'public.servant_profiles'::regclass
      and contype = 'u'
      and pg_get_constraintdef(oid) = 'UNIQUE (auth_user_id)'
  loop
    execute format('alter table public.servant_profiles drop constraint %I', unique_constraint.conname);
  end loop;

  for unique_index in
    select index_class.relname as index_name
    from pg_index as indexes
    join pg_class as table_class on table_class.oid = indexes.indrelid
    join pg_namespace as table_schema on table_schema.oid = table_class.relnamespace
    join pg_class as index_class on index_class.oid = indexes.indexrelid
    join pg_attribute as indexed_column
      on indexed_column.attrelid = indexes.indrelid
     and indexed_column.attnum = indexes.indkey[0]
    where table_schema.nspname = 'public'
      and table_class.relname = 'servant_profiles'
      and indexes.indisunique
      and not indexes.indisprimary
      and indexes.indnkeyatts = 1
      and indexed_column.attname = 'auth_user_id'
  loop
    execute format('drop index public.%I', unique_index.index_name);
  end loop;
end;
$$;

create unique index if not exists servant_profiles_auth_user_service_unique
  on public.servant_profiles (auth_user_id, service_id);

grant select, insert, update, delete on public.servant_profiles to authenticated;

drop policy if exists "active system administrators manage servant profiles"
  on public.servant_profiles;
create policy "active system administrators manage servant profiles"
  on public.servant_profiles
  for all to authenticated
  using ((select public.is_active_system_admin()))
  with check ((select public.is_active_system_admin()));
