# Multi-Service Architecture v2.0 — Existing-to-Target Migration Map

**Status:** Expand phase in progress; no destructive cutover authorized by this document  
**Branch:** `feat/spiritual-notebook`  
**Inspected:** 2026-11-22  
**Target:** One church, one application, multiple independently managed services

## 1. Executive decision

The live database already has a `services` table and two service rows, but its student model is still service-owned: `students.service_id` is NOT NULL and all 82 current students belong to the original Primary Boys service. The second service currently has no student memberships; all 82 memberships belong to the original Primary Boys service. No student identity is currently shared across services. The target model requires global student identity plus independent `service_students` memberships.

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
| `students` | 82 approved global identity rows, all owned by Primary Boys. Still contains legacy `service_id`, current/proposed class, school, grade, enrollment date and approval fields alongside identity attributes. |
| `student_sensitive_data` | Confidential data keyed by student. Must be reviewed before cross-service reuse; sensitive notes must not automatically become shared global identity data. |
| `servant_profiles` | Service-scoped servant assignment and role. One user can have multiple service assignments. Reuse as service role assignments initially. |
| `system_administrators` | Platform-level administrator assignment. Reuse for platform role model; do not conflate with service leadership. |
| `meetings` | Actual dated meeting occurrences with service ownership and schedule reference. Reuse as meeting occurrences. |
| `meeting_schedules` | Recurring schedule records. Extend for schedule types/exceptions as needed; preserve historical occurrences. |
| `attendance_records` | Retains `meeting_id`, `student_id`, `class_id_at_attendance`, recorder and idempotency key; `service_id` and `service_student_id` are now populated for all 192 rows. |
| `follow_up_records` | Retains student and creator references; `service_id` and `service_student_id` are now populated for both legacy rows. |
| `follow_up_cases` | Service/student/class-owned case model; `service_student_id` is populated for all 3 current cases. |
| `follow_up_case_assignments`, `follow_up_activities` | Case-owned child records. Service boundary should be inherited and enforced through the parent case. |
| `spiritual_notebook_activities`, `spiritual_notebook_categories`, `spiritual_notebook_settings` | Service configuration; reuse as service-owned configuration. |
| `spiritual_notebook_submissions` | Has service, student and membership references with a composite membership/service FK. No submissions exist yet. |
| `spiritual_notebook_submission_items` | Submission-owned snapshots; preserve as historical child records. |
| `weekly_lessons` | Stage-scoped content; service ownership derives from stage. |
| `weekly_lesson_preparations`, `weekly_lesson_preparation_reviews` | Preparation and review history linked to servant profiles and lessons; preserve audit trail. |
| `reporting_periods` | Service-owned reporting periods; reuse. |
| `servant_registration_requests` | Authentication onboarding workflow; keep separate from student membership. |
| `servant_attendance_records` | Servant attendance; keep service-scoped via servant assignment and meeting. |

Observed data checks:
- Global students: 82; all currently have `approval_status = approved`.
- Service memberships: 82; all 82 currently belong to Primary Boys; zero identities are shared across services.
- The second service has zero memberships, so live two-service data-isolation acceptance is not yet demonstrated.
- Attendance records: 192; no cross-service meeting/student mismatch found in the inspected join.
- Legacy follow-up records: 2; no cross-service creator/student mismatch found.
- Follow-up cases: 3; follow-up activities: 14.
- Existing service A meeting start: 15:00; existing service B meeting start: 18:00.

These are point-in-time counts, not permanent invariants.

## 3. Existing-to-target domain mapping

| v2.0 target domain | Existing implementation | Required change | Migration treatment |
|---|---|---|---|
| Platform / services | `services`, `system_administrators` | Add service lifecycle/configuration and explicit platform-role boundaries where absent. | Reuse; additive columns/tables only. |
| Global identity | `students` still includes legacy `service_id` and class/enrollment attributes. | Keep one person row; move service participation attributes into memberships. | Preserve student UUIDs; no name-based deduplication. |
| Service membership | `service_students` now exists with independent class, enrollment and lifecycle fields. | Finish membership-first feature cutovers and identity reuse controls. | 82 memberships backfilled; no shared identities yet. |
| Service organization | `stages`, `classes` | Keep service ownership and enforce composite service consistency. | Reuse; add composite keys/constraints only after duplicate and FK audit. |
| Servants / authorization | `servant_profiles` plus `system_administrators` | Formalize platform role vs service assignment; support multiple services. | Reuse; no role broadening. |
| Meeting management | `meeting_schedules`, `meetings` | Add meeting types and schedule exceptions/config version where required. | Treat `meetings` as occurrences; do not rewrite historical dates/times. |
| Attendance | `attendance_records` retains student ID and now carries membership/service IDs. | Switch Flutter repository and sync operations to membership IDs; preserve class-at-attendance snapshot. | 192 historical rows linked; all references populated. |
| Scoring | No independent score ledger identified in current public table inventory. Spiritual notebook points are a separate module. | Decide whether v2.0 scoring transactions are in scope for a later phase. | Do not reinterpret notebook points as a general scoring ledger. |
| Follow-up | Legacy `follow_up_records` plus membership-linked cases and child tables. | Switch both follow-up workflows to membership-first reads/writes. | 2 records and 3 cases linked; preserve all activity and case history. |
| Spiritual notebook | Service-owned activities/settings; submissions include membership linkage and a composite service FK. | Switch notebook repository, RPC and RLS fully to membership ownership. | Membership schema ready; zero historical submissions to backfill. |
| Weekly preparation | Lesson/stage and servant-profile relationships. | Ensure lesson stage and servant assignment resolve to same service; preserve review history. | Reuse and add cross-service integrity tests. |
| Reporting | `reporting_periods` is service-owned. | Keep reports service-scoped; cross-service aggregation requires platform permission. | Reuse; adapt queries to membership. |
| Offline cache | Drift `CachedStudents` still stores legacy `serviceId`, current/proposed class and approval alongside identity attributes; `CachedServiceStudents` now stores service membership rows separately. | Split global cached identity from cached service membership; add membership IDs to operational caches. | Drift schema upgrade; copy local legacy rows transactionally. |
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

