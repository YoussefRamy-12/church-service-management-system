# Graphify Architecture Notes (feat/shared-identity-multi-service)

## 1. Files Touching `students`, `service_students`, `servant_profiles` / `servant_registration_requests`

- **Database & Sync**:
  - `lib/core/database/app_database.dart`, `lib/core/database/app_database.g.dart`
  - `lib/core/sync/handlers/student_sync_handler.dart`, `service_student_sync_handler.dart`, `servant_sync_handler.dart`
- **Students Feature (`lib/features/students/`)**:
  - Domain: `entities/student.dart`, `entities/service_student.dart`, `entities/sensitive_student_data.dart`, `repositories/student_repository.dart`, `repositories/student_registration.dart`, `student_permissions.dart`
  - Data: `local_student_repository.dart`, `local_service_student_repository.dart`, `offline_first_student_repository.dart`, `offline_first_service_student_repository.dart`, `offline_first_student_registration.dart`, `online_student_repository.dart`, `online_student_registration.dart`, `supabase_student_repository.dart`
  - Presentation & Services: `add_student_page.dart`, `class_students_page.dart`, `import_students_excel_page.dart`, `student_details_page.dart`, `student_providers.dart`, `students_page.dart`, `widgets/student_attendance_tab.dart`, `widgets/student_edit_dialog.dart`, `widgets/student_follow_up_tab.dart`, `services/excel_student_import_service.dart`, `services/student_qr_pdf_service.dart`
- **Auth & Servants**:
  - `lib/features/auth/data/servant_profile_repository.dart`, `domain/entities/servant_profile.dart`, `presentation/servant_registration_requests_page.dart`
  - `lib/features/servants/presentation/servant_management_dialogs.dart`
- **Cross-Feature Consumers**:
  - Attendance (`lib/features/attendance/`): `data/*_attendance_repository.dart`, `attendance_profile_resolver.dart`, `domain/entities/attendance_record.dart`, `domain/repositories/attendance_repository.dart`, `presentation/attendance_session_page.dart`, `qr_scan_page.dart`, `widgets/attendance_review_sheet.dart`, `widgets/attendance_student_tile.dart`, `widgets/register_student_dialog.dart`
  - Follow-Up (`lib/features/follow_up/`): `data/*_follow_up*_repository.dart`, `domain/entities/follow_up_*.dart`, `domain/repositories/follow_up*_repository.dart`, `presentation/*_page.dart`, `follow_up_case_providers.dart`, `widgets/follow_up_student_card.dart`
  - Reports & Export: `lib/features/reports/` (`domain/analytics_models.dart`, `report_filter.dart`, `service_report.dart`, `report_providers.dart`, `reports_page.dart`, `pages/student_analytics_detail_page.dart`, `widgets/repeated_absences_table.dart`, `widgets/student_analytics_view.dart`), `lib/features/export/` (`csv_export_repository.dart`, `export_page.dart`)
  - Spiritual Notebook & Service: `lib/features/spiritual_notebook/` (`data/spiritual_notebook_repository.dart`, `presentation/pages/student_notebook*.dart`, `presentation/widgets/student_list*.dart`), `lib/features/service/presentation/service_dashboard_page.dart`
- **Tests (`test/`)**:
  - `add_student_page_test.dart`, `attendance_redesign_widget_test.dart`, `drift_student_migration_test.dart`, `excel_student_import_test.dart`, `follow_up/quick_follow_up_sheet_widget_test.dart`, `multi_service_sync_replay_test.dart`, `offline_student_integration_test.dart`, `offline_student_registration_test.dart`, `servant_profile_permissions_test.dart`, `service_dashboard_role_test.dart`, `service_student_offline_integration_test.dart`, `student_details_actions_test.dart`, `student_mutation_test.dart`, `student_qr_pdf_test.dart`, `student_repository_integration_test.dart`, `students_list_filtering_test.dart`, `system_offline_workflow_test.dart`, `task12_spiritual_notebook*_test.dart`, `goldens/*_golden_test.dart`, `task6/7/8_*_golden_test.dart`

## 2. Sync Handlers & Drift Tables

- **Sync Handlers** (`lib/core/sync/handlers/`):
  - `StudentSyncHandler` (`student_sync_handler.dart`)
  - `ServiceStudentSyncHandler` (`service_student_sync_handler.dart`)
  - `ServantSyncHandler` (`servant_sync_handler.dart`)
- **Drift Database**: `lib/core/database/app_database.dart` (generated `app_database.g.dart`)

## 3. Supabase Migrations (RPCs & `students` RLS)

- `20261013101403_scope_rls_to_service_assignment.sql`: `students_insert` (L228), `students_select` (L242), `students_update` (L256)
- `20261022230000_allow_class_servant_import_current_class.sql`: `students_insert` (L8)
- `20261023120000_allow_student_hard_delete.sql`: `students_delete` (L49)
- `20261122140938_students_membership_workflows.sql`: `register_service_student` (L4), `update_service_student` (L86)
- `20261122141313_students_update_nullable_date_guard.sql`: `update_service_student` (L2)
- `20261128120000_student_identity_matching_and_linking.sql`: `update_service_student` (L309), `register_service_student_v2` (L404)
