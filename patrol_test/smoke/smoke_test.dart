// Smoke tests for the real DevFlutt app.
import 'package:patrol/patrol.dart';

import '../common/app_helper.dart';
import '../pages/home_page.dart';

void main() {
  patrolTest('launches and shows the complete home screen', tags: ['smoke', 'android'], ($) async {
    await createApp($);
    final homePage = HomePage($);
    await homePage.waitUntilVisible();
    homePage.expectContent();
  });
}
