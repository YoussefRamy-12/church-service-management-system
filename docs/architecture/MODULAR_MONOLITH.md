# Modular Monolith Architecture

## Status: migration in progress — target not yet reached

This repository is being refactored into a **fully enforced modular monolith**: one Flutter application and one deployable artifact, with feature-owned modules and explicit dependency boundaries. This is the target architecture, **not a description of the current achieved state**.

The current architecture audit is intentionally report-and-allowlist based while existing dependencies are removed incrementally. `test/architecture/known_violations.txt` lists the exact violations and cycle records that remain. It is a migration ledger, not an approval of those dependencies. The target is reached only when the relevant audit rules are enforced and the remaining violation/cycle allowlist is empty (apart from any explicitly documented, approved non-violation records).

The migration is incremental and must preserve runtime behavior, persisted production data, and existing contracts unless a separately approved change says otherwise. This is a modular monolith, not a microservices migration.

## Target project layout

```text
lib/
  app/                         # Composition root, routing, application entry points
  core/                        # Technical infrastructure shared by modules
    config/
    database/
    network/
    sync/
    ...
  shared_kernel/               # Small, stable cross-feature identity/value entities
  features/
    attendance/
      attendance.dart          # Public feature API (barrel)
      presentation/
      application/
      domain/
      data/
    auth/
      auth.dart
      presentation/
      application/
      domain/
      data/
    service/
      service.dart
      presentation/
      application/
      domain/
      data/
    students/
    follow_up/
    servants/
    reports/
    settings/
    spiritual_notebook/
    weekly_prep/
    export/
test/
  architecture/
    known_violations.txt
tool/
  arch_audit.dart
  arch_audit_lib.dart
docs/
  architecture/
    MODULAR_MONOLITH.md
```

A feature owns its presentation, application, domain, and data implementation. Its public barrel is the supported entry point for other features. Internal directories are private implementation details and must not become cross-feature APIs.

### Layer responsibilities and dependency direction

- **Presentation** owns screens, widgets, and view-facing state. It may depend on its own feature's application/domain code and on explicitly published contracts of other features. It must not reach into another feature's presentation or data implementation.
- **Application** owns use-case orchestration. It may depend on its own domain and declared abstractions/contracts, including explicitly published APIs where orchestration requires them.
- **Domain** owns business entities, value objects, and repository abstractions. It depends on language primitives and domain-level abstractions, not Flutter UI, persistence, Supabase, or Riverpod implementation details.
- **Data** implements its feature's domain abstractions. It may depend on its own domain, core infrastructure, shared-kernel types, and external packages. It must not depend on another feature's data implementation.
- **Core** contains technical infrastructure (database, sync, network, configuration, utilities, and shared technical UI). It must not depend on feature code or app composition.
- **App** is the composition root: application entry points, routing, and dependency assembly. It may connect feature public APIs; it must not become a place for business logic.
- **Shared kernel** contains only small, stable concepts genuinely shared across features. It may depend on Dart, core abstractions, and other shared-kernel declarations; it must not depend on feature internals or UI/platform implementation.

### Foundation features

**Auth and Service are foundation features.** Every feature may consume their supported public APIs through `lib/features/auth/auth.dart` and `lib/features/service/service.dart`. Foundation features must not depend on other features.

There are known reverse dependencies today: auth depends on attendance through `session_gate.dart`; service depends on students and attendance through dashboard/settings pages. Those edges are intentionally left for Phase 3. They must remain visible in the allowlist until that phase removes them; do not hide them by changing the audit baseline.

## Dependency rules R1–R10

These rules describe the intended architecture. The current audit implements only the checks identified below; a rule being documented does not mean it is already fully enforced. The audit's `R8-X` and `R5-SOFT` labels are additional reporting labels, not replacements for the target rule numbering.

