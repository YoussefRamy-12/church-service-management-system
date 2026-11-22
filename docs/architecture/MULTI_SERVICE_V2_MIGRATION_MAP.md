# Multi-Service Architecture v2.0 — Existing-to-Target Migration Map

**Status:** Inspection baseline; no destructive cutover authorized by this document  
**Branch:** `feat/spiritual-notebook`  
**Inspected:** 2026-11-22  
**Target:** One church, one application, multiple independently managed services

## 1. Executive decision

The live database already has a `services` table and two service rows, but its student model is still service-owned: `students.service_id` is NOT NULL and all 82 current students belong to the original Primary Boys service. The second service currently has no student rows. The target model requires global student identity plus independent `service_students` memberships.

The safe migration is expand-and-contract:

1. Add `service_students` and backfill one membership for each existing student without changing student IDs.
2. Add nullable membership references to service-owned operational records and backfill them.
3. Deploy repositories, Drift schema, sync handlers, RLS and tests that read/write through memberships.
4. Verify old and new paths in parallel, including counts and historical joins.
5. Only in a later approved cutover, make the global identity model canonical and retire legacy service-owned student fields after all consumers have moved.

**Do not drop `students.service_id`, `current_class_id`, `proposed_class_id`, or other legacy fields during the expand phase.** Do not merge students based on names.

## 2. Live baseline

The inspected production project is healthy (PostgreSQL 17.11). The `public` schema contains 25 base tables; RLS is enabled on all 25.

| Current table | Observed role / state |
|---|---|
| `services` | Reuse as service registry. Two rows exist: Primary Boys and a second service. |
| `stages` | Service-owned organization; `service_id` exists. Reuse as service stages. |
| `classes` | Belongs to `stages`; service ownership is derived through stage. Reuse as service classes. |
| `students` | 82 approved rows, all in Primary Boys. Contains `service_id`, current/proposed class, name, birth date, phone, school, grade, enrollment date, approval status, photo, notes, deacon flag. Currently mixes person and membership attributes. |
| `student_sensitive_data` | Confidential data keyed by student. Must be reviewed before cross-service reuse; sensitive notes must not automatically become shared global identity data. |
| `servant_profiles` | Service-scoped servant assignment and role. One user can have multiple service assignments. Reuse as service role assignments initially. |
| `system_administrators` | Platform-level administrator assignment. Reuse for platform role model; do not conflate with service leadership. |
| `meetings` | Actual dated meeting occurrences with service ownership and schedule reference. Reuse as meeting occurrences. |
| `meeting_schedules` | Recurring schedule records. Extend for schedule types/exceptions as needed; preserve historical occurrences. |
| `attendance_records` | References `meeting_id`, `student_id`, `class_id_at_attendance`, recorder and idempotency key. Add membership linkage; preserve snapshots and immutable identity fields. |
| `follow_up_records` | Legacy follow-up history referencing student and creator; no service_id. Add membership/service linkage derived from current student and creator. |
| `follow_up_cases` | New case model with service, student and class. Add membership linkage; keep service-specific confidentiality. |
| `follow_up_case_assignments`, `follow_up_activities` | Case-owned child records. Service boundary should be inherited and enforced through the parent case. |
| `spiritual_notebook_activities`, `spiritual_notebook_categories`, `spiritual_notebook_settings` | Service configuration; reuse as service-owned configuration. |
| `spiritual_notebook_submissions` | Has service and student references; add membership reference. Preserve period and score snapshots. |
| `spiritual_notebook_submission_items` | Submission-owned snapshots; preserve as historical child records. |
| `weekly_lessons` | Stage-scoped content; service ownership derives from stage. |
| `weekly_lesson_preparations`, `weekly_lesson_preparation_reviews` | Preparation and review history linked to servant profiles and lessons; preserve audit trail. |
| `reporting_periods` | Service-owned reporting periods; reuse. |
| `servant_registration_requests` | Authentication onboarding workflow; keep separate from student membership. |
| `servant_attendance_records` | Servant attendance; keep service-scoped via servant assignment and meeting. |

Observed data checks:
- Students: 82; all currently have `approval_status = approved`.
- Attendance records: 192; no cross-service meeting/student mismatch found in the inspected join.
- Legacy follow-up records: 2; no cross-service creator/student mismatch found.
- Follow-up cases: 3; follow-up activities: 14.
- Existing service A meeting start: 15:00; existing service B meeting start: 18:00.

These are point-in-time counts, not permanent invariants.

## 3. Existing-to-target domain mapping

