---
name: Diakonia Stewardship — Warm Navy
description: Arabic-first, offline-first church service operations interface. Warm, calm, restrained, high-contrast and optimized for fast attendance at the church door.
direction: RTL
platform: Flutter Web
---

# Design System — Warm Navy

**Status:** Task 0 design proposal — awaiting approval  
**Canonical source:** This file is the design-token and component contract for implementation. `docs/ux-spec.md` defines screen behavior and responsive composition.  
**Scope:** Light and dark themes; mobile-first interaction with compact desktop density. This document supersedes older visual guidance in `UI/DESIGN.md` and `design-system/church-service-management/MASTER.md`.

## 1. Design principles

1. **Warm Navy:** brand navy anchors actions and navigation; warm off-white reduces the clinical feel of a conventional admin dashboard.
2. **Task-first:** attendance check-in is the highest-frequency operational workflow. Keep the next action visible, thumb-reachable and unambiguous.
3. **Flat, quiet surfaces:** opaque surfaces, 1px borders and one restrained elevation level. No gradients, glows, glassmorphism, backdrop blur or decorative shadows.
4. **Meaningful gold:** gold is reserved for meaningful highlights, milestones and spiritual-notebook features. It is not a generic accent or decoration.
5. **Arabic-first RTL:** Arabic reading order, directional layout, and mirrored directional icons. Numbers remain legible and consistently aligned.
6. **Offline trust:** distinguish local availability, queued changes, successful sync and conflicts. Never imply a remote write succeeded when it is only queued locally.
7. **Accessible by default:** WCAG AA text contrast, visible focus, keyboard access and minimum 44×44px interactive targets. Status always has color, icon and Arabic text.

## 2. Color tokens

### 2.1 Light theme

| Token | Hex | Intended use |
|---|---|---|
| `canvas` | `#FAF8F4` | Main page background |
| `surface` | `#FFFFFF` | Cards, inputs, sheets and navigation surfaces |
| `surface-subtle` | `#F1EEE7` | Quiet grouping, table headers and secondary control backgrounds |
| `ink` | `#17243A` | Primary text and headings |
| `ink-muted` | `#46515F` | Supporting text, labels and metadata |
| `border` | `#D6D0C5` | Standard 1px surface/control border |
| `border-subtle` | `#E8E3DA` | Low-emphasis separators |
| `primary` | `#00236F` | Primary buttons, selected navigation, links and key actions |
| `primary-container` | `#1E3A8A` | Hover and pressed container; selected/active container |
| `on-primary` | `#FFFFFF` | Text and icons on primary |
| `gold` | `#B8860B` | Meaningful highlight/milestone/spiritual-notebook accent only |
| `error` | `#B91C1C` | Destructive and error semantics |
| `focus` | `#1E3A8A` | 2px keyboard focus indicator |

### 2.2 Dark theme

| Token | Hex | Intended use |
|---|---|---|
| `canvas` | `#0B1120` | Main page background |
| `surface` | `#131D33` | Cards, inputs, sheets and navigation surfaces |
| `surface-subtle` | `#1E293B` | Quiet grouping, table headers and secondary control backgrounds |
| `ink` | `#F8FAFC` | Primary text and headings |
| `ink-muted` | `#C0CAD8` | Supporting text, labels and metadata |
| `border` | `#334155` | Standard 1px surface/control border |
| `border-subtle` | `#26344B` | Low-emphasis separators |
| `primary` | `#00236F` | Primary buttons and key actions |
| `primary-container` | `#1E3A8A` | Hover and pressed container; selected/active container |
| `on-primary` | `#FFFFFF` | Text and icons on primary |
| `gold` | `#C9A227` | Meaningful highlight/milestone/spiritual-notebook accent only |
| `error` | `#F87171` | Destructive and error semantics |
| `focus` | `#93C5FD` | 2px keyboard focus indicator on dark surfaces |

**Brand behavior:** `#00236F` remains the primary brand color in both themes. `#1E3A8A` is its hover/pressed container in both themes. Do not replace the dark-theme brand with violet, cyan or a brighter unrelated blue.

### 2.3 Contrast verification

Ratios below are calculated using the WCAG 2.x relative-luminance formula. Values are rounded to two decimals. Text must meet **4.5:1**; large text and meaningful non-text controls must meet **3:1**.

