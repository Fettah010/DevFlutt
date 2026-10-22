/// Theme tests using Patrol's native automation.
///
/// Patrol can toggle device-level dark mode via `$.platform.mobile.enableDarkMode()`
/// which `integration_test` cannot do. These tests verify the app responds to
/// system theme changes.
library devflutt_patrol_flows.theme_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../common/app_helper.dart';
import '../common/test_data.dart';
import '../pages/home_page.dart';

void main() {
  patrolTest(
    'app responds to system dark mode',
    tags: ['theme', 'native', 'android'],
    ($) async {
      await createApp($);

      final homePage = HomePage($);

      await homePage.waitForPage();
      await homePage.verifyContent();

      // Enable system-wide dark mode via Patrol native automation
      await $.platform.mobile.enableDarkMode();
      await Future.delayed(TestConstants.shortWait);

      // Verify the app still renders correctly in dark mode
      await homePage.waitForPage();
      await homePage.verifyContent();
    },
  );

  patrolTest(
    'app responds to system light mode',
    tags: ['theme', 'native', 'android'],
    ($) async {
      await createApp($);

      final homePage = HomePage($);

      await homePage.waitForPage();

      // Enable system-wide light mode
      await $.platform.mobile.disableDarkMode();
      await Future.delayed(TestConstants.shortWait);

      await homePage.waitForPage();
      await homePage.verifyContent();
    },
  );
}