| v2.0 target domain | Existing implementation | Required change | Migration treatment |
|---|---|---|---|
| Platform / services | `services`, `system_administrators` | Add service lifecycle/configuration and explicit platform-role boundaries where absent. | Reuse; additive columns/tables only. |
| Global identity | `students` currently includes `service_id` and class/enrollment attributes. | Keep one person row; move service participation attributes into memberships. | Preserve student UUIDs; no name-based deduplication. |
| Service membership | No `service_students` table. | Add unique student/service membership, independent lifecycle and class assignment. | Backfill one row per existing student. |
| Service organization | `stages`, `classes` | Keep service ownership and enforce composite service consistency. | Reuse; add composite keys/constraints only after duplicate and FK audit. |
| Servants / authorization | `servant_profiles` plus `system_administrators` | Formalize platform role vs service assignment; support multiple services. | Reuse; no role broadening. |
| Meeting management | `meeting_schedules`, `meetings` | Add meeting types and schedule exceptions/config version where required. | Treat `meetings` as occurrences; do not rewrite historical dates/times. |
| Attendance | `attendance_records` references global student ID directly. | Reference membership and meeting within same service; preserve class-at-attendance snapshot. | Add nullable membership/service references and backfill. |
| Scoring | No independent score ledger identified in current public table inventory. Spiritual notebook points are a separate module. | Decide whether v2.0 scoring transactions are in scope for a later phase. | Do not reinterpret notebook points as a general scoring ledger. |
| Follow-up | Legacy `follow_up_records` plus `follow_up_cases` and child tables. | Ensure every case/history row is membership-owned and confidential per service. | Add linkage; preserve all activity and case history. |
| Spiritual notebook | Service-owned activities/settings/submissions with direct student FK. | Link submissions to membership; retain service-specific activity configuration and snapshots. | Add membership linkage; retain existing score snapshots. |
| Weekly preparation | Lesson/stage and servant-profile relationships. | Ensure lesson stage and servant assignment resolve to same service; preserve review history. | Reuse and add cross-service integrity tests. |
| Reporting | `reporting_periods` is service-owned. | Keep reports service-scoped; cross-service aggregation requires platform permission. | Reuse; adapt queries to membership. |
| Offline cache | Drift `CachedStudents` currently stores `serviceId`, current/proposed class, approval, school/grade and other attributes in one row. | Split global cached identity from cached service membership; add membership IDs to operational caches. | Drift schema upgrade; copy local legacy rows transactionally. |
| Sync | Strategy handlers exist for students, attendance, follow-up, meetings, services and weekly prep. | Add membership handler; make operational payloads carry membership/service context; validate server-side. | Idempotent dual-write/read migration; keep old queued operations replayable. |

## 4. Target membership model

The target membership must represent service participation, not the person:

- `id` — stable UUID for the membership.
- `student_id` — global person identity.
- `service_id` — owning service.
- `class_id` — current class within that service.
- `proposed_class_id` — pending class assignment, if applicable.
- `enrollment_date` — service enrollment date.
- `status` — pending, active, inactive, graduated, rejected.
- `created_at`, `updated_at`.

Required uniqueness: `UNIQUE(student_id, service_id)` for one retained membership per student/service under the initial policy. Re-enrollment must reactivate or transition the retained membership according to an explicit lifecycle policy; it must not silently create duplicates.

Identity matching must be explicit and auditable. A name or name-plus-birth-date match is a candidate, not permission to merge.

## 5. Operational references to membership

The current schema directly references `students` from:
- `attendance_records`
- `follow_up_records`
- `follow_up_cases`
- `spiritual_notebook_submissions`
- `student_sensitive_data`

The first four are operational and should gain membership linkage. `student_sensitive_data` needs a separate confidentiality decision: if its content is collected/owned by a service, its access boundary must be membership-scoped; do not expose it to every service merely because the person identity is global.

For attendance, enforce that meeting, membership and service are consistent at the database layer. For follow-up and notebook submissions, enforce that the referenced membership belongs to the same service as the parent operational record.

## 6. Drift and offline synchronization mapping

Current Drift schema version is 9. `CachedStudents` has a primary key on student ID and includes service-specific fields. The local schema currently has:
- `CachedStudents` with `serviceId`, class IDs, approval status, school, grade, enrollment, deacon flag.
- `CachedStudentSensitiveData` keyed by student ID.
- `CachedAttendanceRecords` with meeting and student IDs but no membership/service ID.
- `CachedFollowUpRecords` with student ID but no service/membership ID.
- `CachedFollowUpCases` with service and student IDs.
- A persistent `SyncQueueEntries` idempotency key and handler strategy.