| Foreground | Background | Ratio | Result |
|---|---|---:|---|
| Light ink `#17243A` | Light canvas `#FAF8F4` | 14.65:1 | AAA |
| Light muted ink `#46515F` | Light canvas `#FAF8F4` | 7.61:1 | AAA |
| Light muted ink `#46515F` | Light surface `#FFFFFF` | 8.07:1 | AAA |
| Primary `#00236F` | Light canvas `#FAF8F4` | 13.47:1 | AAA |
| White `#FFFFFF` | Primary `#00236F` | 14.29:1 | AAA |
| White `#FFFFFF` | Primary container `#1E3A8A` | 10.36:1 | AAA |
| Dark ink `#F8FAFC` | Dark canvas `#0B1120` | 18.00:1 | AAA |
| Dark muted ink `#C0CAD8` | Dark canvas `#0B1120` | 11.37:1 | AAA |
| Dark muted ink `#C0CAD8` | Dark surface `#131D33` | 10.13:1 | AAA |
| White `#FFFFFF` | Primary `#00236F` | 14.29:1 | AAA |
| White `#FFFFFF` | Primary container `#1E3A8A` | 10.36:1 | AAA |
| Gold `#B8860B` | Light canvas `#FAF8F4` | 3.07:1 | Large/icon-only use; not body text |
| Dark navy `#0D1B2A` | Light gold `#B8860B` | 5.34:1 | AA |
| Gold `#C9A227` | Dark canvas `#0B1120` | 7.78:1 | AAA |
| Gold `#C9A227` | Dark surface `#131D33` | 6.94:1 | AA |

**Gold accessibility rule:** light-theme gold `#B8860B` is not approved for small text on the warm canvas. Use it as a semantic icon, border, marker or highlight paired with normal-contrast text (`#17243A` or `#0D1B2A`). When gold is used as a filled highlight, use dark foreground `#0D1B2A`; its contrast is 5.34:1. Dark-theme gold `#C9A227` may be used for icons and text on the specified dark surfaces, subject to the semantic-only rule.

**Status contrast verification:** status foreground colors are tested against both the theme canvas and primary surface. Badge tint fills are decorative background tints only; status text and icon use the opaque foreground token.

| State | Light foreground | Light canvas | Light surface | Dark foreground | Dark canvas | Dark surface |
|---|---|---:|---:|---|---:|---:|
| Present | `#166534` | 6.72:1 | 7.13:1 | `#4ADE80` | 10.81:1 | 9.63:1 |
| Absent | `#B91C1C` | 6.10:1 | 6.47:1 | `#F87171` | 6.81:1 | 6.07:1 |
| Late | `#92400E` | 6.68:1 | 7.09:1 | `#FBBF24` | 11.28:1 | 10.05:1 |
| Excused | `#1D4ED8` | 6.32:1 | 6.70:1 | `#60A5FA` | 7.41:1 | 6.60:1 |
| Pending | `#854D0E` | 6.46:1 | 6.85:1 | `#FCD34D` | 13.06:1 | 11.64:1 |
| Synced | `#0F766E` | 5.16:1 | 5.47:1 | `#5EEAD4` | 12.73:1 | 11.35:1 |
| Conflict | `#B91C1C` | 6.10:1 | 6.47:1 | `#FB7185` | 7.00:1 | 6.24:1 |

## 3. Semantic status system

Every state is rendered as **color + icon + Arabic label**. Never communicate status with color or a dot alone. Use the same state meaning consistently across attendance, student approval and synchronization surfaces.

| State | Icon (Material equivalent) | Arabic label | Light token | Dark token |
|---|---|---|---|---|
| Present | `check_circle` | حاضر | `#166534` | `#4ADE80` |
| Absent | `cancel` | غائب | `#B91C1C` | `#F87171` |
| Late | `schedule` | متأخر | `#92400E` | `#FBBF24` |
| Excused | `info` | معتذر | `#1D4ED8` | `#60A5FA` |
| Pending | `hourglass_top` | قيد الانتظار | `#854D0E` | `#FCD34D` |
| Synced | `cloud_done` | تمت المزامنة | `#0F766E` | `#5EEAD4` |
| Conflict | `warning` | تعارض يحتاج مراجعة | `#B91C1C` | `#FB7185` |

- Badge: pill shape, 999px radius, 8px horizontal padding, 4px vertical padding; icon 16px; label 12–13px semibold; subtle state-tinted background and 1px state-tinted border.
- In dense desktop tables, the label may be visually compact but must remain present; do not remove it in favor of icon-only status.
- Attendance status and sync status are separate dimensions. A present record may still be pending sync.

