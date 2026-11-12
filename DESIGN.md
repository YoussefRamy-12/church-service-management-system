---
name: Diakonia Stewardship
description: Crisp, restrained Arabic-first operations workspace for church service management. High information density, quiet surfaces, and disciplined typography.
colors:
  primary: "#00236F"
  primary-container: "#1E3A8A"
  canvas: "#F8F9FF"
  surface: "#FFFFFF"
  surface-subtle: "#F1F4FA"
  ink: "#0D1C2E"
  ink-muted: "#444651"
  border: "#C5C5D3"
  border-subtle: "#E2E8F0"
  success: "#059669"
  warning: "#904D00"
  error: "#DC2626"
  dark-canvas: "#0B1120"
  dark-surface: "#131D33"
  dark-surface-subtle: "#1E293B"
  dark-ink: "#F8FAFC"
  dark-ink-muted: "#94A3B8"
  dark-border: "#334155"
typography:
  display:
    fontFamily: "Cairo, IBM Plex Sans, Arial, sans-serif"
    fontSize: "1.75rem"
    fontWeight: 800
    lineHeight: 1.2
    letterSpacing: "-0.02em"
  headline:
    fontFamily: "Cairo, IBM Plex Sans, Arial, sans-serif"
    fontSize: "1.375rem"
    fontWeight: 800
    lineHeight: 1.25
    letterSpacing: "-0.01em"
  title:
    fontFamily: "Cairo, IBM Plex Sans, Arial, sans-serif"
    fontSize: "1.125rem"
    fontWeight: 700
    lineHeight: 1.35
  body:
    fontFamily: "Cairo, IBM Plex Sans, Arial, sans-serif"
    fontSize: "0.9375rem"
    fontWeight: 400
    lineHeight: 1.6
  label:
    fontFamily: "Cairo, IBM Plex Sans, Arial, sans-serif"
    fontSize: "0.8125rem"
    fontWeight: 600
    lineHeight: 1.4
rounded:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  pill: "999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "32px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "#FFFFFF"
    rounded: "{rounded.sm}"
    height: "44px"
    padding: "0 20px"
  button-primary-hover:
    backgroundColor: "{colors.primary-container}"
  button-secondary:
    backgroundColor: "transparent"
    textColor: "{colors.primary}"
    rounded: "{rounded.sm}"
    height: "44px"
    padding: "0 18px"
  card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.md}"
    padding: "18px"
  input-text:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.sm}"
    height: "44px"
    padding: "0 14px"
---

# Design System: Diakonia Stewardship

## Overview

Diakonia Stewardship is a purpose-built Arabic RTL operations environment designed for church service management, attendance check-in, student records, and spiritual care. Operating in Impeccable's **Operate** mode, the interface prioritizes immediate scanability, dense information display, high legibility under varying church ambient light conditions, and zero unnecessary visual distraction.

The tool disappears into the task: servants should never hesitate or struggle to find check-in buttons, student attendance status, or follow-up notes.

## Colors

### Surface Hierarchy
- **Canvas (`#F8F9FF` light / `#0B1120` dark)**: Quiet, cool foundation that provides contrast without eye fatigue.
- **Surface (`#FFFFFF` light / `#131D33` dark)**: Clean, opaque functional panels, cards, dialogs, and navigation containers.
- **Subtle Inset (`#F1F4FA` light / `#1E293B` dark)**: Table headers, filter pill backgrounds, and secondary control areas.

### Brand and State Accents
- **Brand Navy (`#00236F`)**: Primary actions, active selected navigation states, major section titles.
- **Container Navy (`#1E3A8A`)**: Active hover states and compact emphasis.
- **Success (`#059669`)**: Present attendance, approved students, synced state. Always accompanied by text or icon.
- **Warning / Attention (`#904D00`)**: Pending approval, delayed submission, attention needed.
- **Error / Urgent (`#DC2626`)**: Absence alerts, sync conflicts, destructive actions.
- **Focus Ring (`#4F46E5` / `#818CF8`)**: High-visibility focus indicators with 2px width and offset.