Current Drift schema version is 14. `CachedStudents` remains the global identity cache keyed by student ID. `CachedServiceStudents` is the per-membership offline roster cache keyed by membership ID and now stores the identity-owning service ID. The local schema currently has:
- `CachedStudents` with global identity fields, service membership fields, membership ID/status, and identity owner metadata.
- `CachedStudentSensitiveData` keyed by global student ID; offline reads are denied unless the current service is the identity-owning service.
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

At the initial audit, the remote ledger had 15 versions and the branch had 25 SQL files. After applying the eleven additive membership, security and performance migrations below, the remote ledger has **26 versions** and the branch has **36 SQL files**. The eleven new versions are aligned exactly:

- `20261122125142_multi_service_membership_expand`
- `20261122125643_service_membership_class_scope_write`
- `20261122125923_service_membership_fk_indexes`
- `20261122130257_service_student_directory_rpc`
- `20261122131229_index_remaining_foreign_keys`
- `20261122140938_students_membership_workflows`
- `20261122141313_students_update_nullable_date_guard`
- `20261122141534_student_directory_identity_scope`
- `20261122143825_spiritual_notebook_membership_cutover`
- `20261122143841_spiritual_notebook_active_membership_roster`
- `20261122144712_restore_pending_membership_directory`

The remaining mismatch is 15 branch migration files not represented by the same version in the remote ledger, and 5 remote ledger versions without same-version files in this branch. The eleven expand-phase migrations now match the remote ledger versions exactly after correcting local filenames to their applied versions.

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
- `20261122131229_index_remaining_foreign_keys`: adds covering indexes for remaining creator/reviewer and child-table foreign keys; the performance advisor now reports zero unindexed foreign keys.
- `20261122160500_students_membership_workflows`: adds authenticated, RLS-invoker RPCs for atomic registration, membership editing, approval, class assignment, and archival.
- `20261122162000_students_update_nullable_date_guard`: preserves existing required date values when optional edit fields are omitted.
- `20261122162500_student_directory_identity_scope`: adds `identity_service_id` to the directory projection so local sensitive-data cache fallback is denied across service boundaries.

The Flutter/Drift branch now has schema version 14, a `CachedServiceStudents` table, membership IDs and identity ownership in `CachedStudents`, a `ServiceStudent` domain entity, an offline-first membership repository, and a `service_student` sync handler. The directory RPC returns the identity-owning service ID for sensitive-data isolation. Spiritual Notebook now reads active membership rosters and submits scores against membership IDs, with a class-at-submission snapshot and per-membership weekly uniqueness. The shared directory RPC still includes pending memberships for Students approval; the notebook repository filters them out locally. Offline tests cover membership cache isolation by service, queued upserts, and archive state changes.

**Compatibility boundary:** the Students screen now reads its roster through `get_service_student_directory` and routes registration, editing, approval, class assignment, and archival through membership lifecycle RPCs. Legacy `students` columns are dual-written only for the existing owning service while other modules are migrated. Attendance, Follow-up, and Spiritual Notebook still need membership-first application cutovers, so this phase does not yet enable complete second-service operations.

The old `students.service_id` and class columns remain in place. No contract/drop migration has been applied.

## 8. Security review baseline

