# Implementation Notes: Church Service Management

The canonical Stitch-aligned specification is [DESIGN.md](DESIGN.md). Keep these implementation notes consistent with that specification; when the two differ, `DESIGN.md` and the supplied Stitch screen references are the design source of truth.

## 1. Visual Theme and Atmosphere

Use a calm, service-focused administrative workspace: balanced information density, clear Arabic-first hierarchy, and enough warmth to feel pastoral without sacrificing fast daily operations. The interface is RTL by default. Keep the desktop navigation on the right, align names and Arabic copy naturally, and preserve compact rosters for check-in work.

## 2. Color Palette and Roles

- **Soft Blue Canvas** (`#F8F9FF`) — app background and open page areas.
- **Clear White Surface** (`#FFFFFF`) — forms, roster panels, dialogs, and raised content.
- **Royal Navy** (`#00236F`) — the single brand accent for primary actions, selected navigation, and key emphasis.
- **Navy Container** (`#1E3A8A`) — selected navigation and emphasized surface treatment.
- **Pale Mist** (`#EFF4FF`) — filter panels, secondary information, and subdued controls.
- **Blue Tint** (`#DCE9FF`) — soft selected states, dividers, and progress tracks.
- **Slate Ink** (`#0D1C2E`) — primary text; **Muted Slate** (`#444651`) — supporting text.
- **Coptic Amber** (`#904D00`) — semantic pending, early-attendance, or milestone status only.
- **Sage Green** (`#059669`) — semantic present, successful, and synced status only.
- **Brick Red** (`#DC2626`) — semantic urgent absence, error, or disconnected status only.
- **Soft Border** (`#C5C5D3`) — input outlines and quiet structural borders.

Amber, sage, and red are status colors, not competing brand accents. Never use a neon glow or pure black.

## 3. Typography Rules

- Prefer **Cairo** for Arabic-first interface copy and **IBM Plex Sans** for mixed Arabic and Latin labels when those fonts are available.
- Use the system Arabic sans-serif fallback when custom fonts are unavailable so the app remains usable offline.
- Page titles: 22–28 px, weight 700. Section titles: 18–20 px, weight 600–700. Body: 14–16 px with relaxed line height. Metadata: 11–12 px.
- Keep long instructional copy to readable line lengths and do not use large display type in dense administration screens.

## 4. Component Styling

- **Primary buttons:** navy fill, white text, 8–12 px corner radius, minimum 44 px touch height. Secondary actions use white fill, a soft border, and navy text.
- **Cards and panels:** white with a 1 px navy-tinted border, 14–16 px corners, no heavy shadow. Use pale blue panels for grouped filters and supporting details.
- **Inputs:** label above, white background, soft outline, navy focus border, validation below the field.
- **Status chips:** fully rounded, with a semantic pale background and readable foreground. Always pair color with text or an icon.
- **Rosters:** RTL alignment, compact rows around 56–64 px for attendance, faint horizontal dividers, and a light green checked-in state.
- **Loading:** use placeholders or progress that reflects the content layout. **Empty and error states:** explain what happened and offer a clear next action.

## 5. Layout and Responsive Behavior

- Desktop: fixed right rail around 260 px, slim white top bar, and a fluid content area constrained to a comfortable reading width.
- Tablet: replace the rail with an accessible navigation drawer.
- Mobile: single-column content, 16 px page gutters, full-width primary actions, no horizontal overflow, and touch targets at least 44 px high.
- Use directional padding and alignment APIs in Flutter (`EdgeInsetsDirectional`, `AlignmentDirectional`) for RTL/LTR-safe layout.
- Maintain consistent 8 px spacing increments; use 16 px panel corners and 8–12 px control corners.

## 6. Motion and Interaction

- Keep transitions restrained: short fades or small position changes for route and selection feedback.
- Buttons and list rows provide immediate pressed/selected feedback. Do not make essential status depend on animation.
- Prefer animating opacity and transforms; avoid continuous decorative motion in check-in screens.

## 7. Anti-Patterns

- No LTR-only layout assumptions or mirrored directional icons left uncorrected.
- No invented data presented as live data; demo values must be clearly marked.
- No giant gradients, neon glows, pure black, or decorative animations that distract from attendance entry.
- No equal-card dashboard grid when a varied hierarchy better reflects importance.
- No color-only status; label every state.
- No new feature that is only a static mockup when the app already has a matching route and repository workflow.
