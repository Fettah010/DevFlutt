import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:{{projectName}}/app.dart';
import 'package:{{projectName}}/core/config/app_config.dart';

const _config = AppConfig(appName: 'TestApp', environment: AppEnvironment.development);

void main() {
  testWidgets('renders the home screen', (tester) async {
{{#hasGoRouter}}    await tester.pumpWidget(DevFluttApp(config: _config));
{{/hasGoRouter}}{{^hasGoRouter}}    await tester.pumpWidget(const DevFluttApp(config: _config));
{{/hasGoRouter}}    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Your app is ready'), findsOneWidget);
  });

  testWidgets('follows platform brightness changes in system theme mode', (tester) async {
    try {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
{{#hasGoRouter}}      await tester.pumpWidget(DevFluttApp(config: _config));
{{/hasGoRouter}}{{^hasGoRouter}}      await tester.pumpWidget(const DevFluttApp(config: _config));
{{/hasGoRouter}}
      expect(Theme.of(tester.element(find.byType(Scaffold))).brightness, Brightness.dark);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(Theme.of(tester.element(find.byType(Scaffold))).brightness, Brightness.light);
    } finally {
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
    }
  });
}
