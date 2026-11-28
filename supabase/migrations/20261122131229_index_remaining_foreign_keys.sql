-- Add covering indexes for the remaining foreign keys reported by Supabase.
CREATE INDEX IF NOT EXISTS idx_follow_up_activities_created_by_fk ON public.follow_up_activities(created_by);
CREATE INDEX IF NOT EXISTS idx_follow_up_case_assignments_assigned_by_fk ON public.follow_up_case_assignments(assigned_by);
CREATE INDEX IF NOT EXISTS idx_follow_up_records_created_by_fk ON public.follow_up_records(created_by);
CREATE INDEX IF NOT EXISTS idx_meeting_schedules_created_by_fk ON public.meeting_schedules(created_by);
CREATE INDEX IF NOT EXISTS idx_servant_attendance_recorded_by_fk ON public.servant_attendance_records(recorded_by);
CREATE INDEX IF NOT EXISTS idx_servant_registration_reviewed_by_fk ON public.servant_registration_requests(reviewed_by);
CREATE INDEX IF NOT EXISTS idx_spiritual_activities_service_category_fk ON public.spiritual_notebook_activities(service_id,category_id);
CREATE INDEX IF NOT EXISTS idx_spiritual_submission_items_activity_fk ON public.spiritual_notebook_submission_items(activity_id);
CREATE INDEX IF NOT EXISTS idx_spiritual_submissions_submitted_by_fk ON public.spiritual_notebook_submissions(submitted_by);
CREATE INDEX IF NOT EXISTS idx_weekly_prep_reviews_reviewer_fk ON public.weekly_lesson_preparation_reviews(reviewer_id);
CREATE INDEX IF NOT EXISTS idx_weekly_preparations_reviewed_by_fk ON public.weekly_lesson_preparations(reviewed_by);
CREATE INDEX IF NOT EXISTS idx_weekly_preparations_servant_profile_fk ON public.weekly_lesson_preparations(servant_profile_id);
CREATE INDEX IF NOT EXISTS idx_weekly_lessons_uploaded_by_fk ON public.weekly_lessons(uploaded_by);
