# Church Service Management — Design System Master

> **Canonical source:** [Root DESIGN.md](../../DESIGN.md)  
> **Screen-level UX specification:** [docs/ux-spec.md](../../docs/ux-spec.md)

This file is retained as a compatibility entry point for tools and workflows that still look for `design-system/church-service-management/MASTER.md`.

## Authority

The repository-root `DESIGN.md` is the single source of truth for:
- Warm Navy light and dark color tokens and verified contrast ratios
- Cairo / IBM Plex Sans Arabic type scale
- Spacing, density, radii and elevation
- Button, input, card, chip, list tile, bottom navigation and app bar specifications
- Semantic status colors, icons and Arabic labels
- RTL, accessibility, motion and visual anti-patterns

The root `docs/ux-spec.md` defines the six screen wireframes, responsive notes, primary actions, loading/empty/error/offline states and tap-count targets.

## Non-overridable rules

1. Do not define a second palette, typography scale, spacing system, component system or page pattern in this file.
2. If this file appears to conflict with root `DESIGN.md`, root `DESIGN.md` wins.
3. If a screen-level implementation question is not answered by root `DESIGN.md`, consult `docs/ux-spec.md`; do not revive the old purple/lavender palette or editorial landing-page patterns.
4. This project is an authenticated church-service operations workspace, not a public marketing landing page. Do not add testimonials, hero conversion sections, decorative purple/gold themes, gradients, glass, blur or layered shadows.
5. UI redesign is presentation-only. Existing routes, business logic, repositories, Drift schema, sync behavior, Supabase behavior, role permissions and widget/test keys must remain intact.

## Status

Task 0 proposal — awaiting owner approval. No Dart implementation is authorized by this file.
