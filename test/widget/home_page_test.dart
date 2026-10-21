import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devflutt/features/home/home_page.dart';

void main() {
  group('HomePage', () {
    testWidgets('renders the title and the description', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Your app is ready'), findsOneWidget);
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
