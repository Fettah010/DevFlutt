import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
{{#hasStateRiverpod}}
import 'package:flutter_riverpod/flutter_riverpod.dart';
{{/hasStateRiverpod}}

import 'package:{{projectName}}/app.dart';
import 'package:{{projectName}}/core/config/app_config.dart';

void main() {
  testWidgets('renders the home screen', (tester) async {
    await tester.pumpWidget(const DevFluttApp(config: _config()));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Your app is ready'), findsOneWidget);
  });
}

const _config = AppConfig(
  appName: 'TestApp',
  environment: AppEnvironment.development,
);
