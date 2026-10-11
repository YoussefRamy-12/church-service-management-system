-- Give active system administrators full row-level access to every existing
-- table in public. RLS still verifies the caller on every request, so this
-- does not grant the same access to ordinary authenticated users.
do $$
declare
  target record;
begin
  for target in
    select schemaname, tablename
    from pg_tables
    where schemaname = 'public'
  loop
    execute format(
      'alter table %I.%I enable row level security',
      target.schemaname,
      target.tablename
    );

    execute format(
      'drop policy if exists %I on %I.%I',
      'active system administrators have full access',
      target.schemaname,
      target.tablename
    );

    execute format(
      'create policy %I on %I.%I for all to authenticated using ((select public.is_active_system_admin())) with check ((select public.is_active_system_admin()))',
      'active system administrators have full access',
      target.schemaname,
      target.tablename
    );
  end loop;
end;
$$;

-- RLS limits these table grants to the active system administrators above.
grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;

-- Keep table access available for tables created later by the same schema owner.
alter default privileges in schema public
  grant select, insert, update, delete on tables to authenticated;
alter default privileges in schema public
  grant usage, select on sequences to authenticated;
