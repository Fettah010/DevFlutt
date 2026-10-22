import 'package:yaml/yaml.dart';

import 'module_manifest.dart';

/// Validates a module manifest against the schema rules.
///
/// Returns a list of actionable error messages. An empty list means the manifest
/// is structurally valid. Referential integrity (unknown `requires` /
/// `conflictsWith` targets) is checked by the compatibility graph, not here.
class ManifestValidator {
  const ManifestValidator();

  static const List<String> _requiredFields = [
    'id',
    'version',
    'category',
    'summary',
    'requires',
    'conflictsWith',
    'platforms',
    'pubDependencies',
    'nativeChanges',
    'permissions',
    'configKeys',
    'privacy',
    'outputs',
    'requiredSetup',
    'tests',
  ];

  /// The fields every module manifest must declare.
  ///
  /// The published JSON schema lists the same fields. A generator test keeps the
  /// two in step so the documented contract cannot drift from the enforced one.
  static List<String> get requiredFields => List<String>.unmodifiable(_requiredFields);

  static final RegExp _idPattern = RegExp(r'^[a-z][a-z0-9-]*$');

  /// Validates [map] and returns actionable error messages.
  List<String> validate(YamlMap map) {
    final errors = <String>[];

    for (final field in _requiredFields) {
      if (!map.containsKey(field)) {
        errors.add('Missing required field "$field".');
      }
    }

    final id = map['id'];
    if (id is String && !_idPattern.hasMatch(id)) {
      errors.add(
        'Invalid id "$id". Use lowercase letters, numbers, and hyphens, '
        'starting with a letter.',
      );
    }

    final version = map['version'];
    if (version is int && version < 1) {
      errors.add('Invalid version $version. Must be an integer >= 1.');
    }

    final platforms = map['platforms'];
    if (platforms is YamlList) {
      if (platforms.isEmpty) {
        errors.add('platforms must not be empty.');
      }
      for (final platform in platforms) {
        if (platform != 'android' && platform != 'ios') {
          errors.add('Invalid platform "$platform". Expected android or ios.');
        }
      }
    }

    final outputs = map['outputs'];
    if (outputs is YamlList && outputs.isEmpty) {
      errors.add('outputs must not be empty.');
    }

    _checkDuplicates(map, 'requires', errors);
    _checkDuplicates(map, 'conflictsWith', errors);
    _checkDuplicates(map, 'platforms', errors);
    _checkDuplicates(map, 'permissions', errors);
    _checkDuplicates(map, 'configKeys', errors);
    _checkDuplicates(map, 'outputs', errors);
    _checkDuplicates(map, 'capabilities', errors);

    _checkCapabilities(map, errors);

    return errors;
  }

  void _checkCapabilities(YamlMap map, List<String> errors) {
    final value = map['capabilities'];
    if (value is! YamlList) {
      return;
    }
    for (final entry in value) {
      if (entry is! String) {
        errors.add('capabilities entries must be strings.');
        continue;
      }
      if (!knownAuthCapabilities.contains(entry)) {
        errors.add(
          'Unknown capability "$entry". Known capabilities: '
          '${knownAuthCapabilities.join(', ')}.',
        );
      }
    }
  }

  void _checkDuplicates(YamlMap map, String field, List<String> errors) {
    final value = map[field];
    if (value is! YamlList) {
      return;
    }
    final seen = <String>{};
    for (final entry in value) {
      final key = entry.toString();
      if (!seen.add(key)) {
        errors.add('Duplicate entry "$key" in "$field".');
      }
    }
  }
}