## 4. Typography

**Arabic families**
- Headings: **Cairo**.
- Body, labels and numbers: **IBM Plex Sans Arabic**.
- Fallback order: Cairo, IBM Plex Sans Arabic, system Arabic sans-serif, Arial, sans-serif.
- Use tabular figures for counts, times and dates where supported. Keep Arabic labels in natural RTL order; isolate mixed Latin identifiers and email addresses.

| Role | Family | Size | Weight | Line height | Typical use |
|---|---|---:|---:|---:|---|
| Display | Cairo | 32px | 800 | 1.20 (38.4px) | Main dashboard metric/major page title; rare |
| Headline | Cairo | 26px | 700 | 1.25 (32.5px) | Screen title and major section heading |
| Title | Cairo | 20px | 700 | 1.35 (27px) | Card title, dialog title, roster group |
| Body | IBM Plex Sans Arabic | 16px | 400 | 1.50 (24px) | Default content and form values |
| Label | IBM Plex Sans Arabic | 14px | 600 | 1.35 (18.9px) | Buttons, field labels, table headings |
| Caption | IBM Plex Sans Arabic | 12px | 500 | 1.40 (16.8px) | Metadata, helper text, timestamps |

- Compact desktop density may reduce body to 14px and caption to 11px only for secondary table metadata; primary content and status labels stay at least 12px.
- Do not use light font weights for operational data.
- Do not use letter-spacing tricks to style Arabic text.

## 5. Spacing, density and layout

### 5.1 Spacing scale

| Token | Value |
|---|---:|
| `space-1` | 4px |
| `space-2` | 8px |
| `space-3` | 12px |
| `space-4` | 16px |
| `space-6` | 24px |
| `space-8` | 32px |

Use only these base increments for layout spacing. Component-specific optical adjustments may use half increments only when needed for icon alignment; do not introduce a competing scale.

### 5.2 Two density modes

| Property | Comfortable — mobile / door check-in | Compact — desktop tables |
|---|---|---|
| Content side padding | 16px | 24px (32px on wide canvas) |
| Card padding | 16px | 12–16px |
| Row minimum height | 56px | 44px |
| Interactive target | 48px preferred; never below 44×44px | Never below 44×44px |
| Input height | 48px | 44px |
| Button height | 48px | 44px |
| List separation | 8–12px | 4–8px |
| Primary text | 16px | 14–16px |
| Data presentation | Stacked, one clear action per row | Dense table with aligned columns |

Breakpoints:
- Mobile: < 768px — one-column composition; bottom navigation; comfortable density.
- Tablet: 768–1099px — responsive content; compact navigation only if space allows; no clipped tables.
- Desktop: >= 1100px — persistent right-side navigation; compact density for tables; content remains bounded and readable.

### 5.3 RTL rules

- Set the app direction to RTL at the app boundary.
- Use `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional` and directional border APIs.
- Mirror directional navigation icons (back, forward, chevron, send) for RTL. Do not mirror non-directional icons (check, search, calendar, QR).
- On mobile, place the primary thumb action in the lower reachable region when it is a repeated task. Do not place destructive actions beside primary actions.

## 6. Shape and elevation

| Element | Radius |
|---|---:|
| Cards and panels | 12px |
| Buttons and inputs | 14px |
| Chips and status badges | 999px |
| Bottom sheet top corners | 16px |
| Avatars | 999px |

**Elevation:** one subtle level only: `0 2px 8px rgba(15, 23, 42, 0.08)` in light theme and `0 2px 8px rgba(0, 0, 0, 0.24)` in dark theme. Reserve it for a single floating layer (e.g. menu or modal). Cards, navigation, inputs and normal page surfaces remain flat with 1px borders. No layered shadow stacks.

**Forbidden:** gradients, glows, glass effects, backdrop filters, blur, translucent cards, decorative halos, hover transforms that shift layout, and multiple elevation tiers.

## 7. Component specifications

### 7.1 Buttons

**Primary**
- Fill: `primary`; foreground: `on-primary`.
- Hover/pressed fill: `primary-container`; no opacity-only hover.
- Radius: 14px.
- Height: 48px comfortable / 44px compact; horizontal padding 16–20px.
- Label: 14px, weight 700; icon 18–20px with 8px gap.
- Loading: retain button width; show progress indicator and prevent duplicate submission.
- Disabled: neutral surface/border and clearly muted label; maintain readable contrast.

