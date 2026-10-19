/// The user's requested project configuration.
class ProjectSpec {
  const ProjectSpec({
    required this.name,
    required this.org,
    required this.preset,
    required this.output,
    required this.platforms,
    this.modules = const <String>[],
    this.dryRun = false,
    this.force = false,
    this.skipPub = false,
  });

  /// Human-facing application name.
  final String name;

  /// Reverse-domain organization used for platform identifiers.
  final String org;

  /// Selected preset ID.
  final String preset;

  /// Destination directory for the generated project.
  final String output;

  /// Target platforms.
  final List<String> platforms;

  /// Explicitly added module IDs, on top of the preset.
  final List<String> modules;

  /// When true, report the plan without writing files.
  final bool dryRun;

  /// When true, overwrite a non-empty destination.
  final bool force;

  /// When true, skip dependency resolution in the generated project.
  final bool skipPub;

  /// The Dart package identifier derived from [name].
  String get projectName => _toSnakeCase(name);

  /// The Android application ID derived from [org] and [projectName].
  String get applicationId => '$org.$projectName';

  static String _toSnakeCase(String value) {
    final normalized = value
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    if (normalized.isEmpty || !RegExp(r'^[a-z]').hasMatch(normalized)) {
      throw FormatException(
        'Invalid project name "$value". Use letters, digits, spaces, or '
        'hyphens, starting with a letter.',
      );
    }
    return normalized;
  }
}
