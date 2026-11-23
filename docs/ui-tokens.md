# UI Tokens and Shared Components

This guide is the implementation reference for the Warm Navy design system. The canonical visual contract remains DESIGN.md.

## Theme setup

Use the provided theme at the app boundary:

~~~dart
MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: themeMode,
)
~~~

Theme entry points remain available through lib/app/theme.dart:
- buildAppTheme() — light theme
- buildAppDarkTheme() — dark theme
- Existing palette names remain available as deprecated aliases.

## Color usage

Use Material roles for general interface colors:

~~~dart
final scheme = Theme.of(context).colorScheme;
Container(color: scheme.surface);
Text('عنوان', style: Theme.of(context).textTheme.titleLarge);
~~~

Use AppColors only for semantic states:

~~~dart
final statusColors = AppColors.of(context).present;
Icon(Icons.check_circle, color: statusColors.foreground);
DecoratedBox(decoration: BoxDecoration(color: statusColors.background));
~~~

Semantic foreground/background pairs (present, absent, late, excused, pending, synced, conflict, warning and accent) are tested against WCAG AA.

## Spacing, shape and typography

- AppSpacing: 4, 8, 12, 16, 24 and 32 logical pixels.
- AppRadii.card: 12; AppRadii.control: 14; AppRadii.chip: 999; bottom sheet: 16.
- AppTypography: Cairo for headings; IBM Plex Sans Arabic for body, labels and numbers.
- Body font fallback is Cairo, then Arial. Heading fallback is IBM Plex Sans Arabic, then Arial.
- Use EdgeInsetsDirectional, AlignmentDirectional and other directional APIs for RTL.

## Responsive layout

BuildContext exposes isMobile, isTablet, isDesktop and adaptivePagePadding.
MaxWidthContainer centers content and applies the 16 / 24 / 32px horizontal page padding.

## Shared components

Import package:church_service_management_system/app/ui/components/app_components.dart.

- StatusChip(status: AppStatus.present): icon + Arabic label + semantic color.
- EmptyState(icon:, title:, message:, action:): empty content and optional next step.
- ErrorState(message:, onRetry:): explicit retry.
- SyncBadge(state:, count:, onTap:): sync status; pending count is optional.
- AppSectionHeader(title:, subtitle:, action:): section hierarchy.
- AppListTile(title:, subtitle:, leading:, trailing:, onTap:): RTL-safe row, minimum 56px.

Use AppSurface and AppCard from app_ui.dart for opaque, flat surfaces. The deprecated AmbientBackground and GlassContainer wrappers exist only to preserve existing call sites; blur and opacity are ignored.

## Font assets

IBM Plex Sans Arabic Regular, Medium, SemiBold and Bold are bundled under assets/fonts and registered in pubspec.yaml. The upstream SIL Open Font License is included alongside the font files.

## Feature-code color rule

**No Color(0x...) in feature code.** Feature widgets must use Theme.of(context).colorScheme, Theme.of(context).textTheme, or AppColors.of(context) for semantic states. Literal palette values belong only in lib/app/design/.