**Secondary / outlined**
- Transparent or surface fill; 1px border; foreground `primary`.
- Same height, radius and target as primary.
- Use for secondary actions only; avoid multiple competing filled buttons.

**Text / icon**
- Minimum hit area 44×44px; icon visual size 20–24px.
- Icon-only controls require an accessible tooltip/semantic label.

### 7.2 Inputs

- Height: 48px comfortable / 44px compact; radius 14px; 1px border.
- Fill: theme surface; text: theme ink; hint/helper: theme muted ink.
- Horizontal padding: 12–16px; field label 14px semibold.
- Focus: 2px focus border/ring with no glow; error: semantic error border plus Arabic error text and icon.
- Keep labels visible when a value is entered; do not rely on placeholder-only labeling.
- Password visibility control and other suffix actions retain 44×44px hit areas.

### 7.3 Cards

- Surface fill; 1px border; 12px radius; 16px comfortable / 12–16px compact padding.
- Flat by default; no hover lift or shadow on ordinary cards.
- Use one card for one coherent content group. Avoid nested card-in-card layouts.
- Clickable cards expose a clear selected/focus state and the entire intended hit area.

### 7.4 Chips

- 999px radius; 1px border; compact horizontal padding 10px.
- Visual height 32–36px; interactive wrapper hit area at least 44px high.
- Selected state: primary-container fill and white label; unselected state: subtle surface and ink.
- Status chips follow the semantic status table, not the brand palette.

### 7.5 List tile

- Comfortable minimum height 56px; compact minimum height 44px; never below 44px for an interactive row.
- Horizontal content padding 12–16px; icon 20–24px; title 14–16px; secondary line 12–14px.
- Keep title, key metadata and status in a stable scan order. Avoid excessive trailing actions.
- Whole-row activation is preferred for opening details; independent trailing controls must have separate 44px targets.

### 7.6 Bottom navigation

- Mobile only, fixed to the bottom safe area; opaque surface with a 1px top border.
- Height 64px excluding device safe-area inset.
- Four primary destinations: **الرئيسية، التلاميذ، الحضور، المزيد**. The More destination opens the complete role-filtered navigation list.
- Each destination has icon + visible Arabic label; active item uses primary color and a clear selected indicator. No icon-only bottom bar.
- Preserve the existing role-based visibility rules. Items hidden for a role remain hidden in More; do not create a second permission model.
- Attendance remains directly reachable in one tap from every authenticated mobile screen.
- On desktop, do not render bottom navigation; use the persistent right-side navigation rail/sidebar.

### 7.7 App bar

- Height 56px mobile / 64px desktop, plus system safe-area handling.
- Opaque surface, 1px bottom border, no blur or shadow.
- Screen title uses Cairo title/headline scale and is right-aligned for RTL.
- Mobile: title, optional menu/context action, sync state and profile affordance; avoid crowding.
- Desktop: title/context and account/system actions; navigation remains in the right rail.
- All icon actions have 44×44px targets and accessible labels.

## 8. Feedback and system states

Every data-driven screen must define:
- **Loading:** skeletons that match the final content geometry; avoid a full-screen spinner when cached data can render immediately.
- **Empty:** clear Arabic title, one-sentence explanation and a relevant primary CTA when the role is allowed to act.
- **Error:** concise Arabic explanation and explicit retry action. Keep already cached data visible where safe.
- **Offline:** persistent but quiet offline indicator; state whether displayed data is cached and whether writes are saved locally for later sync. Never present offline as an error if the local workflow is functioning.
- **Sync pending/conflict:** use the status system above and offer a next step where the user has permission to resolve it.

## 9. Motion

- Duration: 150–200ms for state changes only (selection, expansion, confirmation, loading completion).
- Use simple ease-out/ease-in curves; respect reduced-motion preferences.
- No entrance choreography, parallax, animated gradients, decorative looping motion, scale-on-hover or motion that delays attendance input.
- Press feedback may change surface color or border; do not shrink the hit target.

## 10. Non-negotiable implementation constraints

- This design system changes presentation only. Do not change business rules, repository behavior, Drift schema, sync queue semantics, Supabase behavior, route paths or role permissions as part of UI redesign.
- Preserve all existing widget/test keys, including `nav_logout`, `nav_switch_service` and other current keys.
- Keep light and dark themes equivalent in information hierarchy and component behavior.
- Mobile attendance check-in is the primary optimization target; desktop tables remain fully functional.
- Every status uses color + icon + Arabic label; every action remains keyboard accessible and has a visible focus state.
