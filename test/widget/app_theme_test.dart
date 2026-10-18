import 'package:devflutt/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    test('provides a Material 3 light and dark theme', () {
      final light = AppTheme.light();
      final dark = AppTheme.dark();

      expect(light.useMaterial3, isTrue);
      expect(dark.useMaterial3, isTrue);
      expect(light.colorScheme.brightness, Brightness.light);
      expect(dark.colorScheme.brightness, Brightness.dark);
      expect(light.colorScheme.primary.alpha, greaterThan(0));
      expect(dark.colorScheme.primary.alpha, greaterThan(0));
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
  });
}
