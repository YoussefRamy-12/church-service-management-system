-- Index the new composite and service membership foreign keys.
CREATE INDEX IF NOT EXISTS idx_classes_stage_service_fk
  ON public.classes(stage_id, service_id);
CREATE INDEX IF NOT EXISTS idx_service_students_class_service_fk
  ON public.service_students(class_id, service_id);
CREATE INDEX IF NOT EXISTS idx_service_students_proposed_class_service_fk
  ON public.service_students(proposed_class_id, service_id);
CREATE INDEX IF NOT EXISTS idx_attendance_service_fk
  ON public.attendance_records(service_id);
CREATE INDEX IF NOT EXISTS idx_attendance_membership_service_fk
  ON public.attendance_records(service_student_id, service_id);
CREATE INDEX IF NOT EXISTS idx_attendance_class_snapshot_fk
  ON public.attendance_records(class_id_at_attendance);
CREATE INDEX IF NOT EXISTS idx_follow_up_records_service_fk
  ON public.follow_up_records(service_id);
CREATE INDEX IF NOT EXISTS idx_follow_up_records_membership_service_fk
  ON public.follow_up_records(service_student_id, service_id);
CREATE INDEX IF NOT EXISTS idx_follow_up_cases_class_service_fk
  ON public.follow_up_cases(class_id, service_id);
CREATE INDEX IF NOT EXISTS idx_follow_up_cases_membership_service_fk
  ON public.follow_up_cases(service_student_id, service_id);
CREATE INDEX IF NOT EXISTS idx_notebook_membership_service_fk
  ON public.spiritual_notebook_submissions(service_student_id, service_id);

DROP TRIGGER IF EXISTS service_students_updated_at ON public.service_students;
CREATE TRIGGER service_students_updated_at
BEFORE UPDATE ON public.service_students
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