| Rule | Target constraint | Current audit / migration status |
|---|---|---|
| **R1 — Feature boundaries** | A feature must not import another feature's internal files. Cross-feature use goes through the owning feature's public barrel/API. | Implemented as a report. Direct cross-feature imports are emitted as `R1` violations; the feature's exact public barrel path is exempted. Remaining records are in `known_violations.txt`. |
| **R2 — Acyclic feature graph** | Feature dependencies must be acyclic. No strongly connected component may contain more than one feature. | Implemented as cycle reporting. `CYCLE` records identify remaining strongly connected components. Reciprocal dependency pairs are separately reported as `RECIPROCAL_PAIR`; they are not the same count as SCCs. |
| **R3 — Core isolation** | Core must not depend on feature modules or app composition. | Implemented as a report for core-to-feature and core-to-app dependencies. Remaining records are allowlisted. |
| **R4 — Shared-kernel isolation** | Shared-kernel code may depend only on Dart and approved core/shared-kernel declarations; it must not depend on features, app composition, or UI/platform implementation. | Implemented as a report for disallowed shared-kernel imports. |
| **R5 — Domain purity** | Domain code must not depend on presentation/framework, persistence, or backend implementation packages. | Partially implemented. Flutter Material, Supabase, Drift, and Flutter Riverpod imports are hard `R5` violations. Flutter foundation imports are currently reported separately as `R5-SOFT` for staged migration; they are not a statement that all framework dependencies are acceptable. |
| **R6 — Application boundaries** | Application code may depend on its own domain, its own application code, shared-kernel abstractions, and explicitly declared public contracts. It must not reach into another feature's internals or depend on presentation/data implementation. | Target rule; not yet implemented as a complete audit check. |
| **R7 — Presentation boundaries** | A feature's presentation layer must not import another feature's presentation or data implementation. Use the other feature's public API/contract instead. | Implemented as a report for cross-feature presentation-to-presentation and presentation-to-data imports. |
| **R8 — Data boundaries** | Data code may depend on its own domain, core, shared kernel, and external packages. It must not depend on another feature's data implementation. | Target rule; the full allowed/forbidden dependency matrix is not yet enforced. |
| **R9 — App composition** | App is the composition root and the only layer that may import feature presentation entry points to assemble navigation/application composition. Feature modules must not import app composition. | Target rule; not yet implemented as a complete audit check. |
| **R10 — Infrastructure access** | Presentation and application code must not directly depend on Supabase or Drift. Access persistence/backend infrastructure through feature-owned abstractions and providers/repositories. | Implemented as a report for presentation/application imports of `supabase_flutter` and `drift`. Remaining records are allowlisted. |

Additional audit labels:

- **R5-SOFT** records domain imports of `package:flutter/foundation.dart`. These are tracked separately while domain models are migrated away from framework annotations/types.
- **R8-X** currently reports cross-feature data-to-data dependencies as an extra diagnostic. It does not replace R8's complete data-layer dependency rule.
- `CYCLE` and `RECIPROCAL_PAIR` are graph diagnostics, not ordinary `VIOLATION` lines. A graph can contain reciprocal pairs within one SCC, so their counts must not be conflated.

## Architecture audit and allowlist policy

The audit implementation is in `tool/arch_audit_lib.dart`; `tool/arch_audit.dart` is its CLI entry point. CI runs the audit against `lib/` and the architecture tests validate the audit and the known-violations ledger.

`test/architecture/known_violations.txt` is the exact baseline of known outstanding audit records:

- Keep the records sorted and preserve the audit's exact output format.
- Remove a record only when the corresponding dependency/cycle has actually been eliminated.
- Never add a new record merely to make CI green. An addition is allowed only when a migration batch explicitly authorizes that exact new record (for example, a planned move that changes a soft framework-import classification); otherwise it is a newly introduced architecture violation and the batch must stop.
- After a code batch, use the live audit output from that same CI run to prepare any permitted allowlist synchronization. Compare old and new ledgers: deletions are expected; additions must be explicitly authorized for that batch.
- A green CI run proves the current code matches the checked-in audit contract. It does not prove that the target architecture has been reached while known violations remain.
- Do not hand-edit generated files such as `*.g.dart`. If a proposed move is referenced by generated output that cannot yet be regenerated safely, stop that move and resolve the generation workflow first.

The allowlist must shrink as migration proceeds. Do not weaken, suppress, or redefine a rule to make an existing violation disappear.

## Adding a feature module

1. Create `lib/features/<feature_name>/` with only the layers it needs: `presentation/`, `application/`, `domain/`, and `data/`.
2. Keep implementation files private to that feature. Define a small, intentional public API in `<feature_name>.dart`; export only types/providers/contracts that consumers legitimately need.
3. Put shared identity/value concepts in `lib/shared_kernel/` only when they are truly cross-feature and stable. Do not use the kernel as a dumping ground for feature logic.
4. Depend inward on the feature's own abstractions. Put infrastructure implementations in `data/`; keep Supabase/Drift access out of presentation/application and keep framework details out of domain.
5. For cross-feature collaboration, import the owning feature's public barrel or an explicitly defined contract. Never import another feature's `presentation/`, `data/`, or private `domain/` file.
6. Keep dependencies one-way and preserve an acyclic feature graph. Foundation features (auth and service) are consumed through their barrels and must not depend on other features.
7. Add or update focused tests and architecture checks. Do not add new allowlist entries unless the batch specification explicitly permits the exact additions.
8. Verify the completed change through CI and inspect the finished audit output, not merely the workflow's status indicator.

## Migration discipline

Work in small, independently reviewable batches. Use `git mv` for file moves, update imports in both `lib/` and `test/`, preserve class names and runtime behavior, and avoid unrelated formatting. Run the architecture audit and the full CI workflow after each batch. A batch is accepted only after its finished CI run is green and its audit/allowlist delta has been reviewed. Do not begin the next phase until the current batch is accepted.
