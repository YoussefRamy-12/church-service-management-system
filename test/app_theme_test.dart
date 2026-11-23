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

  test('all semantic foreground/background pairs meet WCAG AA', () {
    for (final palette in [AppColors.light, AppColors.dark]) {
      for (final semantic in palette.semanticColors) {
        expect(
          AppColors.contrastRatio(semantic.foreground, semantic.background),
          greaterThanOrEqualTo(4.5),
        );
      }
    }
  });
}
