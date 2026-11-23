import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/domain/entities/app_settings.dart';
import '../features/settings/presentation/settings_providers.dart';
import 'design/app_colors.dart';
import 'design/app_theme.dart';

export 'design/app_colors.dart';

// Deprecated compatibility aliases. New code should use ColorScheme or AppColors.
@Deprecated('Use Theme.of(context).scaffoldBackgroundColor.')
const appCanvas = AppDesignColors.lightCanvas;
@Deprecated('Use Theme.of(context).colorScheme.surface.')
const appSurface = AppDesignColors.lightSurface;
@Deprecated('Use AppSurface; translucent surfaces are no longer part of the design system.')
const appSurfaceGlass = AppDesignColors.lightSurface;
@Deprecated('Use Theme.of(context).colorScheme.primary.')
const appPrimary = AppDesignColors.primary;
@Deprecated('Use Theme.of(context).colorScheme.primaryContainer.')
const appPrimaryContainer = AppDesignColors.primaryContainer;
@Deprecated('Use Theme.of(context).colorScheme.secondary.')
const appSecondary = AppDesignColors.lightGold;
@Deprecated('Use Theme.of(context).colorScheme.secondaryContainer.')
const appSecondaryContainer = Color(0xFFF4E5C1);
@Deprecated('Use Theme.of(context).colorScheme.tertiary.')
const appTertiary = Color(0xFF0F766E);
@Deprecated('Use AppColors.of(context).accent.')
const appAccentCyan = Color(0xFF5EEAD4);
@Deprecated('Use Theme.of(context).colorScheme.primaryContainer.')
const appAccentViolet = AppDesignColors.primaryContainer;
@Deprecated('Use Theme.of(context).colorScheme.surfaceContainerLow.')
const appSoftBlue = AppDesignColors.lightSurfaceSubtle;
@Deprecated('Use Theme.of(context).colorScheme.surfaceContainerHigh.')
const appMistBlue = AppDesignColors.lightBorderSubtle;
@Deprecated('Use Theme.of(context).colorScheme.onSurface.')
const appInk = AppDesignColors.lightInk;
@Deprecated('Use Theme.of(context).colorScheme.onSurfaceVariant.')
const appMutedInk = AppDesignColors.lightMutedInk;
@Deprecated('Use Theme.of(context).colorScheme.outlineVariant.')
const appBorder = AppDesignColors.lightBorder;
@Deprecated('Use Theme.of(context).colorScheme.outlineVariant.')
const appGlassBorder = AppDesignColors.lightBorder;
@Deprecated('Use AppColors.of(context).present.foreground.')
const appSuccess = Color(0xFF166534);
@Deprecated('Use AppColors.of(context).warning.foreground.')
const appWarning = Color(0xFF854D0E);
@Deprecated('Use Theme.of(context).colorScheme.error.')
const appError = AppDesignColors.lightError;

/// Builds the canonical light Warm Navy theme.
ThemeData buildAppTheme() => AppTheme.light;

/// Builds the canonical dark Warm Navy theme.
ThemeData buildAppDarkTheme() => AppTheme.dark;

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final settings = ref.watch(appSettingsProvider);
    return settings.themeMode.mode;
  }

  void toggleTheme() {
    final current = state;
    final next = current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(next);
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    final appMode = switch (mode) {
      ThemeMode.light => AppThemeMode.light,
      ThemeMode.dark => AppThemeMode.dark,
      ThemeMode.system => AppThemeMode.system,
    };
    ref.read(appSettingsProvider.notifier).setThemeMode(appMode);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
