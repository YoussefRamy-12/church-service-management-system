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

The remote Supabase migration ledger contains 15 versions. The branch migration directory contains 25 SQL files. These sets are not equivalent:
- The remote ledger has entries not represented by same-version files in this branch (including early October administrator migrations and `20261022202810`).
- The branch has later migrations absent from the remote ledger, including weekly-preparation, follow-up, and student-model migrations.

This is migration-history drift, not proof that every absent migration's schema effect is absent. Some effects may have been applied manually, folded into later migrations, or represented by migrations that were renamed. The catalog must be compared by object definition, constraints, policies, indexes, triggers and function bodies before any ledger repair.

**Do not blindly mark all missing files applied, reset the ledger, or replay historical migrations against production.** First create a per-migration evidence matrix: intended objects, current catalog match, data effect, safe action (already present / needs forward migration / ledger-only reconciliation / obsolete).

## 8. Security review baseline

- All 25 public tables have RLS enabled; `FORCE ROW LEVEL SECURITY` is false on them.
- The Supabase security advisor identified two anonymous-executable `SECURITY DEFINER` helpers: `public.is_active_system_admin()` and `public.is_active_service_schedule_leader(text)`. Their bodies use `auth.uid()`; anonymous execution is not needed. Revoke execution from `PUBLIC` and `anon`, retaining `authenticated` and `service_role`.
- Four other `SECURITY DEFINER` RPCs are authenticated-only and include in-function authorization/ownership checks. Review their bodies individually; do not blanket-revoke required application RPCs or convert them to invoker without evaluating RLS dependencies.
- Advisor reports leaked-password protection disabled; enable it in Supabase Auth settings after confirming project policy.
- The advisor reports multiple permissive RLS policies and unindexed FK findings. These require per-table review; permissive policies are OR-combined, so deleting a policy by count alone can break admin access or change effective scope.
- A function review found `review_weekly_preparation` selects an active reviewer profile before resolving the lesson's service and uses `LIMIT 1`. A user with assignments in multiple services may be recorded under the wrong servant profile. Resolve the lesson's service first, then select the reviewer profile in that service.

## 9. Migration gates and acceptance

### Gate A — expand schema
- Add membership table, unique/index constraints and RLS.
- Backfill exactly one membership per current student, preserving UUID, service, class, approval state and timestamps.
- Add/backfill membership links for operational records.
- Verify no null or cross-service membership references.
- Keep all legacy columns and policies needed by the current app.

### Gate B — application and offline dual compatibility
- Update domain entities/repositories/providers.
- Upgrade Drift schema with a transactional local data copy.
- Update sync handlers and replay legacy queue payloads safely.
- Add unit/integration tests for membership lifecycle and idempotency.
- Keep the old single-service workflow working.

### Gate C — multi-service isolation
- Service A cannot read/write Service B membership, attendance, follow-up, notebook or sensitive data.
- A student can have two memberships without duplicating the global student identity.
- Class/stage-scoped roles remain scoped.
- System super admin remains platform-scoped, not silently granted to service leaders.
- Offline queue replay cannot move a record across services.

### Gate D — contract / cutover
- All app and sync consumers use membership IDs.
- Data parity and historical joins are proven.
- Rollback plan and backup are verified.
- Only then propose removal of legacy service-owned fields and obsolete policies/FKs in a separate reviewed migration.

## 10. Current decision

The current database is not yet the v2.0 global identity model. It is a service-scoped student model with multiple service infrastructure already present. The next safe implementation unit is an additive membership expansion, followed by application/offline adaptation. Production cutover is blocked until the regression and service-isolation gates pass.
