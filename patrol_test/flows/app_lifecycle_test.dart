// Native app lifecycle behavior on Android.
import 'package:patrol/patrol.dart';

import '../common/app_helper.dart';
import '../pages/home_page.dart';

void main() {
  patrolTest(
    'returns to the home screen after backgrounding',
    tags: ['regression', 'lifecycle', 'android'],
    ($) async {
      await createApp($);
      final homePage = HomePage($);
      await homePage.waitUntilVisible();
      homePage.expectContent();

      await $.platform.mobile.pressHome();
      await $.platform.mobile.openApp(appId: 'com.example.devflutt.dev');

      await homePage.waitUntilVisible();
      homePage.expectContent();
    },
  );
}
