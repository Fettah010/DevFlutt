import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:{{projectName}}/core/theme/app_theme.dart';
import 'package:{{projectName}}/core/theme/app_tokens.dart';

void main() {
  group('AppTheme', () {
    test('provides a Material 3 light and dark theme', () {
      final light = AppTheme.light();
      final dark = AppTheme.dark();

      expect(light.useMaterial3, isTrue);
      expect(dark.useMaterial3, isTrue);
      expect(light.colorScheme.brightness, Brightness.light);
      expect(dark.colorScheme.brightness, Brightness.dark);
    });

    test('provides light and dark high-contrast variants', () {
      final light = AppTheme.lightHighContrast();
      final dark = AppTheme.darkHighContrast();

      expect(light.colorScheme.brightness, Brightness.light);
      expect(dark.colorScheme.brightness, Brightness.dark);
      expect(light.colorScheme.primary, isNot(AppTheme.light().colorScheme.primary));
      expect(dark.colorScheme.primary, isNot(AppTheme.dark().colorScheme.primary));
    });

    test('keeps the semantic colours of the two schemes distinct', () {
      final light = AppTheme.light().colorScheme;
      final dark = AppTheme.dark().colorScheme;

      expect(light.primary, isNot(dark.primary));
      expect(light.onPrimary, isNot(dark.onPrimary));
      expect(light.error, isNot(dark.error));
      expect(light.onError, isNot(dark.onError));
    });

    testWidgets('applies the light theme to a widget tree', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: Text('themed')),
        ),
      );

      expect(find.text('themed'), findsOneWidget);
    });

    testWidgets('renders without overflow at double text scale', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(body: Text('scaled')),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('AppTokens', () {
    test('exposes an increasing spacing scale', () {
      expect(AppSpacing.xs, lessThan(AppSpacing.sm));
      expect(AppSpacing.sm, lessThan(AppSpacing.md));
      expect(AppSpacing.md, lessThan(AppSpacing.lg));
      expect(AppSpacing.lg, lessThan(AppSpacing.xl));
    });

    test('exposes an increasing radius scale', () {
      expect(AppRadius.sm, lessThan(AppRadius.md));
      expect(AppRadius.md, lessThan(AppRadius.lg));
    });

    test('exposes ordered motion durations', () {
      expect(AppDurations.fast, lessThan(AppDurations.normal));
      expect(AppDurations.normal, lessThan(AppDurations.slow));
    });
  });
}
