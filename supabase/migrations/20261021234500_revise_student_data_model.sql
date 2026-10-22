-- Migration: Revise Student Data Model
-- Timestamp: 2026-10-21 23:45:00
-- Purpose: Implement confirmed student data model revision, address components,
--          family structure, deacon status, and financial status classification.

-- 1. Update public.students with ordinary fields
alter table public.students
  add column if not exists is_deacon boolean not null default false;

-- 2. Ensure public.student_sensitive_data exists
create table if not exists public.student_sensitive_data (
  student_id text primary key references public.students(id) on delete cascade,
  guardian_name text,
  guardian_phone text,
  emergency_phone text,
  address text,
  medical_notes text,
  confessor text,
  confidential_notes text,
  study_year text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 3. Add confirmed fields to public.student_sensitive_data
alter table public.student_sensitive_data
  add column if not exists father_job text,
  add column if not exists father_phone text,
  add column if not exists mother_name text,
  add column if not exists mother_job text,
  add column if not exists mother_phone text,
  add column if not exists family_size integer,
  add column if not exists birth_order integer,
  add column if not exists financial_status text,
  add column if not exists address_building text,
  add column if not exists address_street text,
  add column if not exists address_floor text,
  add column if not exists address_apartment text;

-- 4. Add validation constraints
alter table public.student_sensitive_data drop constraint if exists check_family_size_positive;
alter table public.student_sensitive_data add constraint check_family_size_positive
  check (family_size is null or family_size > 0);

alter table public.student_sensitive_data drop constraint if exists check_birth_order_positive;
alter table public.student_sensitive_data add constraint check_birth_order_positive
  check (birth_order is null or birth_order > 0);

alter table public.student_sensitive_data drop constraint if exists check_birth_order_le_family_size;
alter table public.student_sensitive_data add constraint check_birth_order_le_family_size
  check (family_size is null or birth_order is null or birth_order <= family_size);

alter table public.student_sensitive_data drop constraint if exists check_valid_financial_status;
alter table public.student_sensitive_data add constraint check_valid_financial_status
  check (financial_status is null or financial_status in ('طبيعي', 'إخوة رب', 'أسرة مستترة'));

-- 5. Safe backfill for legacy columns (only if they exist in the table)
do $$
begin
  -- Only run backfill if legacy columns actually exist in the production table.
  -- The CREATE TABLE IF NOT EXISTS above is a no-op when the table already exists,
  -- so guardian_phone / emergency_phone may not be present.
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'student_sensitive_data'
      and column_name = 'guardian_phone'
  ) then
    execute $$
      update public.student_sensitive_data
      set father_phone = coalesce(father_phone, guardian_phone)
      where father_phone is null and guardian_phone is not null
    $$;
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'student_sensitive_data'
      and column_name = 'emergency_phone'
  ) then
    execute $$
      update public.student_sensitive_data
      set mother_phone = coalesce(mother_phone, emergency_phone)
      where mother_phone is null and emergency_phone is not null
    $$;
  end if;
end
$$;
