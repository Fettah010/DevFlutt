import 'package:yaml/yaml.dart';

/// A single pub dependency contributed by a module.
class PubDependency {
  const PubDependency({required this.name, required this.version});

  final String name;
  final String version;

  factory PubDependency.fromYaml(YamlMap map) => PubDependency(
    name: _string(map['name'], 'pubDependencies.name'),
    version: _string(map['version'], 'pubDependencies.version'),
  );

  @override
  String toString() => '$name: $version';
}

/// Privacy declarations for a module.
class ManifestPrivacy {
  const ManifestPrivacy({required this.network, required this.telemetry});

  final bool network;
  final bool telemetry;

  factory ManifestPrivacy.fromYaml(YamlMap map) => ManifestPrivacy(
    network: _bool(map['network'], 'privacy.network'),
    telemetry: _bool(map['telemetry'], 'privacy.telemetry'),
  );
}

/// Test declarations for a module.
class ManifestTests {
  const ManifestTests({
    required this.unit,
    required this.widget,
    required this.integration,
  });

  final bool unit;
  final bool widget;
  final String integration;

  factory ManifestTests.fromYaml(YamlMap map) => ManifestTests(
    unit: _bool(map['unit'], 'tests.unit'),
    widget: _bool(map['widget'], 'tests.widget'),
    integration: _string(map['integration'], 'tests.integration'),
  );
}

/// Native (platform) changes contributed by a module.
class NativeChanges {
  const NativeChanges({required this.android, required this.ios});

  final List<String> android;
  final List<String> ios;

  factory NativeChanges.fromYaml(YamlMap map) => NativeChanges(
    android: _stringList(map['android'], 'nativeChanges.android'),
    ios: _stringList(map['ios'], 'nativeChanges.ios'),
  );
}

/// A parsed module manifest.
class ModuleManifest {
  const ModuleManifest({
    required this.id,
    required this.version,
    required this.category,
    required this.summary,
    required this.requires,
    required this.conflictsWith,
    required this.platforms,
    required this.pubDependencies,
    required this.nativeChanges,
    required this.permissions,
    required this.configKeys,
    required this.privacy,
    required this.outputs,
    required this.requiredSetup,
    required this.tests,
  });

  final String id;
  final int version;
  final String category;
  final String summary;
  final List<String> requires;
  final List<String> conflictsWith;
  final List<String> platforms;
  final List<PubDependency> pubDependencies;
  final NativeChanges nativeChanges;
  final List<String> permissions;
  final List<String> configKeys;
  final ManifestPrivacy privacy;
  final List<String> outputs;
  final List<String> requiredSetup;
  final ManifestTests tests;

  factory ModuleManifest.fromYaml(YamlMap map) => ModuleManifest(
    id: _string(map['id'], 'id'),
    version: _int(map['version'], 'version'),
    category: _string(map['category'], 'category'),
    summary: _string(map['summary'], 'summary'),
    requires: _stringList(map['requires'], 'requires'),
    conflictsWith: _stringList(map['conflictsWith'], 'conflictsWith'),
    platforms: _stringList(map['platforms'], 'platforms'),
    pubDependencies: _pubDependencies(map['pubDependencies']),
    nativeChanges: NativeChanges.fromYaml(
      _map(map['nativeChanges'], 'nativeChanges'),
    ),
    permissions: _stringList(map['permissions'], 'permissions'),
    configKeys: _stringList(map['configKeys'], 'configKeys'),
    privacy: ManifestPrivacy.fromYaml(_map(map['privacy'], 'privacy')),
    outputs: _stringList(map['outputs'], 'outputs'),
    requiredSetup: _stringList(map['requiredSetup'], 'requiredSetup'),
    tests: ManifestTests.fromYaml(_map(map['tests'], 'tests')),
  );

  @override
  String toString() => id;
}

/// Loads a module manifest from a YAML string.
ModuleManifest loadModuleManifest(String yaml) {
  final decoded = loadYaml(yaml);
  if (decoded is! YamlMap) {
    throw const FormatException('Module manifest must be a YAML mapping.');
  }
  return ModuleManifest.fromYaml(decoded);
}

/// Loads a preset from a YAML string, returning the ordered module IDs.
List<String> loadPreset(String yaml) {
  final decoded = loadYaml(yaml);
  if (decoded is! YamlMap) {
    throw const FormatException('Preset must be a YAML mapping.');
  }
  return _stringList(decoded['modules'], 'modules');
}

String _string(dynamic value, String path) {
  if (value is! String || value.isEmpty) {
    throw FormatException('$path must be a non-empty string.');
  }
  return value;
}

int _int(dynamic value, String path) {
  if (value is! int) {
    throw FormatException('$path must be an integer.');
  }
  return value;
}

bool _bool(dynamic value, String path) {
  if (value is! bool) {
    throw FormatException('$path must be a boolean.');
  }
  return value;
}

YamlMap _map(dynamic value, String path) {
  if (value is! YamlMap) {
    throw FormatException('$path must be a mapping.');
  }
  return value;
}

List<String> _stringList(dynamic value, String path) {
  if (value is YamlList) {
    return value.map((entry) {
      if (entry is! String) {
        throw FormatException('$path entries must be strings.');
      }
      return entry;
    }).toList(growable: false);
  }
  if (value == null) {
    return const <String>[];
  }
  throw FormatException('$path must be a list.');
}

List<PubDependency> _pubDependencies(dynamic value) {
  if (value is YamlList) {
    return value
        .map((entry) => PubDependency.fromYaml(_map(entry, 'pubDependencies')))
        .toList(growable: false);
  }
  if (value == null) {
    return const <PubDependency>[];
  }
  throw FormatException('pubDependencies must be a list.');
}
