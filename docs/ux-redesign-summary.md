# UX Mobile Redesign Summary (`ux/mobile-redesign`)

Draft PR summary for the Arabic-first, RTL, mobile-first **Warm Navy** UX redesign on branch `ux/mobile-redesign`.

## Overview

This branch redesigns the Diakonia Stewardship interface around the **Warm Navy** design system (`DESIGN.md`, `docs/ux-spec.md`, `docs/ui-tokens.md`) with flat opaque surfaces, 1px borders, WCAG AA semantic contrast, RTL-first directional layouts, and responsive mobile/tablet/desktop compositions.

---

## What Changed Per Area

### 1. Design System & Shared UI Tokens
- Defined the **Warm Navy** light and dark palettes, spacing (`AppSpacing`), radii (`AppRadii`), typography (`AppTypography`), and semantic color extensions (`AppColors`) in `lib/app/design/`.
- Consolidated shared flat surface, status chip, and responsive layout primitives in `lib/app/ui/app_ui.dart` and documented usage in `DESIGN.md` and `docs/ui-tokens.md`.

### 2. Responsive Shell & Navigation (Task 2)
- Implemented a responsive shell (`lib/app/ui/` / navigation shell) with 5 persistent mobile bottom-bar destinations (الرئيسية، الحضور، التلاميذ، المتابعة، المزيد), an RTL right-edge tablet navigation rail, and a persistent desktop sidebar.
- Added safe-area handling around the tablet rail, unified account actions in the More sheet, and verified keyboard insets and 1.3× text scaling.

### 3. Attendance & QR Check-in (Task 3)
- Redesigned the attendance session page for one-handed mobile use (`lib/features/attendance/presentation/`) and decomposed it into focused widgets (`attendance_student_tile.dart`, `meeting_list_page.dart`, `qr_scan_page.dart`).
- Added widget tests covering attendance redesign flows.

### 4. Students & Service Dashboard (Task 4)
- Redesigned `service_dashboard_page.dart`, `students_page.dart`, and `add_student_page.dart`, and split `student_details_page.dart` into tab widgets with a dedicated header.
- Added role-scoped dashboard and student list filtering tests (`test/service_dashboard_role_test.dart`, `test/students_list_filtering_test.dart`).
- Fixed an RTL directional padding leak in `lib/features/students/presentation/add_student_page.dart` (`EdgeInsets.only(bottom: 12, right: 4)` → `EdgeInsetsDirectional.only(bottom: 12, start: 4)`).

### 5. Auth, Session Gate, Service Picker & Sync Center (Task 5)
- Replaced legacy glass/blur panels in login, signup, password recovery, and session gate with flat Warm Navy themed surfaces, safe areas, accessible password visibility controls, and keyboard/autofill ordering.
- Updated the service picker and system admin service grid for responsive layouts with loading, empty, and retry states.
- Clarified sync summary, pending queue overview, and conflict cards in the Sync Center, with widget and golden tests (`login_page_widget_test.dart`, `session_gate_widget_test.dart`, `sync_center_widget_test.dart`, `login_page_golden_test.dart`).

### 6. Servants, Follow-up & Reports (Task 6)
- **Servants:** Extracted management dialogs and added responsive servant directory, role filters, and loading/retry states (`servant_management_page.dart`, `test/servant_role_filter_test.dart`).
- **Follow-up:** Added contact actions, quick activity sheet, flat themed contact surfaces, retry states, and loading skeletons (`follow_up_hub_page.dart` and `lib/features/follow_up/presentation/pages/`).
- **Reports:** Moved mobile report filters into a bottom sheet, aligned KPI cards with flat theme tokens, made the attendance trend chart scrollable and labeled, adapted the arrival distribution legend and class comparison into mobile cards, and added loading skeletons (`reports_page.dart`).
- Added Task 6 mobile light/dark golden coverage (`test/task6_mobile_golden_test.dart`).

### 7. Spiritual Notebook, Weekly Prep, Import/Export & Settings (Task 7)
- Split `spiritual_notebook_page.dart` into focused `part` files (state, controls, student list/filters, student notebook actions, leaderboard sections/controls/helpers, settings/actions, layout, data model) and added desktop two-column vs. mobile tabbed presentation.
- Updated `weekly_prep` sheets for safe areas and keyboard insets (`servant_prep_view.dart`, `leadership_prep_dashboard.dart`, `lesson_files_manager_sheet.dart`).
- Applied Warm Navy tokens to `global_settings_page.dart` and `import_students_excel_page.dart`, and adopted compact semantic `StatusChip` indicators in import/export flows.
- Added Task 7 mobile golden coverage (`test/task7_notebook_prep_mobile_golden_test.dart`).

### 8. Accessibility, Contrast, Dark Mode & Goldens (Task 8 — Uncommitted Working Tree)
- Added tap-target and WCAG AA contrast tests (`test/a11y_tap_target_test.dart`, `test/contrast_aa_test.dart`).
- Added dark-mode and 1.3× text-scale golden test suites (`test/task8_dark_golden_test.dart`, `test/task8_text_scale_golden_test.dart`).
- Cleaned up `app_ui.dart` and `app_theme.dart` tokens across 17 feature presentation files.

---

## Verification & Repo Hygiene

- **Static analysis (`flutter analyze`):** 0 issues (`No issues found!`).
- **Generated Drift code (`lib/core/database/app_database.g.dart`):** Tracked in git with no uncommitted modifications.
- **Test counts:**
  - Non-golden suite (`flutter test --exclude-tags=golden`): **297 passed, 0 failed, 0 skipped** (wall time ~26s).
  - Golden suite (`flutter test --update-goldens --tags golden`): **92 passed, 0 failed** (wall time ~20s), generating 68 full-screen/variant PNGs in `test/goldens/images/` plus Task 5–8 baselines.
  - Full suite (`flutter test`, no excluded tags): **389 passed, 0 failed, 0 skipped** (wall time 43.96s).

---

## Known Limitations & Follow-up Items

1. **Remaining `Color(0x...)` literals:** `333` occurrences remain in `lib/` (excluding `.g.dart`), concentrated in `app_colors.dart` (39) and `app_theme.dart` (25) token definitions, plus legacy report, follow-up, and weekly-prep widgets (`follow_up_analytics_view.dart` 19, `student_analytics_view.dart` 16, `report_export_dialog.dart` 16, `actionable_insights_card.dart` 13, `absence_prioritization_page.dart` 13, `preparation_review_dialog.dart` 12, `preparation_history_sheet.dart` 11, `student_analytics_detail_page.dart` 11).
2. **Intentional non-directional alignment:** `lib/features/auth/presentation/session_gate.dart:436-437` uses `Alignment.topLeft` / `Alignment.bottomRight` for a decorative square icon container gradient.
3. **Font fallback:** `IBM Plex Sans Arabic` is bundled in `assets/fonts/`; `Cairo` is referenced for headings in `AppTypography` and falls back to `IBM Plex Sans Arabic` / `Arial` unless explicitly loaded in tests or host environments.
4. **Working tree state:** Task 8 edits and new test files are currently uncommitted in the working tree pending final verification.