## Typography

The type system is strictly Arabic-first, utilizing Cairo and IBM Plex Sans with clean operating system sans-serif fallbacks.

- **Display (28px / 1.75rem, w800)**: Page titles and prominent milestone metrics.
- **Headline (22px / 1.375rem, w800)**: Section titles and dashboard headers.
- **Title (18px / 1.125rem, w700)**: Card titles, dialog headers, and roster group names.
- **Body (15px / 0.9375rem, w400/w500)**: Form input fields, table data, body descriptions (line height 1.6).
- **Label / Meta (12-13px / 0.8125rem, w600)**: Badges, column headers, timestamps, and secondary status text.

## Layout

- **Right-to-Left (RTL)**: All directional layout follows native Arabic RTL reading flow.
- **Desktop Navigation Rail (280px)**: Persistent right-hand navigation rail on screens >= 1100px.
- **Header Bar (60px)**: Sticky top bar containing breadcrumbs, active service context, sync status widget, and profile menu.
- **Responsive Breakpoints**:
  - Desktop: >= 1100px (persistent right rail, multi-column metric grids, full table views).
  - Tablet: 768px - 1099px (compact rail or bottom bar, 2-column grids).
  - Mobile: < 768px (drawer navigation, single-column stacked layout, full-width primary CTAs).

## Elevation & Depth

Impeccable operates on **hairline borders first before shadows**:
- Surfaces rest on subtle 1px borders (`#E2E8F0` light, `#1E293B` dark).
- Shadows are reserved for floating overlays (dialogs, dropdown menus, tooltips) with realistic vertical offsets and soft blurs (e.g. `0 4px 16px rgba(15, 23, 42, 0.08)`).
- **Zero-offset colored halos and blur filters are strictly prohibited**. Cards and panels are solid, crisp surfaces.

## Shapes

- **Base Radius**: 12px for standard cards, dialogs, and panels.
- **Controls**: 8px radius for text inputs, buttons, and dropdowns.
- **Badges & Chips**: Pill-shaped (999px radius) for status indicators and filter tokens.

## Components

### Buttons
- **Primary**: Solid brand navy fill (`#00236F`), white bold text, 44px minimum touch height, 8px radius.
- **Secondary / Outlined**: Transparent background, 1px `#C5C5D3` border, brand navy text.
- **Text Button**: Borderless, padded tap target (minimum 44x44px).

### Cards & Panels
- Solid opaque background with crisp 1px border. No nested cards inside cards.
- Content groupings use dividers or spacing rhythm (16-24px) rather than sub-card containers.

### Status Badges
- Pill container with 10% tinted background of the semantic color and 1px border.
- Solid 6px dot indicator (without glow/halo) alongside clear Arabic text.

### Feedback & State
- **Loading**: Structured skeleton placeholders matching destination layout geometry, never floating spinners.
- **Empty States**: Clear icon, direct explanation title, concise description of why it is empty, and an immediate primary action button to create or import.

## Do's and Don'ts

### Do
- Do prioritize fast door attendance and check-in workflows.
- Do keep borders subtle (1px) and surfaces opaque.
- Do use paired dual-channel indicators (color + text or icon) for every operational state.
- Do maintain consistent 8px/16px/24px spacing rhythms across all pages.
- Do provide accessible 44x44px minimum tap targets on all interactive elements.

### Don'ts
- Don't use decorative glassmorphism, blur effects, or zero-offset colored glow halos.
- Don't nest cards inside cards.
- Don't place kicker or eyebrow labels above headings. Let the heading speak directly.
- Don't use thick asymmetric colored borders (`border-left` or `border-right` > 1px).
- Don't rely on color alone to communicate attendance or sync status.
- Don't use generic AI-tool purple-to-blue gradients or neon accents.

