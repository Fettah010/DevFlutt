import 'package:devflutt/features/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomePage', () {
    testWidgets('renders the title and blank-app description', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      expect(find.text('DevFlutt'), findsOneWidget);
      expect(find.text('Blank-first Flutter starter'), findsOneWidget);
      expect(find.byIcon(Icons.flutter_dash), findsOneWidget);
    });

    testWidgets('exposes an accessible label for the example icon', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      expect(find.bySemanticsLabel('Flutter logo'), findsOneWidget);
    });

    testWidgets('renders without overflow at double text scale', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: const MaterialApp(home: HomePage()),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
