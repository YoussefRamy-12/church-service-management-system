-- Phase 2 servant identity regression script.
-- Run on a disposable Supabase development branch after the migration.
-- All fixtures and mutations are rolled back at the end.
BEGIN;

DO $schema_checks$
DECLARE
  v_names text[];
  v_conflict_rls boolean;
  v_person_rls boolean;
BEGIN
  SELECT p.proargnames[3:6] INTO v_names
  FROM pg_catalog.pg_proc p
  WHERE p.oid = 'public.find_servant_candidates(text,text)'::regprocedure;
  IF v_names IS DISTINCT FROM ARRAY[
    'auth_user_id', 'full_name', 'phone_suffix', 'service_names'
  ]::text[] THEN
    RAISE EXCEPTION 'candidate result exposes unexpected columns: %', v_names;
  END IF;

  SELECT relrowsecurity INTO v_person_rls
  FROM pg_catalog.pg_class
  WHERE oid = 'public.servant_persons'::regclass;
  SELECT relrowsecurity INTO v_conflict_rls
  FROM pg_catalog.pg_class
  WHERE oid = 'public.servant_person_backfill_conflicts'::regclass;
  IF NOT v_person_rls OR NOT v_conflict_rls THEN
    RAISE EXCEPTION 'RLS must be enabled on both new tables';
  END IF;

  IF has_table_privilege('authenticated', 'public.servant_persons', 'INSERT')
     OR has_table_privilege('authenticated', 'public.servant_person_backfill_conflicts', 'INSERT')
     OR has_table_privilege('authenticated', 'public.servant_person_backfill_conflicts', 'UPDATE') THEN
    RAISE EXCEPTION 'direct insert/update access to canonical/conflict tables is too broad';
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_constraint
    WHERE conrelid = 'public.servant_profiles'::regclass
      AND conname = 'servant_profiles_service_phone_unique'
  ) THEN
    RAISE EXCEPTION 'phone match must be report-only, not a uniqueness blocker';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_indexes
    WHERE schemaname = 'public'
      AND indexname = 'servant_profiles_auth_user_service_unique'
      AND indexdef LIKE '%UNIQUE%'
  ) THEN
    RAISE EXCEPTION 'one assignment per auth user and service must remain enforced';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_catalog.pg_proc p
    CROSS JOIN LATERAL pg_catalog.unnest(COALESCE(p.proconfig, ARRAY[]::text[])) AS c(setting)
    WHERE p.oid IN (
      'public.find_servant_candidates(text,text)'::regprocedure,
      'public.assign_servant_to_service(uuid,uuid,text,uuid,uuid)'::regprocedure
    )
      AND p.prosecdef
      AND c.setting <> 'search_path=""'
  ) OR EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
    WHERE p.oid IN (
      'public.find_servant_candidates(text,text)'::regprocedure,
      'public.assign_servant_to_service(uuid,uuid,text,uuid,uuid)'::regprocedure
    )
      AND (NOT p.prosecdef OR NOT EXISTS (
        SELECT 1 FROM pg_catalog.unnest(COALESCE(p.proconfig, ARRAY[]::text[])) AS c(setting)
        WHERE c.setting = 'search_path=""'
      ))
  ) THEN
    RAISE EXCEPTION 'RPCs must be SECURITY DEFINER with empty search_path';
  END IF;

  IF has_function_privilege('anon', 'public.find_servant_candidates(text,text)', 'EXECUTE')
     OR has_function_privilege('anon', 'public.assign_servant_to_service(uuid,uuid,text,uuid,uuid)', 'EXECUTE')
     OR EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
       CROSS JOIN LATERAL pg_catalog.aclexplode(COALESCE(p.proacl, pg_catalog.acldefault('f', p.proowner))) AS acl
       WHERE p.oid IN (
         'public.find_servant_candidates(text,text)'::regprocedure,
         'public.assign_servant_to_service(uuid,uuid,text,uuid,uuid)'::regprocedure
       ) AND acl.grantee = 0 AND acl.privilege_type = 'EXECUTE'
     ) THEN
    RAISE EXCEPTION 'RPC execution must be revoked from PUBLIC and anon';
  END IF;
END;
$schema_checks$;

-- Fixtures: an existing servant in service A, an overall admin in service B,
-- and another auth account with the same phone. Same-phone accounts must remain
-- reportable but must not be rejected by a phone uniqueness constraint.
CREATE TEMP TABLE phase2_ids AS
SELECT
  gen_random_uuid() AS service_a,
  gen_random_uuid() AS service_b,
  gen_random_uuid() AS actor_b,
  gen_random_uuid() AS servant,
  gen_random_uuid() AS duplicate_phone_user;

