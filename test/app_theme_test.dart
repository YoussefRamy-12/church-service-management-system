import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:church_service_management_system/app/design/app_colors.dart';
import 'package:church_service_management_system/app/design/app_theme.dart';

void main() {
  test('Warm Navy theme builds in light and dark modes', () {
    final light = AppTheme.light;
    final dark = AppTheme.dark;

    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.extension<AppColors>(), isNotNull);
    expect(dark.extension<AppColors>(), isNotNull);
    expect(light.scaffoldBackgroundColor, AppDesignColors.lightCanvas);
    expect(dark.scaffoldBackgroundColor, AppDesignColors.darkCanvas);
  });

  test('semantic pairs and their theme-surface text meet WCAG AA', () {
    final themes = [
      (AppColors.light, AppDesignColors.lightCanvas, AppDesignColors.lightSurface),
      (AppColors.dark, AppDesignColors.darkCanvas, AppDesignColors.darkSurface),
    ];
    for (final (palette, canvas, surface) in themes) {
      for (final semantic in palette.semanticColors) {
        expect(AppColors.contrastRatio(semantic.foreground, semantic.background), greaterThanOrEqualTo(4.5));
        expect(AppColors.contrastRatio(semantic.foreground, canvas), greaterThanOrEqualTo(4.5));
        expect(AppColors.contrastRatio(semantic.foreground, surface), greaterThanOrEqualTo(4.5));
      }
    }
  });
}
