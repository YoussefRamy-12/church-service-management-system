-- A global student identity must not cascade-delete service memberships.
-- Membership archival is the supported lifecycle operation.
ALTER TABLE public.service_students
  DROP CONSTRAINT IF EXISTS service_students_student_id_fkey;

ALTER TABLE public.service_students
  ADD CONSTRAINT service_students_student_id_fkey
  FOREIGN KEY (student_id)
  REFERENCES public.students(id)
  ON DELETE RESTRICT;
