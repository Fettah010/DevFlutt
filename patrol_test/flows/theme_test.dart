// Verifies that the app follows Android's system brightness setting.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../common/app_helper.dart';

void main() {
  patrolTest('follows system light and dark mode', tags: ['regression', 'theme', 'android'], (
    $,
  ) async {
    await $.platform.mobile.disableDarkMode();
    await createApp($);
    final scaffold = find.byType(Scaffold);
    expect(Theme.of($.tester.element(scaffold)).brightness, Brightness.light);

    try {
      await $.platform.mobile.enableDarkMode();
      await $.tester.pumpAndSettle();
      expect(Theme.of($.tester.element(scaffold)).brightness, Brightness.dark);
    } finally {
      await $.platform.mobile.disableDarkMode();
      await $.tester.pumpAndSettle();
    }
  });
}
