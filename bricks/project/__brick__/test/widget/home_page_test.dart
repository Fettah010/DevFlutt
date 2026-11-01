import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:{{projectName}}/features/home/home_page.dart';
{{#hasLocalization}}import 'package:{{projectName}}/l10n/generated/app_localizations.dart';
{{/hasLocalization}}

Widget _testApp({required Widget home}) => MaterialApp(
{{#hasLocalization}}  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
{{/hasLocalization}}  home: home,
);

void main() {
  group('HomePage', () {
    testWidgets('renders the title and the description', (tester) async {
      await tester.pumpWidget(_testApp(home: const HomePage()));

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Your app is ready'), findsOneWidget);
    });

    testWidgets('exposes an accessible label for the example icon', (tester) async {
      await tester.pumpWidget(_testApp(home: const HomePage()));

      expect(find.bySemanticsLabel('Flutter logo'), findsOneWidget);
    });

    testWidgets('renders without overflow at double text scale', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: _testApp(home: const HomePage()),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
