/// The runtime environment the application was built for.
///
/// The wire names match the Android product flavors (`dev`, `staging`, `prod`)
/// so that a build command reads the same in Gradle and in Dart.
enum AppEnvironment {
  /// Local development builds.
  development('dev'),

  /// Shared pre-production builds.
  staging('staging'),

  /// Production builds.
  production('prod');

  const AppEnvironment(this.wireName);

  /// The canonical value expected by `--dart-define=APP_ENV`.
  final String wireName;

  /// Parses an environment name, rejecting unknown values.
  ///
  /// The offending value is never repeated in the error message: configuration
  /// values can carry deployment details that must not reach logs.
  static AppEnvironment fromWire(String name) {
    final normalized = name.trim().toLowerCase();
    for (final environment in AppEnvironment.values) {
      if (environment.wireName == normalized) {
        return environment;
      }
    }
    final allowed = AppEnvironment.values.map((e) => e.wireName).join(', ');
    throw StateError('Invalid APP_ENV value. Expected one of: $allowed.');
  }
}

/// Typed, validated configuration boundary.
///
/// Values are read from `--dart-define` at compile time. Invalid values fail
/// fast with an actionable message. Messages never repeat the offending value,
/// because configuration values can carry deployment details that must not
/// reach logs.
class AppConfig {
  const AppConfig({
    required this.appName,
    required this.environment,
    this.apiBaseUrl = defaultApiBaseUrl,
    this.featureFlags = const <String>{},
  });

  /// The base URL used when no API base URL is configured.
  static const String defaultApiBaseUrl = 'https://api.example.com';

  /// Human-facing application name.
  final String appName;

  /// Selected runtime environment.
  final AppEnvironment environment;

  /// Base URL of the backend API.
  final String apiBaseUrl;

  /// Feature flags enabled for this build.
  final Set<String> featureFlags;

  /// Builds the configuration from compile-time environment defines.
  factory AppConfig.fromEnvironment() {
    const appName = String.fromEnvironment('APP_NAME', defaultValue: 'DevFlutt');
    const envName = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    const featureFlags = String.fromEnvironment('FEATURE_FLAGS', defaultValue: '');

    return AppConfig(
      appName: appName,
      environment: AppEnvironment.fromWire(envName),
      apiBaseUrl: _parseApiBaseUrl(apiBaseUrl),
      featureFlags: _parseFeatureFlags(featureFlags),
    );
  }

  /// Whether the application is running against production infrastructure.
  bool get isProduction => environment == AppEnvironment.production;

  /// Whether the application is running against local infrastructure.
  bool get isDevelopment => environment == AppEnvironment.development;

  /// Whether the feature flag [name] is enabled for this build.
  bool isFeatureEnabled(String name) => featureFlags.contains(name);

  static final RegExp _flagPattern = RegExp(r'^[A-Za-z0-9_-]+$');

  static String _parseApiBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return defaultApiBaseUrl;
    }

    Uri? parsed;
    try {
      parsed = Uri.tryParse(trimmed);
    } on FormatException {
      parsed = null;
    }

    if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
      throw StateError('Invalid API_BASE_URL value. Expected an absolute http or https URL.');
    }
    if (parsed.scheme != 'http' && parsed.scheme != 'https') {
      throw StateError('Invalid API_BASE_URL value. Expected an http or https URL.');
    }
    return trimmed;
  }

  static Set<String> _parseFeatureFlags(String value) {
    final flags = <String>{};
    var position = 0;
    for (final entry in value.split(',')) {
      final flag = entry.trim();
      if (flag.isEmpty) {
        continue;
      }
      position += 1;
      if (!_flagPattern.hasMatch(flag)) {
        throw StateError(
          'Invalid FEATURE_FLAGS value at position $position. Expected names '
          'of letters, digits, underscores, and hyphens.',
        );
      }
      flags.add(flag);
    }
    return flags;
  }
}
