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

    testWidgets('scales text without overflow', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      expect(tester.takeException(), isNull);
    });
  });
}
