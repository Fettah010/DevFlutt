/// The spacing scale used across the application.
///
/// Every layout gap is a multiple of these values so that the vertical and
/// horizontal rhythm stays consistent between features.
abstract final class AppSpacing {
  /// Extra small gap, for example between an icon and its label.
  static const double xs = 4;

  /// Small gap, for example inside a compact control.
  static const double sm = 8;

  /// Default gap, used for most content padding.
  static const double md = 16;

  /// Large gap, for example between page sections.
  static const double lg = 24;

  /// Extra large gap, for example around a hero area.
  static const double xl = 32;
}

/// The corner radius scale used across the application.
abstract final class AppRadius {
  /// Small radius, for example on a chip.
  static const double sm = 8;

  /// Default radius, used by cards, fields, and buttons.
  static const double md = 12;

  /// Large radius, for example on a dialog.
  static const double lg = 20;
}

/// The motion durations used across the application.
abstract final class AppDurations {
  /// Fast transition, for example a focus or hover change.
  static const Duration fast = Duration(milliseconds: 150);

  /// Default transition, for example a route change.
  static const Duration normal = Duration(milliseconds: 250);

  /// Slow transition, for example a large content reveal.
  static const Duration slow = Duration(milliseconds: 400);
}
