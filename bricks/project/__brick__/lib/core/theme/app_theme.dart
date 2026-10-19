import 'package:flutter/material.dart';

/// Minimal light/dark theme foundation.
///
/// Colour and typography come from a Material 3 colour scheme generated from a
/// single seed colour. Modules build on these tokens; they do not introduce
/// competing theme sources.
class AppTheme {
  const AppTheme._();

  static const Color _seedColor = Color(0xFF3F51B5);

  /// Light theme for the application.
  static ThemeData light() => _build(Brightness.light);

  /// Dark theme for the application.
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