INSERT INTO public.services (id, name, church_name, meeting_start_time)
SELECT service_a, 'Phase2 Test A', 'Test', '15:00'::time FROM phase2_ids
UNION ALL
SELECT service_b, 'Phase2 Test B', 'Test', '18:00'::time FROM phase2_ids;

INSERT INTO auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
SELECT actor_b, 'authenticated', 'authenticated',
       actor_b::text || '@phase2.invalid', '', now(), '{}'::jsonb, '{}'::jsonb, now(), now()
FROM phase2_ids
UNION ALL
SELECT servant, 'authenticated', 'authenticated',
       servant::text || '@phase2.invalid', '', now(), '{}'::jsonb, '{}'::jsonb, now(), now()
FROM phase2_ids
UNION ALL
SELECT duplicate_phone_user, 'authenticated', 'authenticated',
       duplicate_phone_user::text || '@phase2.invalid', '', now(), '{}'::jsonb, '{}'::jsonb, now(), now()
FROM phase2_ids;

INSERT INTO public.servant_profiles (
  auth_user_id, service_id, name, phone, birth_date, work_study,
  role, account_status
)
SELECT actor_b, service_b, 'مسؤول الاختبار', '01222222222', '1985-01-01',
       'عمل', 'overall_leader'::public.servant_role,
       'active'::public.servant_account_status
FROM phase2_ids
UNION ALL
SELECT servant, service_a, 'خادم الاختبار', '01012345678', '1990-02-03',
       'دراسة', 'overall_helper'::public.servant_role,
       'active'::public.servant_account_status
FROM phase2_ids
UNION ALL
SELECT duplicate_phone_user, service_b, 'حساب الهاتف المكرر', '01012345678',
       '1992-03-04', 'عمل', 'overall_helper'::public.servant_role,
       'active'::public.servant_account_status
FROM phase2_ids;

SELECT set_config('app.phase2_actor_b', (SELECT actor_b::text FROM phase2_ids), true);
SELECT set_config('app.phase2_servant', (SELECT servant::text FROM phase2_ids), true);
SELECT set_config('app.phase2_service_a', (SELECT service_a::text FROM phase2_ids), true);
SELECT set_config('app.phase2_service_b', (SELECT service_b::text FROM phase2_ids), true);

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', current_setting('app.phase2_actor_b'), true);
SELECT set_config('request.jwt.claims',
  jsonb_build_object('sub', current_setting('app.phase2_actor_b'),
                     'role', 'authenticated')::text, true);

DO $cross_service_search$
DECLARE
  v_servant uuid := current_setting('app.phase2_servant')::uuid;
  v_service_b uuid := current_setting('app.phase2_service_b')::uuid;
  v_found uuid;
  v_profile_rows integer;
  v_person_rows integer;
  v_assigned uuid;
BEGIN
  IF (SELECT count(*) FROM public.servant_profiles WHERE auth_user_id = v_servant) <> 0
     OR (SELECT count(*) FROM public.servant_persons WHERE auth_user_id = v_servant) <> 0 THEN
    RAISE EXCEPTION 'service B read another service profile before assignment';
  END IF;

  SELECT c.auth_user_id INTO v_found
  FROM public.find_servant_candidates('خادم الاختبار', '') AS c;
  IF v_found IS DISTINCT FROM v_servant THEN
    RAISE EXCEPTION 'overall admin could not find the cross-service candidate';
  END IF;

  v_assigned := public.assign_servant_to_service(
    v_servant, v_service_b, 'overall_helper', NULL, NULL
  );
  PERFORM public.assign_servant_to_service(
    v_servant, v_service_b, 'overall_helper', NULL, NULL
  );

  SELECT count(*) INTO v_profile_rows
  FROM public.servant_profiles
  WHERE auth_user_id = v_servant AND service_id = v_service_b;
  SELECT count(*) INTO v_person_rows
  FROM public.servant_persons WHERE auth_user_id = v_servant;
  IF v_profile_rows <> 1 OR v_person_rows <> 1 OR v_assigned IS NULL THEN
    RAISE EXCEPTION 'assignment created duplicate profile/person rows';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.servant_persons
    WHERE auth_user_id = v_servant AND full_name = 'خادم الاختبار'
  ) THEN
    RAISE EXCEPTION 'service B cannot read the person after assignment';
  END IF;
END;
$cross_service_search$;

