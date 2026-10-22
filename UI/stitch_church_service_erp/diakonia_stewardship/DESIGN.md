---
name: Diakonia Stewardship
colors:
  surface: '#f8f9ff'
  surface-dim: '#ccdbf3'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e6eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d5e3fc'
  on-surface: '#0d1c2e'
  on-surface-variant: '#444651'
  inverse-surface: '#233144'
  inverse-on-surface: '#eaf1ff'
  outline: '#757682'
  outline-variant: '#c5c5d3'
  surface-tint: '#4059aa'
  primary: '#00236f'
  on-primary: '#ffffff'
  primary-container: '#1e3a8a'
  on-primary-container: '#90a8ff'
  inverse-primary: '#b6c4ff'
  secondary: '#904d00'
  on-secondary: '#ffffff'
  secondary-container: '#fe932c'
  on-secondary-container: '#663500'
  tertiary: '#003120'
  on-tertiary: '#ffffff'
  tertiary-container: '#004a32'
  on-tertiary-container: '#4ac08f'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dce1ff'
  primary-fixed-dim: '#b6c4ff'
  on-primary-fixed: '#00164e'
  on-primary-fixed-variant: '#264191'
  secondary-fixed: '#ffdcc3'
  secondary-fixed-dim: '#ffb77d'
  on-secondary-fixed: '#2f1500'
  on-secondary-fixed-variant: '#6e3900'
  tertiary-fixed: '#85f8c4'
  tertiary-fixed-dim: '#68dba9'
  on-tertiary-fixed: '#002114'
  on-tertiary-fixed-variant: '#005137'
  background: '#f8f9ff'
  on-background: '#0d1c2e'
  surface-variant: '#d5e3fc'
typography:
  display-lg:
    fontFamily: IBM Plex Sans
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 48px
  headline-lg:
    fontFamily: IBM Plex Sans
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 38px
  headline-lg-mobile:
    fontFamily: IBM Plex Sans
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 30px
  headline-md:
    fontFamily: IBM Plex Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm:
    fontFamily: IBM Plex Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 26px
  body-lg:
    fontFamily: IBM Plex Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 26px
  body-md:
    fontFamily: IBM Plex Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 22px
  body-sm:
    fontFamily: IBM Plex Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 18px
  label-lg:
    fontFamily: IBM Plex Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  label-md:
    fontFamily: IBM Plex Sans
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  label-sm:
    fontFamily: IBM Plex Sans
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1.25rem
  gutter-mobile: 0.75rem
  margin: 2rem
  margin-mobile: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2.25rem
---

## Brand & Style

This design system serves church administration and pastoral care teams managing pastoral follow-ups, attendance rosters, family demographics, and spiritual service workflows. 

The aesthetic identity balances reverent institutional dignity with modern, warm operational clarity:
- **Design Movement:** Clean Modern Utility paired with subtle Tactile Hospitality. It rejects cold, clinical enterprise bureaucracy in favor of warm stone, parchment, and deep sapphire surfaces that feel orderly, welcoming, and permanent.
- **RTL-Native Ergonomics:** Built entirely for Right-to-Left (RTL) reading patterns, respecting Arabic typographic balance, proper icon mirroring, and natural eye flow from right to left across statistical summaries and record lists.
- **Audience & Emotional Response:** Designed for parish priests, service coordinators (أمناء الخدمة), and servant-leaders (الخدام). The UI must instill trust, pastoral care, and dependable efficiency during high-pressure liturgical service check-ins and offline field visits.

## Colors

The palette draws inspiration from sacred liturgical manuscripts, natural stone, and polished architectural woodwork.

