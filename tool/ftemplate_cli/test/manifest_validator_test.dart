import 'dart:convert';
import 'dart:io';

import 'package:ftemplate_cli/src/manifest/manifest_validator.dart';
import 'package:ftemplate_cli/src/manifest/module_manifest.dart';
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
    test('parses hosted and SDK dependency forms without losing their source', () {
      final hosted = PubDependency.fromYaml(loadYaml('name: intl\nversion: ^0.20.3') as YamlMap);
      final sdk = PubDependency.fromYaml(
        loadYaml('name: flutter_localizations\nsource: sdk\nsdk: flutter') as YamlMap,
      );

      expect(hosted.toPubspecEntry(), 'intl: ^0.20.3');
      expect(sdk.toPubspecEntry(), 'flutter_localizations:\n    sdk: flutter');
      expect(sdk.toString(), 'flutter_localizations (SDK: flutter)');
      expect(sdk, PubDependency.sdk(name: 'flutter_localizations', sdk: 'flutter'));
    });

    test('accepts a valid manifest', () {
      expect(validator.validate(validManifest), isEmpty);
    });

    test('accepts optional development dependencies without changing required fields', () {
      final manifest = _with(validManifest, 'devDependencies', [
        {'name': 'build_runner', 'version': '^2.10.4'},
      ]);
      expect(validator.validate(manifest), isEmpty);
      expect(ManifestValidator.requiredFields, isNot(contains('devDependencies')));
    });

    test('accepts SDK dependencies alongside legacy hosted dependencies', () {
      final manifest = _with(validManifest, 'pubDependencies', [
        {'name': 'intl', 'version': '^0.20.3'},
        {'name': 'flutter_localizations', 'source': 'sdk', 'sdk': 'flutter'},
      ]);

      expect(validator.validate(manifest), isEmpty);
    });

    test('rejects unknown dependency sources and SDK entries without an SDK name', () {
      final unknownSource = _with(validManifest, 'pubDependencies', [
        {'name': 'intl', 'version': '^0.20.3', 'source': 'git'},
      ]);
      final missingSdk = _with(validManifest, 'pubDependencies', [
        {'name': 'flutter_localizations', 'source': 'sdk'},
      ]);

      expect(validator.validate(unknownSource).join('\n'), contains('source'));
      expect(validator.validate(missingSdk).join('\n'), contains('sdk'));
    });

    test('rejects hosted entries without a version and SDK entries with a version', () {
      final missingVersion = _with(validManifest, 'pubDependencies', [
        {'name': 'intl'},
      ]);
      final sdkWithVersion = _with(validManifest, 'pubDependencies', [
        {'name': 'flutter_localizations', 'source': 'sdk', 'sdk': 'flutter', 'version': '^0.0.0'},
      ]);

      expect(validator.validate(missingVersion).join('\n'), contains('version'));
      expect(validator.validate(sdkWithVersion).join('\n'), contains('version'));
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

    test('accepts known capabilities', () {
      final manifest = _with(validManifest, 'capabilities', ['email-password-sign-in', 'logout']);
      expect(validator.validate(manifest), isEmpty);
    });

    test('rejects an unknown capability and names the known ones', () {
      final manifest = _with(validManifest, 'capabilities', ['telepathy']);
      final errors = validator.validate(manifest);
      expect(errors.join('\n'), contains('Unknown capability "telepathy"'));
      expect(errors.join('\n'), contains('email-password-sign-in'));
    });

    test('rejects a duplicate capability', () {
      final manifest = _with(validManifest, 'capabilities', ['logout', 'logout']);
      final errors = validator.validate(manifest);
      expect(errors.join('\n'), contains('Duplicate entry "logout"'));
    });
  });

  group('manifest schema', () {
    test('the JSON schema and the validator agree on the required fields', () {
      final schema = json.decode(
        File('../../manifests/schema/module.schema.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final required = (schema['required'] as List<dynamic>).cast<String>().toSet();
      expect(required, equals(ManifestValidator.requiredFields.toSet()));
    });

    test('the JSON schema and the validator agree on the known capabilities', () {
      final schema = json.decode(
        File('../../manifests/schema/module.schema.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final properties = schema['properties'] as Map<String, dynamic>;
      final capabilities = properties['capabilities'] as Map<String, dynamic>;
      final items = capabilities['items'] as Map<String, dynamic>;
      final declared = (items['enum'] as List<dynamic>).cast<String>().toList();
      expect(declared, equals(knownAuthCapabilities));
    });

    test('the JSON schema declares optional development dependencies', () {
      final schema = json.decode(
        File('../../manifests/schema/module.schema.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final properties = schema['properties'] as Map<String, dynamic>;
      expect(properties['devDependencies'], isA<Map<String, dynamic>>());
      expect((schema['required'] as List<dynamic>), isNot(contains('devDependencies')));
    });
  });
}

YamlMap _with(YamlMap original, String key, dynamic value) {
  final copy = Map<dynamic, dynamic>.from(original);
  copy[key] = value;
  return YamlMap.wrap(copy);
}
