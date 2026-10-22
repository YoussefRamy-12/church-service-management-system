alter table public.services
  add column if not exists early_attendance_minutes integer not null default 15
  check (early_attendance_minutes between 0 and 60);
