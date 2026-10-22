/// App lifecycle tests using Patrol's native automation.
///
/// Patrol can interact with the OS (home button, app switching, etc.) which
/// `integration_test` cannot do. These tests verify that app state is
/// preserved across background/foreground transitions.
library devflutt_patrol_flows.app_lifecycle_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../common/app_helper.dart';
import '../common/test_data.dart';
import '../pages/home_page.dart';

void main() {
  patrolTest(
    'app state preserved after backgrounding',
    tags: ['smoke', 'lifecycle', 'android'],
    ($) async {
      await createApp($);

      final homePage = HomePage($);

      // Verify initial state
      await homePage.waitForPage();
      await homePage.verifyContent();

      // Background the app via the OS home button
      await $.platform.mobile.pressHome();

      // Wait briefly to simulate time in background
      await Future.delayed(TestConstants.shortWait);

      // Bring app back to foreground
      await $.platform.mobile.openApp();

      // Verify state is preserved
      await homePage.waitForPage();
      await homePage.verifyContent();
    },
  );

  patrolTest(
    'app resumes after switching away and back',
    tags: ['lifecycle', 'android'],
    ($) async {
      await createApp($);

      final homePage = HomePage($);

      await homePage.waitForPage();

      // Press home to background
      await $.platform.mobile.pressHome();
      await Future.delayed(TestConstants.shortWait);

      // Return to app
      await $.platform.mobile.openApp();

      await homePage.waitForPage();
      await homePage.verifyContent();
    },
  );
}