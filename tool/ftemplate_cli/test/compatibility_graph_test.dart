import 'package:ftemplate_cli/src/graph/compatibility_exception.dart';
import 'package:ftemplate_cli/src/graph/compatibility_graph.dart';
import 'package:ftemplate_cli/src/manifest/module_manifest.dart';
import 'package:test/test.dart';

void main() {
  ModuleManifest manifest({
    required String id,
    List<String> requires = const [],
    List<String> conflictsWith = const [],
  }) => ModuleManifest(
    id: id,
    version: 1,
    category: 'test',
    summary: 'Test module.',
    requires: requires,
    conflictsWith: conflictsWith,
    platforms: const ['android', 'ios'],
    pubDependencies: const [],
    nativeChanges: const NativeChanges(android: [], ios: []),
    permissions: const [],
    configKeys: const [],
    privacy: const ManifestPrivacy(network: false, telemetry: false),
    outputs: ['lib/$id.dart'],
    requiredSetup: const [],
    tests: const ManifestTests(unit: true, widget: false, integration: 'none'),
  );

  final graph = CompatibilityGraph([
    manifest(id: 'architecture-core'),
    manifest(id: 'state-riverpod', requires: ['architecture-core']),
    manifest(id: 'navigation', requires: ['architecture-core', 'state-riverpod']),
    manifest(id: 'conflicting-a', conflictsWith: ['conflicting-b']),
    manifest(id: 'conflicting-b', conflictsWith: ['conflicting-a']),
  ]);

  group('CompatibilityGraph', () {
    test('resolves a valid selection with transitive requirements', () {
      final resolved = graph.resolve(['navigation']);

      expect(resolved.map((module) => module.id), [
        'architecture-core',
        'state-riverpod',
        'navigation',
      ]);
    });

    test('resolves an empty selection', () {
      expect(graph.resolve([]), isEmpty);
    });

    test('rejects an unknown module', () {
      expect(
        () => graph.resolve(['does-not-exist']),
        throwsA(
          isA<CompatibilityException>().having(
            (error) => error.message,
            'message',
            contains('Unknown module "does-not-exist"'),
          ),
        ),
      );
    });

    test('rejects a missing requirement', () {
      final incomplete = CompatibilityGraph([
        manifest(id: 'navigation', requires: ['architecture-core']),
      ]);

      expect(
        () => incomplete.resolve(['navigation']),
        throwsA(
          isA<CompatibilityException>().having(
            (error) => error.message,
            'message',
            contains('unknown module'),
          ),
        ),
      );
    });

    test('rejects conflicting modules', () {
      expect(
        () => graph.resolve(['conflicting-a', 'conflicting-b']),
        throwsA(
          isA<CompatibilityException>().having(
            (error) => error.message,
            'message',
            contains('conflict'),
          ),
        ),
      );
    });

    test('rejects a circular dependency', () {
      final cyclic = CompatibilityGraph([
        manifest(id: 'a', requires: ['b']),
        manifest(id: 'b', requires: ['a']),
      ]);

      expect(
        () => cyclic.resolve(['a']),
        throwsA(
          isA<CompatibilityException>().having(
            (error) => error.message,
            'message',
            contains('Circular dependency'),
          ),
        ),
      );
    });

    test('exposes known module ids', () {
      expect(graph.moduleIds, containsAll(['architecture-core', 'navigation']));
    });
  });
}