### Core Roles
- **Primary (`#1E3A8A` - Royal Liturgical Navy):** Conveys stability, authority, and pastoral reassurance. Utilized for primary navigation bars, dominant call-to-action buttons, active tabular selections, and key metric emphases.
- **Secondary (`#D97706` - Warm Coptic Gold / Terracotta):** Represents warm fellowship, highlighted recognitions, feast day indicators, and primary milestone markers.
- **Tertiary (`#059669` - Sage Olive):** Designated for verified attendance, positive visitation logs, active servants, and online synchronization states.
- **Neutral (`#475569` - Slate Slate):** Provides balanced typographic legibility and stable neutral scaffolding across lines, subtitles, and subtle dividers.

### Canvas & Surface Hierarchy
- **Base Canvas (`#FAF9F6` - Warm Parchment):** Avoids stark, blinding white (#FFFFFF) in favor of a soft, reading-friendly parchment base that reduces glare during prolonged evening roster reviews.
- **Surface Elevation 1 (`#FFFFFF` - Crisp Card White):** Pure white container surfaces that lift records, forms, and profiles off the parchment background with crisp differentiation.
- **Surface Subdued (`#F1F5F9` - Muted Mist):** Subtle fill for disabled inputs, alternating row stripes, and secondary badge backings.

### Functional Status Indicators
- **Absence / Urgent Visitation Required (`#DC2626` - Crimson Brick):** Alerts, unreached members over 30 days, or dropped connections.
- **Syncing / Pending Approval (`#F59E0B` - Deep Amber):** Offline cache queues waiting for server sync, or service transitions awaiting clerical authorization.
- **Connected / Synced (`#059669` - Sage Olive):** Offline-first database fully synchronized.

## Typography

Typographic scale is optimized specifically for Arabic script legibility using **IBM Plex Sans** (with Arabic script support enabled via IBM Plex Sans Arabic). Arabic requires slightly more vertical breathing room than Latin typefaces due to ascenders, descenders, and tashkeel marks.

- **Line Height:** Line heights are relaxed to 1.5x–1.6x the font size across body copy to prevent cramped baselines in multi-line member notes and pastoral logs.
- **Numerical Treatment:** Eastern Arabic numerals (١، ٢، ٣) are supported for ceremonial dates and traditional liturgical calendars, while Western numerals (1, 2, 3) are styled consistently for quick accounting, attendance percentages, and mobile contact dialing.
- **Hierarchy Rules:** Section headings avoid harsh all-caps styling (non-existent in Arabic) and instead establish authority through clear weight steps (`700` for main parish view titles, `600` for roster grouping titles, and `400` for body demographics).

## Layout & Spacing

The layout employs an asymmetric, fluid 12-column grid anchored to the right edge:

- **Desktop (>= 1280px):** 12 columns with `2rem` outer page margins and `1.25rem` column gutters. Features a persistent right-hand navigation rail (260px fixed width) for service branches (الافتقاد، مدارس الأحد، الشباب، الخدام).
- **Tablet (768px - 1279px):** 8 columns with `1.5rem` margins and `1rem` gutters. Navigation collapses into an accessible RTL sliding drawer with quick tab switching for primary duty registers.
- **Mobile (< 768px):** 4 columns with `1rem` outer canvas padding and `0.75rem` column gaps. Critical action items (e.g., Quick Attendance Mark, Call Family) sit in a fixed bottom utility bar accessible by thumb.

RTL grid flow ensures visual priority moves from top-right to bottom-left: primary key indicators (Total Congregation, Attended Today, Unvisited Families) occupy the top-right quadrants of dashboard panels.

## Elevation & Depth

Visual hierarchy combines warm, low-contrast structural outlines with subtle ambient diffusion:

- **Surface Base:** The canvas rests at `#FAF9F6`. Cards sit atop the canvas with `#FFFFFF` background fills framed by a hairline border (`1px solid #E2E8F0`).
- **Ambient Shadow (Resting State):** `box-shadow: 0 1px 3px 0 rgba(30, 58, 138, 0.04), 0 1px 2px -1px rgba(30, 58, 138, 0.04);` — Tinted slightly with navy rather than pure black to preserve warmth.
- **Raised Interactive State (Hover/Focus):** `box-shadow: 0 4px 12px -2px rgba(30, 58, 138, 0.08), 0 2px 6px -1px rgba(30, 58, 138, 0.04);` with a subtle vertical translate of `-1px`.
- **Modals & Overlays:** `box-shadow: 0 20px 25px -5px rgba(15, 23, 42, 0.12), 0 8px 10px -6px rgba(15, 23, 42, 0.08);` alongside a warm dimming backdrop (`rgba(30, 41, 59, 0.4)` with 4px backdrop blur).
- **Tabular Elevation:** Data tables do not stack elevations; they rely on crisp `1px` horizontal borders (`#F1F5F9`) and a sticky header pinned with `#FAF9F6` and a crisp lower divider (`#CBD5E1`).

## Shapes

The system uses a balanced rounded geometry (level 2) to maintain institutional seriousness without sharp, intimidating edges.

- **Base Radius (0.5rem / 8px):** Applied to form inputs, table container outlines, dropdown panels, and action buttons.
- **Card Radius (1rem / 16px):** Applied to roster cards, family summary tiles, and modal dialogs.
- **Pill Radius (9999px / Full Round):** Reserved specifically for attendance chips, status tags (حاضر، غائب، تم الافتقاد), offline-sync status indicators, and avatar badges.
- **Icon Enclosures:** Icon buttons and status dots utilize squircular or full-pill enclosures to create soft focal points inside dense statistical views.

## Components

### Buttons
- **Primary:** Background `#1E3A8A`, text `#FFFFFF`, rounded 8px (`0.5rem`). High tactile feedback with a slight darkening (`#172554`) on hover and active scale press (`transform: scale(0.98)`).
- **Secondary / Action:** Outlined with `1px solid #CBD5E1`, background `#FFFFFF`, text `#1E3A8A`. Hover brings `#F8FAFC` fill with `#1E3A8A` border.
- **Tertiary Liturgical Gold:** Background `#D97706`, text `#FFFFFF`. Used for celebratory actions (e.g., "Add Pastoral Milestone", "Feast Registry").
- **RTL Icon Placement:** Leading icons are placed on the right of the Arabic label; trailing indicator icons are placed on the left.

### Inputs & Form Fields
- Surface background `#FFFFFF` with `1px solid #CBD5E1`.
- Focus state reveals a `2px` focus ring in `#1E3A8A` with a 2px offset.
- Floating Arabic labels animate neatly above the right border line.
- Explicit right-aligned placeholder text with contextual icons anchored to the inner right edge (e.g., search icon, calendar icon).

### Status Indicators & Offline Banners
- **Offline-First Connectivity Pill:**
  - *Online / Synced:* Background `#ECFDF5`, text `#065F46`, border `#A7F3D0` with a steady `#059669` green dot.
  - *Syncing / In Queue:* Background `#FFFBEB`, text `#92400E`, border `#FDE68A` with an animated pulse on a `#F59E0B` amber dot.
  - *Offline:* Background `#FEF2F2`, text `#991B1B`, border `#FECACA` with a `#DC2626` red dot and item count badge (e.g., "غير متصل - ٣ تعديلات معلقة").

### Cards & Pastoral Rosters
- Pure white container (`#FFFFFF`) with 16px border-radius, framed by a soft border (`#E2E8F0`).
- Header displays member/family primary name in `headline-sm`, complemented on the left by attendance pill tags.
- Direct-action buttons (Call WhatsApp, Log Visitation, Note Prayer Requests) sit along the bottom card footer with distinct divider separation.

### Attendance Check-in Lists
- Compact row height (56px) for fast thumb tapping.
- Dual-action split switch: Right side triggers green checkmark (حاضر), Left side triggers crimson alert (غائب/يحتاج افتقاد).
- Row background transitions softly to `#F0FDF4` when checked in, providing immediate visual confirmation during busy liturgy arrivals.