# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Primary users are church servants, class teachers, stage leaders, overall service coordinators (أمين الخدمة), and church administrators. They use the system during weekly service meetings, Sunday school sessions, door check-ins, and weekly pastoral follow-up.

## Product Purpose

An offline-first, Arabic-first service operations workspace (Diakonia Stewardship / نظام إدارة الخدمة الكنسية) for attendance tracking, student directory and records, servant assignments, spiritual notebook journaling (النوتة الروحية), weekly lesson preparation, pastoral follow-up, and service structure management.

## Positioning

A purpose-built, offline-first stewardship platform designed for the operational realities of church services: door attendance check-in, hierarchical stage and class management, spiritual growth tracking, and seamless synchronization when internet connectivity is intermittent.

## Operating Context

- Door check-in during fast-paced service arrivals via QR scanning or rapid roster taps.
- Classroom management by servants updating student attendance and spiritual progress.
- Mid-week follow-up phone calls and visits logged by servants.
- Leadership reviews of attendance trends, unassigned students, and pastoral care alerts.
- Offline environments with background two-way sync to Supabase when reconnected.

## Capabilities and Constraints

- **Language & Directionality**: Strictly Arabic RTL interface across all pages and dialogs.
- **Offline First**: Local SQLite / Drift database as the source of truth with background sync queues to Supabase.
- **Role-based Access Control**: System Admin, Overall Leader, Overall Helper, Stage Leader, Class Leader, Class Servant.
- **Responsive Layout**: Desktop-first layout with persistent right navigation rail (>= 1100px) and collapsible drawer on compact mobile screens.
- **High Data Density**: Roster tables, metric summaries, and batch actions requiring immediate scanability and high information density.

## Brand Commitments

- **Tone**: Respectful, calm, organized, and stewardship-focused.
- **Typography**: Arabic sans-serif (Cairo, IBM Plex Sans Arabic) with system fallback.
- **Structure**: Right-to-Left (RTL) navigation, tables, and forms.

## Product Principles

1. **Tool disappears into the task**: Minimize friction during live attendance and data entry; fast, responsive, zero-delay inputs.
2. **Scanability and legibility**: Clear hierarchical typography, high contrast, and distinct status indicators without relying solely on color.
3. **Restraint over decoration**: No gratuitous animations, no glowing decorative halos, no nested card soup. Every surface and border serves visual hierarchy.
4. **Reliable offline trust**: Clear indication of synced, pending, and conflict states with actionable resolution.

## Accessibility & Inclusion

- WCAG AA contrast compliance (minimum 4.5:1 for body and controls, 3:1 for large display elements).
- Fully accessible keyboard navigation and semantic touch targets (minimum 44x44px).
- Dual-channel status feedback: every state color is paired with a clear text label or dedicated icon.