-- Editing a person from their own account updates every legacy assignment row.
SELECT set_config('request.jwt.claim.sub', current_setting('app.phase2_servant'), true);
SELECT set_config('request.jwt.claims',
  jsonb_build_object('sub', current_setting('app.phase2_servant'),
                     'role', 'authenticated')::text, true);
UPDATE public.servant_persons
SET full_name = 'خادم موحد', phone = '01123456789'
WHERE auth_user_id = current_setting('app.phase2_servant')::uuid;

DO $dual_write$
DECLARE
  v_count integer;
BEGIN
  SELECT count(*) INTO v_count
  FROM public.servant_profiles
  WHERE auth_user_id = current_setting('app.phase2_servant')::uuid
    AND name = 'خادم موحد' AND phone = '01123456789';
  IF v_count <> 2 THEN
    RAISE EXCEPTION 'person edit did not dual-write all service profiles: %', v_count;
  END IF;
END;
$dual_write$;

RESET ROLE;

UPDATE public.servant_profiles
SET name = 'Legacy replay name'
WHERE auth_user_id = current_setting('app.phase2_servant')::uuid;

DO $legacy_profile_write$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.servant_persons
    WHERE auth_user_id = current_setting('app.phase2_servant')::uuid
      AND full_name = 'Legacy replay name'
  ) THEN
    RAISE EXCEPTION 'legacy servant_profiles update did not dual-write the person';
  END IF;
END;
$legacy_profile_write$;

DO $phone_report_only$
DECLARE v_count integer;
BEGIN
  SELECT count(DISTINCT auth_user_id) INTO v_count
  FROM public.servant_persons
  WHERE private.normalize_servant_phone(phone) = '01012345678';
  IF v_count <> 2 THEN
    RAISE EXCEPTION 'same-phone auth users should be retained and reportable';
  END IF;
END;
$phone_report_only$;

DO $single_person_two_services$
DECLARE
  v_person_count integer;
  v_profile_count integer;
BEGIN
  SELECT count(*) INTO v_person_count
  FROM public.servant_persons
  WHERE auth_user_id = current_setting('app.phase2_servant')::uuid;
  SELECT count(DISTINCT service_id) INTO v_profile_count
  FROM public.servant_profiles
  WHERE auth_user_id = current_setting('app.phase2_servant')::uuid;
  IF v_person_count <> 1 OR v_profile_count <> 2 THEN
    RAISE EXCEPTION 'expected 1 servant_persons row and 2 services, got % and %',
      v_person_count, v_profile_count;
  END IF;
END;
$single_person_two_services$;

-- Overall admin of service B cannot assign into service A,
-- and cannot reactivate a suspended servant in service B.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', current_setting('app.phase2_admin_b'), true);
SELECT set_config('request.jwt.claims',
  jsonb_build_object('sub', current_setting('app.phase2_admin_b'),
                     'role', 'authenticated')::text, true);

DO $cross_service_assign_blocked$
BEGIN
  BEGIN
    PERFORM public.assign_servant_to_service(
      current_setting('app.phase2_servant')::uuid,
      current_setting('app.phase2_service_a')::uuid,
      'overall_helper',
      NULL,
      NULL
    );
    RAISE EXCEPTION 'expected overall_admin_required_for_service';
  EXCEPTION
    WHEN SQLSTATE '42501' THEN
      IF SQLERRM NOT LIKE '%overall_admin_required_for_service%' THEN
        RAISE;
      END IF;
  END;
END;
$cross_service_assign_blocked$;

RESET ROLE;

UPDATE public.servant_profiles
SET account_status = 'suspended'::public.servant_account_status
WHERE auth_user_id = current_setting('app.phase2_servant')::uuid
  AND service_id = current_setting('app.phase2_service_b')::uuid;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', current_setting('app.phase2_admin_b'), true);
SELECT set_config('request.jwt.claims',
  jsonb_build_object('sub', current_setting('app.phase2_admin_b'),
                     'role', 'authenticated')::text, true);

DO $suspended_reactivation_blocked$
BEGIN
  BEGIN
    PERFORM public.assign_servant_to_service(
      current_setting('app.phase2_servant')::uuid,
      current_setting('app.phase2_service_b')::uuid,
      'overall_helper',
      NULL,
      NULL
    );
    RAISE EXCEPTION 'expected reactivation_requires_super_admin';
  EXCEPTION
    WHEN SQLSTATE '42501' THEN
      IF SQLERRM NOT LIKE '%reactivation_requires_super_admin%' THEN
        RAISE;
      END IF;
  END;
END;
$suspended_reactivation_blocked$;

RESET ROLE;

ROLLBACK;
