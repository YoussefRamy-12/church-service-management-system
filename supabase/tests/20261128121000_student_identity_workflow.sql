-- Phase 1 SQL regression checks.
-- Run on a disposable Supabase development branch after applying the migration.
-- Assertions below are self-contained and rollback-safe. Workflow/RLS tests that
-- require authenticated fixture identities are described in the final section.
BEGIN;

DO $test$
DECLARE
  v_result record;
  v_keys text[];
  v_fn record;
BEGIN
  IF private.normalize_ar_name('  أَحْمَد   عبدُه  ') <> 'احمد عبده' THEN
    RAISE EXCEPTION 'Arabic name normalization failed';
  END IF;
  IF private.normalize_phone('+20 10 1234 5678') <> '01012345678'
     OR private.normalize_phone('00201012345678') <> '01012345678'
     OR private.normalize_phone('٠١٠١٢٣٤٥٦٧٨') <> '01012345678' THEN
    RAISE EXCEPTION 'Egyptian phone normalization failed';
  END IF;

  SELECT p.prosecdef, p.proconfig INTO v_fn
  FROM pg_catalog.pg_proc p
  WHERE p.oid = 'public.find_student_candidates(uuid,text,date,text)'::regprocedure;
  IF NOT v_fn.prosecdef OR NOT EXISTS (
    SELECT 1 FROM pg_catalog.unnest(v_fn.proconfig) AS u(setting)
    WHERE setting = 'search_path=""'
  ) THEN
    RAISE EXCEPTION 'candidate RPC must be SECURITY DEFINER with empty search_path';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_catalog.pg_proc p,
      LATERAL pg_catalog.unnest(p.proconfig) AS u(cfg)
    WHERE p.oid IN (
      'public.find_student_candidates(uuid,text,date,text)'::regprocedure,
      'public.register_service_student_v2(uuid,text,uuid,text,date,text,text,text,text,boolean,timestamp with time zone,text,uuid,uuid,uuid,text)'::regprocedure,
      'public.resolve_identity_review(uuid,text,uuid)'::regprocedure
    )
      AND cfg <> 'search_path=""'
  ) THEN
    RAISE EXCEPTION 'SECURITY DEFINER RPC missing empty search_path';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_indexes
    WHERE schemaname = 'public'
      AND indexname = 'students_normalized_name_birth_date_uidx'
      AND indexdef LIKE '%UNIQUE%'
  ) THEN
    RAISE EXCEPTION 'universal normalized-name/birth-date unique index missing';
  END IF;

  IF NOT (
    SELECT relrowsecurity FROM pg_catalog.pg_class
    WHERE oid = 'public.student_identity_link_events'::regclass
  ) OR NOT (
    SELECT relrowsecurity FROM pg_catalog.pg_class
    WHERE oid = 'public.student_identity_review_requests'::regclass
  ) THEN
    RAISE EXCEPTION 'RLS must be enabled on both identity tables';
  END IF;

  IF has_table_privilege('authenticated', 'public.student_identity_link_events', 'INSERT')
     OR has_table_privilege('authenticated', 'public.student_identity_review_requests', 'INSERT')
     OR has_table_privilege('authenticated', 'public.student_identity_link_events', 'UPDATE')
     OR has_table_privilege('authenticated', 'public.student_identity_review_requests', 'UPDATE') THEN
    RAISE EXCEPTION 'identity audit/review tables must not allow direct writes';
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_trigger
    WHERE tgname = 'trg_verified_student_membership_link'
      AND tgrelid = 'public.service_students'::regclass
      AND tgenabled = 'D'
  ) THEN
    RAISE EXCEPTION 'verified-link trigger is disabled';
  END IF;
END;
$test$;

-- Candidate RPC response contract: the result type contains no DOB, phone,
-- sensitive data, notes, photo, school, or grade. This checks exposed columns.
DO $contract$
DECLARE
  v_columns text[];
BEGIN
  SELECT p.proargnames[5:10] INTO v_columns
  FROM pg_catalog.pg_proc p
  WHERE p.oid = 'public.find_student_candidates(uuid,text,date,text)'::regprocedure;
  IF v_columns IS DISTINCT FROM ARRAY[
    'student_id', 'display_name', 'age', 'service_names',
    'already_in_service', 'match_score'
  ]::text[] THEN
    RAISE EXCEPTION 'candidate result contract mismatch: %', v_columns;
  END IF;
END;
$contract$;

ROLLBACK;

-- Behavioral integration cases to run with authenticated service fixtures on the
-- disposable branch:
-- 1. as service B, SELECT service_students for service A returns no rows.
-- 2. register_service_student_v2(create_new) with an exact normalized name/DOB
--    candidate raises possible_duplicate; the unique index remains universal,
--    including for super-admins.
-- 3. register_service_student_v2(link_existing) creates exactly one service_students
--    row; same idempotency key replays the original result; a new key for the same
--    student/service is rejected by unique membership or student_already_in_service.
-- 4. Candidate JSON keys equal the six declared return columns and never include
--    student_sensitive_data or other forbidden fields.
-- 5. The legacy register_service_student(uuid,...) signature still executes with
--    the legacy payload shape and retains same-service compatibility.
-- 6. Direct cross-service service_students inserts fail without the verified RPC
--    transaction-local flags.