Target changes:
1. Add a global cached student identity table (or make `CachedStudents` identity-only).
2. Add `CachedServiceStudents` keyed by membership UUID, unique on student/service.
3. Add membership/service identifiers to attendance, follow-up and notebook cache rows.
4. Preserve queue operation IDs and legacy payload compatibility during rollout.
5. Validate membership/service ownership before applying remote writes.
6. Ensure retries are idempotent and revoked assignments cannot publish queued writes.

No local cache rows or queued operations may be dropped during the Drift upgrade.

## 7. Migration ledger reconciliation

At the initial audit, the remote ledger had 15 versions and the branch had 25 SQL files. After applying the four additive membership migrations below, the remote ledger has **19 versions** and the branch has **29 SQL files**. The four new versions are aligned exactly:

- `20261122125142_multi_service_membership_expand`
- `20261122125643_service_membership_class_scope_write`
- `20261122125923_service_membership_fk_indexes`
- `20261122130257_service_student_directory_rpc`

The remaining mismatch is 15 branch migration files not represented by the same version in the remote ledger, and 5 remote ledger versions without same-version files in this branch.

### Branch files absent from remote ledger

| Version | Migration file | Catalog evidence / disposition |
|---|---|---|
| 20261010150000 | allow_active_system_admin_create_services | Service creation policies exist; exact original migration effect needs diff review. |
| 20261010151000 | allow_active_system_admin_manage_students | Student admin policies exist; partly superseded by current scoped policies. |
| 20261010152000 | grant_active_system_admin_full_public_access | Broad admin policies exist on several tables; must not be replayed blindly. |
| 20261010153000 | add_service_meeting_schedule | `services` schedule columns and `meeting_schedules` exist. |
| 20261021234500 | revise_student_data_model | `is_deacon` and `student_sensitive_data` columns exist; exact historical backfill already appears represented in live data. |
| 20261022222202 | weekly_stage_prep_lessons | `weekly_lessons` exists with stage/service relationships. |
| 20261022230000 | allow_class_servant_import_current_class | Current student insert/update policies include class-scoped access; exact policy body should be diffed. |
| 20261022233000 | ensure_student_sensitive_data_columns | The expanded sensitive-data columns are present. |
| 20261023120000 | allow_student_hard_delete | Student delete policies and cascade FKs exist; this is a destructive behavior and should be retired only after archive semantics are implemented. |
| 20261023130000 | add_early_attendance_minutes | `services.early_attendance_minutes` exists. |
| 20261030090000 | weekly_lesson_servant_preparation | `weekly_lesson_preparations` exists. |
| 20261030100000 | named_attendance_meeting_schedules | `meeting_schedules` and `meetings.schedule_id/name` exist. |
| 20261110220000 | follow_up_cases_redesign | Case, assignment and activity tables and policies exist; 3 cases and 14 activities were present at audit. |
| 20261111230000 / 20261112010000 | weekly prep review and hardening | Review-history table, status columns, review RPC and write-guard trigger exist. |

### Remote ledger versions without same-version branch files

| Version | Ledger name | Evidence |
|---|---|---|
| 20261005115918 | add_system_super_admin | `system_administrators` and administrator authorization exist. |
| 20261005115940 | wire_super_admin_authorization | Active-system-admin helper and admin RLS policies exist. |
| 20261006152800 | fix_servant_profiles_admin_select_pending | Servant profile administrative policies exist. |
| 20261006152824 | allow_overall_admin_manage_all_servant_statuses | Current profile management policies include overall-admin access. |
| 20261022202810 | allow_student_delete_for_edit_roles | `students_delete` policy exists. |

This is evidence that many effects exist in the catalog, not a byte-for-byte proof that each migration's complete intended effect is present. Several migration names differ between branch history and remote history. No manual ledger repair was performed because the available migration-management action does not provide a safe repair operation and direct edits to Supabase's internal migration ledger would be unsafe.

**Do not reset the ledger, mark all 15 branch files applied, or replay historical migrations against production.** Finish a per-object diff against each original migration and then use a reviewed forward reconciliation migration or a supported Supabase migration repair workflow.

### Newly applied expand migrations

- `20261122125142_multi_service_membership_expand`: added `service_students`, added service ownership to classes, backfilled 82 memberships, and linked 192 attendance rows, 2 legacy follow-up rows, and 3 follow-up cases. Notebook submissions currently number zero.
- `20261122125643_service_membership_class_scope_write`: permits authenticated users to create/update memberships only within their service and class authorization scope.
- `20261122125923_service_membership_fk_indexes`: indexes the new composite foreign keys and adds the membership `updated_at` trigger.
- `20261122130257_service_student_directory_rpc`: exposes a service-scoped, authorization-checked identity projection so a second service can read only the global identity fields for its own memberships without broadening direct access to the legacy `students` table.

