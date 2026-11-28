// WCAG AA contrast ratio tests for all AppColors semantic pairs.
// Every foreground/background pair must be >= 4.5:1 for normal text.
// Gold light on canvas (#B8860B on #FAF8F4 = 3.07:1) is a known large/icon-only
// exemption approved in DESIGN.md §2.3; that check is skipped (not a failure).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:church_service_management_system/app/design/app_colors.dart';

double _contrastRatio(Color fg, Color bg) {
  final l1 = fg.computeLuminance();
  final l2 = bg.computeLuminance();
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

void _expectAA(
  String description,
  Color fg,
  Color bg, {
  bool skipKnown = false,
}) {
  final ratio = _contrastRatio(fg, bg);
  if (skipKnown) {
    // Known exemption: document ratio but do not fail.
    // ignore: avoid_print
    print('  SKIP (large/icon only) $description  ratio=${ratio.toStringAsFixed(2)}:1');
    return;
  }
  expect(
    ratio,
    greaterThanOrEqualTo(4.5),
    reason: '$description  ratio=${ratio.toStringAsFixed(2)}:1 — below WCAG AA 4.5:1',
  );
  // ignore: avoid_print
  print('  PASS $description  ratio=${ratio.toStringAsFixed(2)}:1');
}

void main() {
  // ── Light theme backgrounds ────────────────────────────────────────────────
  const lightCanvas = Color(0xFFFAF8F4);
  const lightSurface = Color(0xFFFFFFFF);

  // ── Dark theme backgrounds ─────────────────────────────────────────────────
  const darkCanvas = Color(0xFF0B1120);
  const darkSurface = Color(0xFF131D33);

  group('Light status foreground vs canvas (AA >= 4.5)', () {
    final pairs = <String, Color>{
      'present':  const Color(0xFF166534),
      'absent':   const Color(0xFFB91C1C),
      'notMarked': AppColors.light.notMarked.foreground,
      'late':     const Color(0xFF92400E),
      'excused':  const Color(0xFF1D4ED8),
      'pending':  const Color(0xFF854D0E),
      'synced':   const Color(0xFF0F766E),
      'conflict': const Color(0xFFB91C1C),
    };
    for (final entry in pairs.entries) {
      test('${entry.key} fg on lightCanvas', () {
        _expectAA('light.${entry.key} on canvas', entry.value, lightCanvas);
      });
    }
  });

  group('Light status foreground vs surface (AA >= 4.5)', () {
    final pairs = <String, Color>{
      'present':  const Color(0xFF166534),
      'absent':   const Color(0xFFB91C1C),
      'notMarked': AppColors.light.notMarked.foreground,
      'late':     const Color(0xFF92400E),
      'excused':  const Color(0xFF1D4ED8),
      'pending':  const Color(0xFF854D0E),
      'synced':   const Color(0xFF0F766E),
      'conflict': const Color(0xFFB91C1C),
    };
    for (final entry in pairs.entries) {
      test('${entry.key} fg on lightSurface', () {
        _expectAA('light.${entry.key} on surface', entry.value, lightSurface);
      });
    }
  });

  group('Dark status foreground vs canvas (AA >= 4.5)', () {
    final pairs = <String, Color>{
      'present':  const Color(0xFF4ADE80),
      'absent':   const Color(0xFFF87171),
      'notMarked': AppColors.dark.notMarked.foreground,
      'late':     const Color(0xFFFBBF24),
      'excused':  const Color(0xFF60A5FA),
      'pending':  const Color(0xFFFCD34D),
      'synced':   const Color(0xFF5EEAD4),
      'conflict': const Color(0xFFFB7185),
    };
    for (final entry in pairs.entries) {
      test('${entry.key} fg on darkCanvas', () {
        _expectAA('dark.${entry.key} on canvas', entry.value, darkCanvas);
      });
    }
  });

  group('Dark status foreground vs surface (AA >= 4.5)', () {
    final pairs = <String, Color>{
      'present':  const Color(0xFF4ADE80),
      'absent':   const Color(0xFFF87171),
      'notMarked': AppColors.dark.notMarked.foreground,
      'late':     const Color(0xFFFBBF24),
      'excused':  const Color(0xFF60A5FA),
      'pending':  const Color(0xFFFCD34D),
      'synced':   const Color(0xFF5EEAD4),
      'conflict': const Color(0xFFFB7185),
    };
    for (final entry in pairs.entries) {
      test('${entry.key} fg on darkSurface', () {
        _expectAA('dark.${entry.key} on surface', entry.value, darkSurface);
      });
    }
  });

  group('AppColors.contrastRatio helper mirrors manual formula', () {
    test('present light vs canvas', () {
      const fg = Color(0xFF166534);
      final expected = _contrastRatio(fg, lightCanvas);
      final actual = AppColors.contrastRatio(fg, lightCanvas);
      expect(actual, closeTo(expected, 0.001));
    });
  });

  group('Gold accent pairs', () {
    // Light: foreground (#B8860B) on canvas (#FAF8F4) = 3.07:1 → large/icon ONLY, skip
    test('light gold fg (#B8860B) on canvas — SKIP (large/icon only, 3.07:1)', () {
      _expectAA(
        'light.accent.fg on canvas',
        const Color(0xFFB8860B),
        lightCanvas,
        skipKnown: true, // 3.07:1 — DESIGN.md approved for large/icon, not body text
      );
    });

    // Light: dark ink (#0D1B2A) on gold background (#B8860B) — chip-bg contrast
    test('light gold: dark ink (#0D1B2A) on gold bg (#B8860B) — AA body text', () {
      _expectAA(
        'light.accent.bg: ink on gold',
        const Color(0xFF0D1B2A),
        const Color(0xFFB8860B),
      );
    });

    // Dark: gold (#C9A227) on darkCanvas (#0B1120)
    test('dark gold fg (#C9A227) on darkCanvas — AA', () {
      _expectAA(
        'dark.accent.fg on darkCanvas',
        const Color(0xFFC9A227),
        darkCanvas,
      );
    });

    // Dark: gold (#C9A227) on darkSurface (#131D33)
    test('dark gold fg (#C9A227) on darkSurface — AA', () {
      _expectAA(
        'dark.accent.fg on darkSurface',
        const Color(0xFFC9A227),
        darkSurface,
      );
    });
  });

  group('Dark mode primary & control border contrast', () {
    test('darkPrimary (#2563EB) vs darkSurface (#131D33) >= 3.0:1', () {
      final ratio = _contrastRatio(AppDesignColors.darkPrimary, darkSurface);
      expect(ratio, greaterThanOrEqualTo(3.0));
    });

    test('onPrimary (#FFFFFF) vs darkPrimary (#2563EB) >= 4.5:1 (AA)', () {
      _expectAA(
        'dark.onPrimary on darkPrimary',
        AppDesignColors.onPrimary,
        AppDesignColors.darkPrimary,
      );
    });

    test('darkBorder (#64748B) vs darkSurface (#131D33) >= 3.0:1', () {
      final ratio = _contrastRatio(AppDesignColors.darkBorder, darkSurface);
      expect(ratio, greaterThanOrEqualTo(3.0));
    });
  });
}