- All 26 public base tables have RLS enabled; `FORCE ROW LEVEL SECURITY` is false on them.
- The two previously anonymous-executable `SECURITY DEFINER` helpers, `public.is_active_system_admin()` and `public.is_active_service_schedule_leader(text)`, now have execution revoked from `PUBLIC` and `anon`; `authenticated` and `service_role` retain execution for RLS/application use. The anonymous execution finding is cleared.
- The advisor now flags seven authenticated-executable `SECURITY DEFINER` functions. These include the registration/enrollment RPCs, admin predicates, weekly-preparation review, spiritual-notebook submission, and the service-scoped student directory RPC. The directory RPC explicitly checks service access and returns only the limited identity projection; it does not return sensitive-data rows. They are intentionally callable by authenticated clients; each still needs periodic function-body authorization review. Do not blanket-revoke these or convert them to invoker without testing their RLS dependencies.
- The weekly-preparation review RPC now resolves the lesson's service before selecting the active reviewer profile and requires the preparer profile to belong to that same service. The previous arbitrary cross-service `LIMIT 1` selection has been removed.
- Advisor reports leaked-password protection disabled; enable it in Supabase Auth settings after confirming project policy. This setting could not be changed through the available database tools.
- The advisor now reports **zero unindexed foreign keys**; the membership and remaining creator/reviewer FK indexes were added in the last two index migrations. It still reports 51 multiple-permissive-policy combinations and 29 unused-index notices. The latest advisor scan confirms 7 authenticated-executable `SECURITY DEFINER` functions, no anonymous execution on those functions, and leaked-password protection disabled. The unused-index notices include the newly created FK indexes, which have not yet accumulated workload usage; do not drop FK-covering indexes solely because the workload is currently small. Permissive policies are OR-combined and must be consolidated only after proving the effective authorization logic.

## 9. Migration gates and acceptance

### Gate A — expand schema
**Status: Completed**
- Added `service_students`, uniqueness, composite service/class constraints and RLS.
- Backfilled 82 memberships without changing global student UUIDs.
- Linked 192 attendance rows, 2 legacy follow-up rows and 3 follow-up cases.
- Verified zero unscoped classes and zero missing membership references in those operational tables.
- Kept legacy columns and policies in place.

### Gate B — application and offline dual compatibility
**Status: Partially completed**
- Added the `ServiceStudent` entity, Drift membership cache (schema version 13), offline-first repository, and `service_student` sync handler.
- Added `get_service_student_directory` for authorized identity projection, including the identity-owning service identifier used to isolate sensitive data.
- Implemented Students membership-backed reads and registration, editing, approval, class assignment, and membership archival through transactional/authorized RPCs.
- Drift now uses schema version 14 and caches membership ID, membership status, and identity ownership.
- Offline registration queues the global student insert before its service membership upsert; membership edits/approval/class changes sync separately.
- Legacy queued physical student deletes now become sync conflicts instead of deleting global identities.
- Sensitive data is not read from the local device cache when the active membership belongs to a different service or identity ownership is unknown.
- Added offline cache, queue, archive, RPC-mapping, and sync-engine tests.
- Global identity search/verification and confirmed reuse are not yet exposed in the UI. Duplicate matching remains explicit; automatic merging is out of scope.
- The preceding stable CI baseline passed dependency resolution, Drift generation, Flutter analysis, web build and 189 tests. The current Students membership-first changes are under a new CI regression run; do not treat them as validated until that run passes.
- The Students feature now reads and mutates service memberships through the new directory/lifecycle RPCs. Attendance and Follow-up still require their UI/repository/sync cutovers. Spiritual Notebook has membership columns and constraints but its RPC, RLS and repository still use the legacy student-owned path.
- A full on-device upgrade test from existing v11/v12/v13 databases and replay of old queued payloads remains required; CI generation and tests are the current validation gate.

### Gate C — multi-service isolation
<badge color="warning">Partially completed</badge>
- Membership read/write RLS was tested with users from both services, including cross-service denial.
- Cross-service class assignment and attendance association were rejected by database constraints/triggers.
- The identity projection RPC was tested for authorized service access and cross-service denial.
- Cross-service reads of `student_sensitive_data` returned zero rows; the directory RPC does not expose that table.
- Legacy-shaped attendance, follow-up and spiritual-notebook writes were tested in temporary transactions; the database triggers attached the correct membership automatically, and all temporary rows were removed.
- Cross-service follow-up association was rejected by the hierarchy validator.
- End-to-end second-service attendance and follow-up workflows are not yet enabled because their UI/repositories/RPCs have not all moved to membership IDs. Spiritual Notebook now uses membership IDs, but a real second-service membership and submission test remains outstanding.
- Sensitive student data remains on the legacy student-keyed model and needs an explicit per-service confidentiality design.
- Offline membership queue behavior is covered; cross-service replay of all existing attendance/follow-up queue variants remains outstanding.

### Gate D — contract / cutover
**Status: Blocked**
- Existing application consumers still depend on `students.service_id/current_class_id`.
- Student hard-delete policies and cascading historical deletes still exist; replace them with membership archival before claiming historical deletion safety.
- Migration ledger drift has not been repaired; 15 branch migrations and 5 remote ledger versions still need exact catalog diff/reconciliation.
- No legacy column or policy has been dropped. A backup/rollback plan and full multi-service regression are required before a separate contract migration.

## 10. Current decision

The live database now has an additive membership expansion and a service-scoped global-identity projection. It is a valid expand-phase foundation, not a completed v2.0 cutover. The Students feature has moved to membership-first access, while Attendance, Follow-up and Spiritual Notebook remain in compatibility mode. Continue by integrating membership-first reads/writes feature by feature, adding archive semantics and sensitive-data boundaries, then run full two-service end-to-end and offline replay tests before contract migration.
