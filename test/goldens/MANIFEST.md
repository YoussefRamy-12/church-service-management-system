# Golden Test Manifest

Branch: `ux/mobile-redesign`  
Inventory source: `lib/app/app.dart` and the `lib/**/presentation/**/*page.dart` files at the branch head inspected for this manifest.

> Status note: this is an inventory and coverage audit, not a claim that the requested matrix is complete. Existing committed goldens are listed as baseline coverage; missing matrix variants and newly requested screens remain explicitly marked pending until executable Flutter golden tests and generated PNGs are committed.

## GoRouter page inventory

There are **30 distinct page-widget destinations** in the current GoRouter configuration (route aliases that build the same widget are counted once).

| # | Route | Page/widget | Current golden status |
|---:|---|---|---|
| 1 | `/admin` | `SystemAdminHomePage` | Not covered |
| 2 | `/admin/servant-registrations` | `ServantRegistrationRequestsPage` | Not covered |
| 3 | `/login` | `LoginPage` | Baseline mobile/desktop, light/dark |
| 4 | `/forgot-password` | `ForgotPasswordPage` | Not covered |
| 5 | `/reset-password` | `ResetPasswordPage` | Not covered |
| 6 | `/auth/callback` | `AuthCallbackPage` | Not covered |
| 7 | `/signup` | `ServantSignUpPage` | Not covered |
| 8 | `/session` | `SessionGate` | Not covered |
| 9 | `/sync/conflicts` | `SyncConflictPage` | Not covered |
| 10 | `/sync` | `SyncCenterPage` | Baseline mobile/desktop, light/dark |
| 11 | `/service/:serviceId/dashboard` | `ServiceDashboardPage` | Baseline mobile/desktop, light/dark; current fixture data needs verification |
| 12 | `/service/:serviceId/stage/:stageId` | `StageDashboardPage` | Not covered |
| 13 | `/service/:serviceId/stage/:stageId/class/:classId` | `ClassDashboardPage` | Not covered |
| 14 | `/service/:serviceId/students` | `StudentsPage` | Baseline mobile/desktop, light/dark |
| 15 | `/service/:serviceId/attendance` | `MeetingListPage` | Not covered |
| 16 | `/service/:serviceId/settings/meetings` | `MeetingSchedulesPage` | Not covered |
| 17 | `/service/:serviceId/attendance/class-picker/:meetingId` | `AttendanceClassPickerPage` | Not covered |
| 18 | `/service/:serviceId/follow-up` | `FollowUpHubPage` | Baseline mobile/desktop, light/dark |
| 19 | `/service/:serviceId/reports` | `ReportsPage` | Baseline mobile/desktop, light/dark; filter-open images need verification |
| 20 | `/service/:serviceId/prep` | `WeeklyPrepPage` | Baseline servant-prep mobile only |
| 21 | `/service/:serviceId/spiritual-notebook` | `SpiritualNotebookPage` | Baseline notebook states in task12/task7 |
| 22 | `/service/:serviceId/spiritual-notebook/student/:membershipId` | `SpiritualNotebookStudentPage` | Baseline task12 student notebook states |
| 23 | `/service/:serviceId/servants` | `ServantManagementPage` | Baseline mobile/desktop, light/dark |
| 24 | `/service/:serviceId/export` | `ExportPage` (standard export) | Not covered |
| 25 | `/service/:serviceId/graduation` | `ExportPage` (graduation mode) | Not covered |
| 26 | `/service/:serviceId/my-settings` | `GlobalSettingsPage` | Not covered |
| 27 | `/service/:serviceId/settings` | `ServiceSettingsPage` | Not covered |
| 28 | `/service/:serviceId/settings/structure` | `StructureSettingsPage` | Not covered |
| 29 | `/service/:serviceId/settings/system` | `SystemSettingsPage` | Not covered |
| 30 | `/service/:serviceId/attendance/session/:meetingId/:classId` and `/attendance/:meetingId/:classId` | `AttendanceSessionPage` (same widget) | Baseline mobile/desktop, light/dark, scale 1.3 |

The router also has the non-page redirect `/app → /session` and the service-root redirect `/service/:serviceId → /service/:serviceId/dashboard`. They are navigation behavior, not additional screens.

## Additional page widgets / flows outside direct GoRouter destinations

These are separate renderable page surfaces discovered under feature presentation code. Some are pushed from parent pages or are reached through in-page actions rather than declared as top-level GoRouter destinations.

