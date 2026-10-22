/// Device settings tests using Patrol's native automation.
///
/// Patrol can toggle device settings like Wi-Fi and cellular which
/// `integration_test` cannot do. These tests verify the app handles
/// connectivity changes correctly.
library devflutt_patrol_native.device_settings_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../common/app_helper.dart';

void main() {
  patrolTest(
    'app handles Wi-Fi disabled',
    tags: ['native', 'settings', 'android'],
    ($) async {
      await createApp($);

      // Disable Wi-Fi via Patrol native automation
      await $.platform.mobile.disableWifi();
      await Future.delayed(TestConstants.shortWait);

      // Verify app still renders (offline mode)
      await $('Home').waitUntilVisible();
    },
  );

  patrolTest(
    'app handles cellular enabled',
    tags: ['native', 'settings', 'android'],
    ($) async {
      await createApp($);

      // Enable cellular data via Patrol native automation
      await $.platform.mobile.enableCellular();
      await Future.delayed(TestConstants.shortWait);

      await $('Home').waitUntilVisible();
    },
  );
}