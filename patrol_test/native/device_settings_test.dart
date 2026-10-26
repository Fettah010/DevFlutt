// The blank home screen must stay available without network connectivity.
import 'package:patrol/patrol.dart';

import '../common/app_helper.dart';
import '../pages/home_page.dart';

void main() {
  patrolTest(
    'blank home screen remains available with Wi-Fi disabled',
    tags: ['regression', 'offline', 'android'],
    ($) async {
      await $.platform.mobile.disableWifi();
      try {
        await createApp($);
        final homePage = HomePage($);
        await homePage.waitUntilVisible();
        homePage.expectContent();
      } finally {
        await $.platform.mobile.enableWifi();
      }
    },
  );
}
