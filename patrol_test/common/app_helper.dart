/// Common app initialization helper for Patrol tests.
///
/// Patrol does NOT use `runApp()`. Instead, use `$.pumpWidgetAndSettle()`
/// to mount the app under test. See:
// https://patrol.leancode.co/documentation#initializing-app-inside-a-test
library devflutt_patrol_common.app_helper;

import 'package:devflutt/app.dart';
import 'package:devflutt/core/config/app_config.dart';
import 'package:patrol/patrol.dart';

/// Builds and pumps the DevFlutt app inside a Patrol test.
///
/// [config] overrides the default [AppConfig]. When omitted, a development
/// configuration with the name "DevFlutt Test" is used.
Future<void> createApp(
  PatrolIntegrationTester $, {
  AppConfig? config,
}) async {
  config ??= const AppConfig(
    appName: 'DevFlutt Test',
    environment: AppEnvironment.development,
  );

  await $.pumpWidgetAndSettle(DevFluttApp(config: config));
}