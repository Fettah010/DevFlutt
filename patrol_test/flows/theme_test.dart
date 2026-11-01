// Verifies that the app follows the device brightness reported by Android.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../common/app_helper.dart';

void main() {
  patrolTest('follows the device brightness', tags: ['regression', 'theme', 'android'], ($) async {
    await createApp($);
    final scaffold = find.byType(Scaffold);
    final deviceBrightness = $.tester.platformDispatcher.platformBrightness;
    expect(Theme.of($.tester.element(scaffold)).brightness, deviceBrightness);
  });
}
