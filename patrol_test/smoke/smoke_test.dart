/// Smoke tests for DevFlutt.
///
/// These are fast, critical-path tests that run on every PR and push.
/// They verify the app launches and renders correctly on an emulator.
library devflutt_patrol_smoke.smoke_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../common/app_helper.dart';
import '../common/test_data.dart';
import '../pages/home_page.dart';

void main() {
  patrolTest(
    'app launches and shows the home screen',
    tags: ['smoke', 'android'],
    ($) async {
      await createApp($);

      final homePage = HomePage($);
      await homePage.waitForPage();
      await homePage.verifyContent();
    },
  );

  patrolTest(
    'app title matches configuration',
    tags: ['smoke', 'android'],
    ($) async {
      await createApp($);

      final homePage = HomePage($);
      await homePage.waitForPage();
      expect($(AppStrings.homeTitle), findsOneWidget);
    },
  );
}