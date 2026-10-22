-- Migration: Ensure all student_sensitive_data columns exist and reload PostgREST schema cache
-- Timestamp: 2026-10-22 23:30:00

alter table public.student_sensitive_data
  add column if not exists medical_notes text,
  add column if not exists confessor text,
  add column if not exists confidential_notes text,
  add column if not exists study_year text,
  add column if not exists guardian_name text,
  add column if not exists guardian_phone text,
  add column if not exists emergency_phone text,
  add column if not exists address text,
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

-- Notify PostgREST to reload schema cache immediately
notify pgrst, 'reload schema';