The Flutter/Drift branch now has schema version 11 with a `CachedServiceStudents` table, a `ServiceStudent` domain entity, an offline-first membership repository, and a `service_student` sync handler, and the `get_service_student_directory` RPC projection. Offline tests cover membership cache isolation by service, queued upserts, and archive state changes.

**Compatibility boundary:** the existing student screens and legacy student repositories still read/write `students.service_id/current_class_id`. The new membership repository and sync handler are additive foundations; the student UI and existing workflows have not yet been switched to membership-first reads/writes or to consume the new identity projection. Therefore this expansion does not yet enable end-to-end second-service student workflows.

The old `students.service_id` and class columns remain in place. No contract/drop migration has been applied.

## 8. Security review baseline

- All 26 public tables have RLS enabled; `FORCE ROW LEVEL SECURITY` is false on them.
- The two previously anonymous-executable `SECURITY DEFINER` helpers, `public.is_active_system_admin()` and `public.is_active_service_schedule_leader(text)`, now have execution revoked from `PUBLIC` and `anon`; `authenticated` and `service_role` retain execution for RLS/application use. The anonymous execution finding is cleared.
- The advisor now flags seven authenticated-executable `SECURITY DEFINER` functions. These include the registration/enrollment RPCs, admin predicates, weekly-preparation review, spiritual-notebook submission, and the new service-scoped student directory RPC. They are intentionally callable by authenticated clients; each still needs periodic function-body authorization review. Do not blanket-revoke these or convert them to invoker without testing their RLS dependencies.
- The weekly-preparation review RPC now resolves the lesson's service before selecting the active reviewer profile and requires the preparer profile to belong to that same service. The previous arbitrary cross-service `LIMIT 1` selection has been removed.
- Advisor reports leaked-password protection disabled; enable it in Supabase Auth settings after confirming project policy. This setting could not be changed through the available database tools.
- The advisor still reports 51 multiple-permissive-policy combinations and 13 unindexed foreign keys. The new membership FK indexes reduced the unindexed-FK findings from 25 to 13. Remaining findings are mainly existing creator/reviewer foreign keys. Permissive policies are OR-combined; they must be consolidated only after proving the effective authorization logic.

## 9. Migration gates and acceptance

### Gate A — expand schema
<badge color="success">Completed</badge>
- Added `service_students`, uniqueness, composite service/class constraints and RLS.
- Backfilled 82 memberships without changing global student UUIDs.
- Linked 192 attendance rows, 2 legacy follow-up rows and 3 follow-up cases.
- Verified zero unscoped classes and zero missing membership references in those operational tables.
- Kept legacy columns and policies in place.

### Gate B — application and offline dual compatibility
<badge color="warning">Partially completed</badge>
- Added the `ServiceStudent` entity, Drift membership cache (schema version 11), offline-first repository, and `service_student` sync handler.
- Added `get_service_student_directory` for authorized identity projection.
- Added offline cache, queue, archive, RPC-mapping and sync-engine tests.
- The existing student UI, attendance UI, follow-up UI and spiritual-notebook UI still use legacy student/service fields. The membership path is not yet wired through every feature or provider.
- A full on-device upgrade test from an existing v10 database and replay of old queued payloads remains required.

### Gate C — multi-service isolation
<badge color="warning">Partially completed</badge>
- Membership read/write RLS was tested with users from both services, including cross-service denial.
- Cross-service class assignment and attendance association were rejected by database constraints/triggers.
- The identity projection RPC was tested for authorized service access and cross-service denial.
- End-to-end second-service attendance, follow-up, notebook, and sensitive-data workflows are not yet enabled because their UI/repositories/RPCs have not all moved to membership IDs.
- Sensitive student data remains on the legacy student-keyed model and needs an explicit per-service confidentiality design.
- Offline membership queue behavior is covered; cross-service replay of all existing attendance/follow-up queue variants remains outstanding.

### Gate D — contract / cutover
<badge color="danger">Blocked</badge>
- Existing application consumers still depend on `students.service_id/current_class_id`.
- Student hard-delete policies and cascading historical deletes still exist; replace them with membership archival before claiming historical deletion safety.
- Migration ledger drift has not been repaired; 15 branch migrations and 5 remote ledger versions still need exact catalog diff/reconciliation.
- No legacy column or policy has been dropped. A backup/rollback plan and full multi-service regression are required before a separate contract migration.

## 10. Current decision

The live database now has an additive membership expansion and a service-scoped global-identity projection. It is a valid expand-phase foundation, not a completed v2.0 cutover. The existing single-service application remains on its legacy data path. Continue by integrating membership-first reads/writes feature by feature, adding archive semantics and sensitive-data boundaries, then run full two-service end-to-end and offline replay tests before contract migration.
