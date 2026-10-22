# Stitch Design System — Diakonia Stewardship

This is the implementation source of truth for the Arabic RTL church service management application. It is distilled from the supplied Stitch screens in `UI/stitch_church_service_erp/`. Keep real application behavior and data connected to the existing repositories; use the Stitch files as visual references, not as static screens.

## Product direction

An Arabic-first, desktop-oriented service operations workspace for attendance, student care, servant assignments, approvals, reports, and service structure. The visual language is calm, precise, and information-dense enough for door check-in. Keep the interface RTL, keep primary actions easy to find, and make operational status legible without relying on color alone.

## Visual tokens

| Role | Value | Usage |
|---|---|---|
| Canvas | `#F8F9FF` | Main page background |
| Surface | `#FFFFFF` | Header, side navigation, forms, tables, cards |
| Brand navy | `#00236F` | Main actions, headings, key emphasis |
| Selected navy | `#1E3A8A` | Active sidebar item and compact emphasis |
| Pale blue | `#EFF4FF` | Filter groups, soft callouts, selected backgrounds |
| Mist blue | `#DCE9FF` | Progress tracks and subtle state backgrounds |
| Ink | `#0D1C2E` | Main text |
| Muted ink | `#444651` | Secondary text and labels |
| Border | `#C5C5D3` | Inputs and quiet panel outlines |
| Success | `#059669` | Present, approved, synced |
| Amber | `#904D00` | Pending, early, and attention states |
| Error | `#DC2626` | Urgent absence, destructive, or disconnected states |

Success, amber, and error colors are semantic. Pair every state color with text or an icon. Avoid heavy shadows, gradients, pure black, and decorative animation.

## Typography and geometry

- Use Cairo for Arabic and IBM Plex Sans for mixed Latin copy when available; retain the operating system Arabic sans-serif fallback so pages work offline.
- Page titles: 22–28 px, bold. Section titles: 18–20 px, semibold/bold. Body: 14–16 px. Metadata: 11–12 px.
- Use an 8 px spacing rhythm. Cards and major panels use 16 px corners; controls use 8–12 px corners; status chips are pill-shaped.
- Content uses directional Flutter layout APIs and right alignment for Arabic. Avoid fixed-width content except the desktop navigation rail.

## Global shell

- Desktop: a 288 px white right-hand rail, a 64 px white top bar, and a fluid `#F8F9FF` content canvas.
- Sidebar: compact brand mark and service identity, section label, icon-led links, a clear navy active pill, sync state, and user identity at the bottom.
- Top bar: current page and service context, sync/network status, service switch for super admins, and a compact user menu.
- Below 1100 px, replace the persistent rail with the accessible navigation sheet; on narrow screens, use 16 px page gutters and full-width primary actions.
- Navigation visibility follows role capabilities, but direct route access must still use the existing authorization rules.

## Page patterns

- **Dashboard:** welcome and service identity; attendance CTA; high-priority attendance summary; compact metric tiles; attendance trend and class status; follow-up/approval alerts; dense roster table. Use varied hierarchy instead of a uniform card grid.
- **Student and servant directories:** page title and primary create action; search and grouped filters; compact rows with identity, relevant stage/class/role, status, and direct view/edit actions. Provide explicit empty, loading, and error treatments.
- **Profiles and forms:** group long forms into labeled sections; show required fields clearly; keep save/cancel actions together and reachable on mobile. Student registration covers identity, family/guardian, school, health, and pastoral notes. Servant profiles emphasize role, assignment, and account state.
- **Attendance:** meeting context and online/offline state first; large search and class/stage/all-student filters; 56–64 px roster rows and a clear present state; QR scan remains a focused full-screen camera workflow with recent scan feedback and a visible close control.
- **Follow-up:** weekly focus and absence priority first, then student follow-up entry and history with dated outcomes.
- **Reports and exports:** filters at the top, summary metrics, charts/tables, then explicit preview/export actions and progress feedback.
- **Settings:** service, stages/classes, service year, and system settings use sectioned white panels with concise helper text and contextual create/edit/delete actions.
- **System feedback:** skeletons match expected page structure; empty states explain the next step; errors offer retry where possible; destructive actions use confirmation; sync status names the state and pending count.

## Stitch references

Primary dashboard: `_19`; directory: `_14`, `_11`; attendance: `_4`, `qr_1`, `qr_2`; student forms/profile: `_21`, `_5`, `_8`; servant profile/approvals: `_6`, `_1`, `_23`; follow-up: `_2`, `_10`, `_18`; reporting/export: `_7`, `_16`, `_20`; sync/settings: `_3`, `_13`, `_15`, `_12`. Smaller screen variants should keep the same tokens and prioritize the primary action and current record.
