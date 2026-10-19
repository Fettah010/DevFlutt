import 'dart:io';

import 'package:ftemplate_cli/ftemplate_cli.dart';
import 'package:test/test.dart';

void main() {
  const brickPath = '../../bricks/project';
  final planner = ProjectPlanner(ManifestRepository(manifestsDir: '../../manifests'));

  ProjectSpec spec({
    required String name,
    required String org,
    String preset = 'blank',
    List<String> modules = const [],
  }) => ProjectSpec(
    name: name,
    org: org,
    preset: preset,
    output: Directory.systemTemp.path,
    platforms: const ['android'],
    modules: modules,
  );

  Future<GenerationResult> generate(ProjectSpec projectSpec) async {
    try {
      return await GenerationEngine(brickPath: brickPath).generate(planner.plan(projectSpec));
    } on Exception catch (error) {
      fail('Generation failed: $error');
    }
  }

  group('GenerationEngine', () {
    test('generates a blank project with no optional dependencies', () async {
      final result = await generate(spec(name: 'Blank', org: 'com.example'));

      expect(result.projectDir.existsSync(), isTrue);
      expect(result.metadata['template_version'], packageVersion);

      final pubspec = File('${result.projectDir.path}/pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('name: blank'));
      expect(pubspec, isNot(contains('flutter_riverpod')));
      expect(pubspec, isNot(contains('go_router')));

      await result.projectDir.delete(recursive: true);
    });

    test('generates a core project with Riverpod and go_router', () async {
      final result = await generate(spec(name: 'Core App', org: 'com.example', preset: 'core'));

      final pubspec = File('${result.projectDir.path}/pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('flutter_riverpod'));
      expect(pubspec, contains('go_router'));
      expect(result.metadata['modules'], containsAll(['state-riverpod', 'navigation']));

      await result.projectDir.delete(recursive: true);
    });

    test('generation is deterministic', () async {
      final first = await generate(spec(name: 'Det', org: 'com.example', preset: 'core'));
      final second = await generate(spec(name: 'Det', org: 'com.example', preset: 'core'));

      expect(_relativeContents(first.projectDir), _relativeContents(second.projectDir));

      await first.projectDir.delete(recursive: true);
      await second.projectDir.delete(recursive: true);
    });
  });
}

Map<String, List<int>> _relativeContents(Directory root) {
  final contents = <String, List<int>>{};
  for (final entity in root.listSync(recursive: true)) {
    if (entity is File) {
      final relative = entity.path.substring(root.path.length + 1);
      contents[relative] = entity.readAsBytesSync();
    }
  }
  return contents;
}
