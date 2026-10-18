/// Runtime environment for the application.
enum AppEnvironment {
  development('development'),
  staging('staging'),
  production('production');

  const AppEnvironment(this.wireName);

  /// The value expected by `--dart-define=APP_ENV`.
  final String wireName;

  /// Parses an environment name, rejecting unknown values.
  static AppEnvironment fromWire(String name) {
    for (final environment in AppEnvironment.values) {
      if (environment.wireName == name) {
        return environment;
      }
    }
    final allowed = AppEnvironment.values.map((e) => e.wireName).join(', ');
    throw StateError(
      'Invalid APP_ENV "$name". Expected one of: $allowed.',
    );
  }
}

/// Typed, validated configuration boundary.
///
/// Values are read from `--dart-define` at compile time. Unknown environment
/// names fail fast with an actionable message instead of silently defaulting.
class AppConfig {
  const AppConfig({required this.appName, required this.environment});

  /// Human-facing application name.
  final String appName;

  /// Selected runtime environment.
  final AppEnvironment environment;

  /// Builds the configuration from compile-time environment defines.
  factory AppConfig.fromEnvironment() {
    const appName = String.fromEnvironment(
      'APP_NAME',
      defaultValue: 'DevFlutt',
    );
    const envName = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );

    return AppConfig(
      appName: appName,
      environment: AppEnvironment.fromWire(envName),
    );
  }

  /// Whether the application is running against production infrastructure.
  bool get isProduction => environment == AppEnvironment.production;
}
