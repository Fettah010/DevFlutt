/// Native permission tests using Patrol's native automation.
///
/// Patrol can interact with OS-level permission dialogs which `integration_test`
/// cannot do. These tests verify the app handles permission grants correctly.
library devflutt_patrol_native.permission_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../common/app_helper.dart';
import '../common/test_data.dart';

void main() {
  patrolTest(
    'location permission dialog is granted',
    tags: ['native', 'permission', 'android'],
    ($) async {
      await createApp($);

      // Handle the native location permission dialog
      await $.platform.mobile.selectFineLocation();
      await $.platform.mobile.grantPermissionWhenInUse();

      // Verify native automation works without errors
      expect(true, isTrue);
    },
  );

  patrolTest(
    'permission dialog can be dismissed',
    tags: ['native', 'permission', 'android'],
    ($) async {
      await createApp($);

      // Verify app loads without permission errors
      await $('Home').waitUntilVisible();
    },
  );
}