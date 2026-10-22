-- Servants need to read their own service assignments after authentication.
-- Admin management remains covered by the existing administrator policy.
grant select on public.servant_profiles to authenticated;

drop policy if exists "servants can read own profiles"
  on public.servant_profiles;
create policy "servants can read own profiles"
  on public.servant_profiles
  for select
  to authenticated
  using ((select auth.uid()) = auth_user_id);
