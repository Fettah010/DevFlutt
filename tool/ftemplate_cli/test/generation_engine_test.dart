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
    test('the brick declares every known capability identifier', () {
      const brickFile =
          '$brickPath/__brick__/{{#hasAuthCore}}lib/core/auth/'
          'auth_capabilities.dart{{/hasAuthCore}}';
      final source = File(brickFile).readAsStringSync();

      for (final capability in knownAuthCapabilities) {
        expect(
          source,
          contains("'$capability'"),
          reason: 'the brick is missing the capability $capability',
        );
      }
    });

    test('generates a blank project with no optional dependencies', () async {
      final result = await generate(spec(name: 'Blank', org: 'com.example'));

      expect(result.projectDir.existsSync(), isTrue);
      expect(result.metadata['template_version'], packageVersion);

      final pubspec = File('${result.projectDir.path}/pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('name: blank'));
      expect(pubspec, isNot(contains('flutter_riverpod')));
      expect(pubspec, isNot(contains('go_router')));
      expect(pubspec, isNot(contains('shared_preferences')));
      expect(pubspec, isNot(contains('drift')));
      expect(pubspec, isNot(contains('build_runner')));

      await result.projectDir.delete(recursive: true);
    });

    test('keeps database runtime and development dependencies in their sections', () async {
      final result = await generate(
        spec(name: 'Database App', org: 'com.example', modules: const ['local-database']),
      );
      final pubspec = File('${result.projectDir.path}/pubspec.yaml').readAsStringSync();
      final runtimeSection = pubspec.split('dev_dependencies:').first;
      final developmentSection = pubspec.split('dev_dependencies:').last;

      expect(runtimeSection, contains('drift: ^2.35.3'));
      expect(runtimeSection, contains('drift_flutter: ^0.3.1'));
      expect(runtimeSection, isNot(contains('drift_dev')));
      expect(developmentSection, contains('drift_dev: ^2.35.2'));
      expect(developmentSection, contains('build_runner: ^2.17.1'));
      expect(
        File('${result.projectDir.path}/lib/core/database/app_database.g.dart').existsSync(),
        isTrue,
      );

      await result.projectDir.delete(recursive: true);
    });

    test('preferences are opt-in and never enter existing presets', () async {
      final blank = await generate(spec(name: 'Blank', org: 'com.example'));
      expect(
        File('${blank.projectDir.path}/lib/core/preferences/preferences_store.dart').existsSync(),
        isFalse,
      );
      await blank.projectDir.delete(recursive: true);

      final app = await generate(
        spec(name: 'Preferences App', org: 'com.example', modules: const ['preferences']),
      );
      expect(
        File('${app.projectDir.path}/lib/core/preferences/shared_preferences_store.dart')
            .existsSync(),
        isTrue,
      );
      expect(
        File('${app.projectDir.path}/test/unit/preferences_store_test.dart').existsSync(),
        isTrue,
      );
      await app.projectDir.delete(recursive: true);
    });

    test('offline notes and persistent commerce generate only with their selections', () async {
      final memoryCommerce = await generate(
        spec(name: 'Commerce App', org: 'com.example', modules: const ['commerce']),
      );
      final memoryPubspec = File('${memoryCommerce.projectDir.path}/pubspec.yaml')
          .readAsStringSync();
      expect(memoryPubspec, isNot(contains('drift:')));
      expect(
        File('${memoryCommerce.projectDir.path}/lib/features/commerce/data/cart_store.dart')
            .existsSync(),
        isTrue,
      );
      expect(
        File(
          '${memoryCommerce.projectDir.path}/lib/features/commerce/data/database_cart_store.dart',
        ).existsSync(),
        isFalse,
      );
      await memoryCommerce.projectDir.delete(recursive: true);

      final selected = await generate(
        spec(
          name: 'Offline Commerce App',
          org: 'com.example',
          modules: const ['offline-data', 'commerce-persistence'],
        ),
      );
      final selectedPubspec = File('${selected.projectDir.path}/pubspec.yaml').readAsStringSync();
      expect(selectedPubspec, contains('drift: ^2.35.3'));
      expect(
        File(
          '${selected.projectDir.path}/lib/features/offline_notes/data/offline_note_repository.dart',
        ).existsSync(),
        isTrue,
      );
      expect(
        File('${selected.projectDir.path}/lib/features/commerce/data/database_cart_store.dart')
            .existsSync(),
        isTrue,
      );
      final routes = File('${selected.projectDir.path}/lib/app/app_router.dart').readAsStringSync();
      expect(routes, contains('DatabaseCartStore(AppDatabase.defaults())'));
      await selected.projectDir.delete(recursive: true);
    });

    test('generates a core project with Riverpod and go_router', () async {
      final result = await generate(spec(name: 'Core App', org: 'com.example', preset: 'core'));

      final pubspec = File('${result.projectDir.path}/pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('flutter_riverpod'));
      expect(pubspec, contains('go_router'));
      expect(result.metadata['modules'], containsAll(['state-riverpod', 'navigation']));

      await result.projectDir.delete(recursive: true);
    });

    test('generates a demo project with the showcase feature', () async {
      final result = await generate(spec(name: 'Demo App', org: 'com.example', preset: 'demo'));

      final showcase = File(
        '${result.projectDir.path}/lib/features/showcase/presentation/showcase_page.dart',
      );
      expect(showcase.existsSync(), isTrue);

      final routes = File('${result.projectDir.path}/lib/app/app_routes.dart').readAsStringSync();
      expect(routes, contains('/showcase'));

      final router = File('${result.projectDir.path}/lib/app/app_router.dart').readAsStringSync();
      expect(router, contains('AppRoutes.showcase'));

      await result.projectDir.delete(recursive: true);
    });

    test('the blank project contains no optional module files', () async {
      final result = await generate(spec(name: 'Blank', org: 'com.example'));

      final router = File('${result.projectDir.path}/lib/app/app_router.dart');
      final button = File('${result.projectDir.path}/lib/core/widgets/app_button.dart');
      final counter = Directory('${result.projectDir.path}/lib/features/counter');

      expect(router.existsSync(), isFalse);
      expect(button.existsSync(), isFalse);
      expect(counter.existsSync(), isFalse);

      await result.projectDir.delete(recursive: true);
    });

    test('the blank project contains no service module files', () async {
      final result = await generate(spec(name: 'Blank', org: 'com.example'));

      final services = File('${result.projectDir.path}/lib/app/app_services.dart');
      final logging = Directory('${result.projectDir.path}/lib/core/logging');
      final networking = Directory('${result.projectDir.path}/lib/core/networking');
      final secureStorage = Directory('${result.projectDir.path}/lib/core/secure_storage');
      final diagnostics = Directory('${result.projectDir.path}/lib/core/diagnostics');

      expect(services.existsSync(), isFalse);
      expect(logging.existsSync(), isFalse);
      expect(networking.existsSync(), isFalse);
      expect(secureStorage.existsSync(), isFalse);
      expect(diagnostics.existsSync(), isFalse);

      final pubspec = File('${result.projectDir.path}/pubspec.yaml').readAsStringSync();
      expect(pubspec, isNot(contains('dio')));
      expect(pubspec, isNot(contains('flutter_secure_storage')));

      await result.projectDir.delete(recursive: true);
    });

    test('the core project has the logger but no transport or storage', () async {
      final result = await generate(spec(name: 'Core App', org: 'com.example', preset: 'core'));

      final logger = File('${result.projectDir.path}/lib/core/logging/app_logger.dart');
      final services = File('${result.projectDir.path}/lib/app/app_services.dart');
      final networking = Directory('${result.projectDir.path}/lib/core/networking');

      expect(logger.existsSync(), isTrue);
      expect(services.existsSync(), isTrue);
      expect(networking.existsSync(), isFalse);

      final pubspec = File('${result.projectDir.path}/pubspec.yaml').readAsStringSync();
      expect(pubspec, isNot(contains('dio')));
      expect(pubspec, isNot(contains('flutter_secure_storage')));

      await result.projectDir.delete(recursive: true);
    });

    test('generates a recommended project with the service modules', () async {
      final result = await generate(
        spec(name: 'Reco App', org: 'com.example', preset: 'recommended'),
      );

      final pubspec = File('${result.projectDir.path}/pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('dio: ^5.11.1'));
      expect(pubspec, contains('flutter_secure_storage: ^11.2.0'));

      final services = File('${result.projectDir.path}/lib/app/app_services.dart');
      expect(services.existsSync(), isTrue);
      expect(services.readAsStringSync(), contains('buildAppServices'));

      final client = File('${result.projectDir.path}/lib/core/networking/dio_api_client.dart');
      expect(client.existsSync(), isTrue);

      expect(
        result.metadata['modules'],
        containsAll(['logging', 'diagnostics', 'networking', 'secure-storage']),
      );

      await result.projectDir.delete(recursive: true);
    });

    test('the secure-storage module generates the Android backup rules', () async {
      final result = await generate(
        spec(name: 'Reco App', org: 'com.example', preset: 'recommended'),
      );

      final backupRules = File(
        '${result.projectDir.path}/android/app/src/main/res/xml/backup_rules.xml',
      );
      final extractionRules = File(
        '${result.projectDir.path}/android/app/src/main/res/xml/data_extraction_rules.xml',
      );
      final manifest = File('${result.projectDir.path}/android/app/src/main/AndroidManifest.xml');

      expect(backupRules.existsSync(), isTrue);
      expect(extractionRules.existsSync(), isTrue);
      expect(backupRules.readAsStringSync(), contains('FlutterSecureStorage.xml'));
      expect(manifest.readAsStringSync(), contains('android:fullBackupContent'));
      expect(manifest.readAsStringSync(), contains('android:dataExtractionRules'));

      await result.projectDir.delete(recursive: true);
    });

    test('a project without secure storage has no backup rules', () async {
      final result = await generate(spec(name: 'Core App', org: 'com.example', preset: 'core'));

      final backupRules = File(
        '${result.projectDir.path}/android/app/src/main/res/xml/backup_rules.xml',
      );
      final manifest = File('${result.projectDir.path}/android/app/src/main/AndroidManifest.xml');

      expect(backupRules.existsSync(), isFalse);
      expect(manifest.readAsStringSync(), isNot(contains('android:fullBackupContent')));

      await result.projectDir.delete(recursive: true);
    });

    test('a project with a network client declares the INTERNET permission', () async {
      final result = await generate(
        spec(name: 'Reco App', org: 'com.example', preset: 'recommended'),
      );

      final manifest = File('${result.projectDir.path}/android/app/src/main/AndroidManifest.xml');

      // Without this the release build cannot reach the network at all: the
      // debug manifest adds the permission, the release manifest does not.
      expect(manifest.readAsStringSync(), contains('android.permission.INTERNET'));

      await result.projectDir.delete(recursive: true);
    });

    test('a project without a network client declares no INTERNET permission', () async {
      final result = await generate(spec(name: 'Core App', org: 'com.example', preset: 'core'));

      final manifest = File('${result.projectDir.path}/android/app/src/main/AndroidManifest.xml');

      expect(manifest.readAsStringSync(), isNot(contains('android.permission.INTERNET')));

      await result.projectDir.delete(recursive: true);
    });

    test('generates format-clean Dart files', () async {
      final result = await generate(spec(name: 'Formatted', org: 'com.example', preset: 'core'));

      final config = File('${result.projectDir.path}/lib/core/config/app_config.dart')
          .readAsStringSync();

      expect(config, contains("throw StateError('Invalid API_BASE_URL value."));
      expect(config, isNot(contains('\n\n\n')));

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
