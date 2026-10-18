import 'package:ftemplate_cli/src/manifest/manifest_validator.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  const validator = ManifestValidator();

  final validManifest = loadYaml('''
id: example-module
version: 1
category: core
summary: An example module.
requires: []
conflictsWith: []
platforms:
  - android
  - ios
pubDependencies: []
nativeChanges:
  android: []
  ios: []
permissions: []
configKeys: []
privacy:
  network: false
  telemetry: false
outputs:
  - lib/example.dart
requiredSetup: []
tests:
  unit: true
  widget: false
  integration: none
''') as YamlMap;

  group('ManifestValidator', () {
    test('accepts a valid manifest', () {
      expect(validator.validate(validManifest), isEmpty);
    });

    test('reports missing required fields', () {
      final errors = validator.validate(loadYaml('id: example') as YamlMap);
      expect(errors, isNotEmpty);
      expect(errors.join('\n'), contains('Missing required field'));
    });

    test('rejects an invalid id', () {
      final manifest = _with(validManifest, 'id', 'Invalid_ID');
      final errors = validator.validate(manifest);
      expect(errors.join('\n'), contains('Invalid id'));
    });

    test('rejects a version below one', () {
      final manifest = _with(validManifest, 'version', 0);
      final errors = validator.validate(manifest);
      expect(errors.join('\n'), contains('version'));
    });

    test('rejects an unknown platform', () {
      final manifest = _with(validManifest, 'platforms', ['android', 'web']);
      final errors = validator.validate(manifest);
      expect(errors.join('\n'), contains('Invalid platform "web"'));
    });

    test('rejects an empty platforms list', () {
      final manifest = _with(validManifest, 'platforms', <String>[]);
      final errors = validator.validate(manifest);
      expect(errors.join('\n'), contains('platforms must not be empty'));
    });

    test('rejects duplicate entries', () {
      final manifest = _with(validManifest, 'requires', ['a', 'a']);
      final errors = validator.validate(manifest);
      expect(errors.join('\n'), contains('Duplicate entry "a"'));
    });

    test('rejects an empty outputs list', () {
      final manifest = _with(validManifest, 'outputs', <String>[]);
      final errors = validator.validate(manifest);
      expect(errors.join('\n'), contains('outputs must not be empty'));
    });
  });
}

YamlMap _with(YamlMap original, String key, dynamic value) {
  final copy = Map<dynamic, dynamic>.from(original);
  copy[key] = value;
  return copy;
}
