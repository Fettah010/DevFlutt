/// Base class for all Patrol page objects.
///
/// Provides the PatrolIntegrationTester instance and a common interface for page
/// verification. All page objects should extend this class.
library devflutt_patrol_pages.base_page;

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

abstract class BasePage {
  /// The Patrol tester instance used for UI interactions.
  final PatrolIntegrationTester $;

  BasePage(this.$);

  /// Waits for the page to become visible.
  /// Subclasses must override this to verify their specific page.
  Future<void> waitForPage() async {
    // Default implementation does nothing; subclasses should override.
  }

  /// Verifies that the page content is correct.
  /// Subclasses must override this to verify their specific page content.
  Future<void> verifyContent() async {
    // Default implementation does nothing; subclasses should override.
  }
}