| Screen/widget | File | Current golden status |
|---|---|---|
| Attendance entry page | `lib/features/attendance/presentation/attendance_page.dart` | Not covered |
| QR scanner | `lib/features/attendance/presentation/qr_scan_page.dart` | Baseline mobile/desktop states; icon/camera placeholder requires verification |
| Add student | `lib/features/students/presentation/add_student_page.dart` | Validation-only baseline; normal state missing |
| Class students | `lib/features/students/presentation/class_students_page.dart` | Not covered |
| Import students Excel | `lib/features/students/presentation/import_students_excel_page.dart` | Not covered |
| Student details | `lib/features/students/presentation/student_details_page.dart` | Baseline mobile/desktop |
| Create follow-up case | `lib/features/follow_up/presentation/pages/create_follow_up_case_page.dart` | Not covered |
| Follow-up case details | `lib/features/follow_up/presentation/pages/follow_up_case_details_page.dart` | Not covered |
| Add follow-up activity | `lib/features/follow_up/presentation/pages/add_follow_up_activity_page.dart` | Not covered |
| Student follow-up profile | `lib/features/follow_up/presentation/pages/student_follow_up_profile_page.dart` | Not covered |
| Weekly follow-up | `lib/features/follow_up/presentation/weekly_follow_up_page.dart` | Not covered |
| Absence prioritization | `lib/features/follow_up/presentation/absence_prioritization_page.dart` | Not covered |
| Follow-up list/entry page | `lib/features/follow_up/presentation/follow_up_page.dart` | Not covered |
| Student analytics detail | `lib/features/reports/presentation/pages/student_analytics_detail_page.dart` | Not covered |
| Student notebook page | `lib/features/spiritual_notebook/presentation/pages/student_notebook_page.dart` | Baseline task12 state images; full viewport/theme matrix missing |

## Requested additions audit

The following requested surfaces are confirmed to exist in source and are currently missing the requested complete matrix:

- **Attendance:** `AttendanceClassPickerPage`, `MeetingListPage`, `MeetingPickerPage`, `MeetingSchedulesPage`. Note: no `meeting_picker_page.dart` exists in the inspected `lib/` tree; the actual picker-like routed page is `AttendanceClassPickerPage`. Confirm whether “meeting picker” means a dialog/sheet embedded in another page.
- **Auth/admin:** `ServantSignUpPage`, `ServantRegistrationRequestsPage`, `SystemAdminHomePage`.
- **Follow-up:** `CreateFollowUpCasePage`, `FollowUpCaseDetailsPage`, `AddFollowUpActivityPage`, `StudentFollowUpProfilePage`, `WeeklyFollowUpPage`, `AbsencePrioritizationPage`, `FollowUpPage`.
- **Students:** `ClassStudentsPage`, `ImportStudentsExcelPage`, normal `AddStudentPage` state.
- **Reports:** `StudentAnalyticsDetailPage`.
- **Service:** `StageDashboardPage`, `ServiceSettingsPage`, `StructureSettingsPage`, `SystemSettingsPage`, populated `ServiceDashboardPage`.
- **Other:** `GlobalSettingsPage`, `ExportPage`, `WeeklyPrepPage`, `SyncConflictPage`, `StudentNotebookPage`, and `AttendancePage` if it is a distinct entry surface.

## Baseline golden coverage observed

The current `test/goldens/full_app_golden_test.dart` documents and renders the following baseline screen families: login, service dashboard, attendance session, QR scan outcomes, students list, student details, add-student validation, shell More sheet, follow-up hub, reports, servant management and sync center. Separate task tests add notebook, servant preparation, dark component and text-scale examples.

Baseline presence does **not** imply full coverage of all requested states, roles, viewport widths, themes, overlays or text scales. The committed image inventory should be treated as incomplete until each row above has a passing executable test and the full requested matrix is listed here with exact filenames.

## Required matrix convention

- Locale: Arabic (`ar`), RTL.
- Viewports: mobile `390×844`, desktop `1280×800`; tablet `820×1180` where the layout changes.
- Themes: light and dark.
- Text scale: 1.0 by default; 1.3 for dense dashboards, attendance, students, follow-up, reports and forms.
- Filename: `<screen>_<viewport>_<theme>.png`; append role and state tokens where they distinguish output; retain `_scale13` for 1.3x.
- Every overlay/state must be a distinct image with a unique, descriptive filename. A filter-open image must visibly show the open filter UI and must not duplicate the closed screen.
