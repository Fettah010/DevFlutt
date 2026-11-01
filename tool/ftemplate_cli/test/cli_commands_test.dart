import 'dart:io';

import 'package:ftemplate_cli/ftemplate_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final runner = FtemplateCommandRunner(manifestsDir: '../../manifests');

  group('list-modules', () {
    test('lists modules and presets', () async {
      final out = StringBuffer();
      final code = await runner.run(['list-modules'], out: out.writeln);

      expect(code, 0);
      expect(out.toString(), contains('architecture-core'));
      expect(out.toString(), contains('state-riverpod'));
      expect(out.toString(), contains('navigation'));
      expect(out.toString(), contains('Presets:'));
      expect(out.toString(), contains('blank'));
      expect(out.toString(), contains('core'));
      expect(out.toString(), contains('demo'));
      expect(out.toString(), contains('design-system'));
      expect(out.toString(), contains('feature-example'));
      expect(out.toString(), contains('showcase'));
      expect(out.toString(), contains('backend-supabase'));
      expect(out.toString(), contains('commerce'));
      expect(out.toString(), contains('full'));
    });
  });

  group('explain-module', () {
    test('describes a known module', () async {
      final out = StringBuffer();
      final code = await runner.run(['explain-module', '--id', 'state-riverpod'], out: out.writeln);

      expect(code, 0);
      expect(out.toString(), contains('state-riverpod'));
      expect(out.toString(), contains('Requires: architecture-core'));
      expect(out.toString(), contains('flutter_riverpod'));
    });

    test('rejects an unknown module', () async {
      final out = StringBuffer();
      final err = StringBuffer();
      final code = await runner.run(
        ['explain-module', '--id', 'nope'],
        out: out.writeln,
        err: err.writeln,
      );

      expect(code, 64);
      expect(err.toString(), contains('Unknown module "nope"'));
    });

    test('requires --id', () async {
      final err = StringBuffer();
      final code = await runner.run(['explain-module'], err: err.writeln);

      expect(code, 64);
      expect(err.toString(), contains('Missing --id'));
    });
  });

  group('validate', () {
    test('accepts a valid manifest', () async {
      final out = StringBuffer();
      final code = await runner.run([
        'validate',
        '--manifest',
        '../../manifests/modules/architecture-core.yaml',
      ], out: out.writeln);

      expect(code, 0);
      expect(out.toString(), contains('is valid'));
    });

    test('rejects an invalid manifest', () async {
      final invalid = File('${Directory.systemTemp.path}/invalid_module.yaml')
        ..writeAsStringSync('id: 123\n');
      final err = StringBuffer();
      final code = await FtemplateCommandRunner(manifestsDir: '../../manifests')
          .run(['validate', '--manifest', invalid.path], err: err.writeln);

      expect(code, 65);
      expect(err.toString(), contains('Invalid manifest'));
    });
  });

  group('create', () {
    test('prints the plan for a blank project', () async {
      final out = StringBuffer();
      final code = await runner.run([
        'create',
        '--name',
        'My App',
        '--org',
        'com.example',
        '--preset',
        'blank',
        '--dry-run',
      ], out: out.writeln);

      expect(code, 0);
      expect(out.toString(), contains('Project: My App'));
      expect(out.toString(), contains('Package: my_app'));
      expect(out.toString(), contains('Application ID: com.example.my_app'));
      expect(out.toString(), contains('Modules: architecture-core'));
      expect(out.toString(), contains('Backend: none'));
      expect(out.toString(), contains('Dry run'));
    });

    test('maps the REST backend to the existing networking module', () async {
      final out = StringBuffer();
      final code = await runner.run([
        'create',
        '--name',
        'REST App',
        '--org',
        'com.example',
        '--backend',
        'rest',
        '--dry-run',
      ], out: out.writeln);

      expect(code, 0);
      expect(out.toString(), contains('Backend: rest'));
      expect(out.toString(), contains('networking'));
      expect(out.toString(), contains('dio: ^5.11.1'));
    });

    test('selects Firestore independently from Supabase authentication', () async {
      final out = StringBuffer();
      final code = await runner.run([
        'create',
        '--name',
        'Firebase Data App',
        '--org',
        'com.example',
        '--backend',
        'firebase',
        '--auth',
        'supabase',
        '--dry-run',
      ], out: out.writeln);

      expect(code, 0);
      expect(out.toString(), contains('Backend: firebase'));
      expect(out.toString(), contains('Authentication: auth-supabase'));
      expect(out.toString(), contains('backend-firestore'));
      expect(out.toString(), contains('auth-supabase'));
    });

    test('selects the Supabase backend without selecting its auth adapter', () async {
      final out = StringBuffer();
      final code = await runner.run([
        'create',
        '--name',
        'Supabase Data App',
        '--org',
        'com.example',
        '--backend',
        'supabase',
        '--dry-run',
      ], out: out.writeln);

      expect(code, 0);
      expect(out.toString(), contains('Backend: supabase'));
      expect(out.toString(), contains('backend-supabase'));
      expect(out.toString(), contains('Authentication: none'));
      expect(out.toString(), isNot(contains('auth-supabase')));
    });

    test('reports a provider backend selected directly as a module', () async {
      final out = StringBuffer();
      final code = await runner.run([
        'create',
        '--name',
        'Direct Backend App',
        '--org',
        'com.example',
        '--module',
        'backend-firestore',
        '--dry-run',
      ], out: out.writeln);

      expect(code, 0);
      expect(out.toString(), contains('Backend: firebase'));
    });

    test('rejects unknown backend choices', () async {
      final err = StringBuffer();
      final code = await runner.run([
        'create',
        '--name',
        'My App',
        '--org',
        'com.example',
        '--backend',
        'magic',
        '--dry-run',
      ], err: err.writeln);

      expect(code, 64);
      expect(err.toString(), contains('Invalid --backend value "magic"'));
      expect(err.toString(), contains('none, rest, firebase, supabase'));
    });

    test('rejects conflicting provider backends before writing output', () async {
      final parent = await Directory.systemTemp.createTemp('ftemplate_backend_conflict_');
      try {
        for (final scenario in <String, String>{
          'firebase': 'backend-supabase',
          'supabase': 'backend-firestore',
        }.entries) {
          final destination = Directory(p.join(parent.path, scenario.key));
          final err = StringBuffer();
          final code = await runner.run([
            'create',
            '--name',
            'Conflict App',
            '--org',
            'com.example',
            '--backend',
            scenario.key,
            '--module',
            scenario.value,
            '--output',
            destination.path,
          ], err: err.writeln);

          expect(code, 64);
          expect(err.toString(), contains('conflict'));
          expect(destination.existsSync(), isFalse);
        }
      } finally {
        await parent.delete(recursive: true);
      }
    });

    test('explicit no-backend selection rejects provider modules before writing', () async {
      final parent = await Directory.systemTemp.createTemp('ftemplate_backend_none_');
      final destination = Directory(p.join(parent.path, 'generated'));
      final err = StringBuffer();
      try {
        final code = await runner.run([
          'create',
          '--name',
          'No Backend App',
          '--org',
          'com.example',
          '--backend',
          'none',
          '--module',
          'backend-firestore',
          '--output',
          destination.path,
        ], err: err.writeln);

        expect(code, 64);
        expect(err.toString(), contains('--backend none'));
        expect(destination.existsSync(), isFalse);
      } finally {
        await parent.delete(recursive: true);
      }
    });

    test('creates output on the requested filesystem', () async {
      final parent = await Directory.current.createTemp('ftemplate_output_volume_');
      final destination = Directory(p.join(parent.path, 'generated'));
      try {
        final code = await runner.run([
          'create',
          '--name',
          'Generated App',
          '--org',
          'com.example',
          '--preset',
          'blank',
          '--brick-dir',
          '../../bricks/project',
          '--output',
          destination.path,
        ]);

        expect(code, 0);
        expect(File(p.join(destination.path, 'pubspec.yaml')).existsSync(), isTrue);
      } finally {
        await parent.delete(recursive: true);
      }
    });

    test('reports selected Android permissions and native changes in dry-run output', () async {
      final out = StringBuffer();
      final code = await runner.run([
        'create',
        '--name',
        'Alerts App',
        '--org',
        'com.example',
        '--module',
        'local-notifications',
        '--dry-run',
      ], out: out.writeln);

      expect(code, 0);
      expect(
        out.toString(),
        contains('Permissions: android.permission.POST_NOTIFICATIONS, android.permission.VIBRATE'),
      );
      expect(
        out.toString(),
        contains(
          'Android native changes: android/app/src/main/AndroidManifest.xml: '
          'declare POST_NOTIFICATIONS and VIBRATE for the selected module.',
        ),
      );
    });

    test('rejects Android-only modules for iOS before writing output', () async {
      final parent = await Directory.systemTemp.createTemp('ftemplate_platform_test_');
      final destination = Directory('${parent.path}/generated');
      final err = StringBuffer();
      try {
        final code = await runner.run([
          'create',
          '--name',
          'Alerts App',
          '--org',
          'com.example',
          '--platforms',
          'ios',
          '--module',
          'local-notifications',
          '--brick-dir',
          '../../bricks/project',
          '--output',
          destination.path,
        ], err: err.writeln);

        expect(code, 64);
        expect(err.toString(), contains('local-notifications'));
        expect(err.toString(), contains('ios'));
        expect(destination.existsSync(), isFalse);
      } finally {
        await parent.delete(recursive: true);
      }
    });

    test('rejects the full Android preset for iOS before writing output', () async {
      final parent = await Directory.systemTemp.createTemp('ftemplate_full_preset_platform_');
      final destination = Directory(p.join(parent.path, 'generated'));
      final err = StringBuffer();
      try {
        final code = await runner.run([
          'create',
          '--name',
          'Full App',
          '--org',
          'com.example',
          '--preset',
          'full',
          '--platforms',
          'ios',
          '--output',
          destination.path,
        ], err: err.writeln);

        expect(code, 64);
        expect(err.toString(), contains('does not support'));
        expect(err.toString(), contains('ios'));
        expect(destination.existsSync(), isFalse);
      } finally {
        await parent.delete(recursive: true);
      }
    });

    test('rejects Firestore for iOS before writing output', () async {
      final parent = await Directory.systemTemp.createTemp('ftemplate_firestore_platform_test_');
      final destination = Directory('${parent.path}/generated');
      final err = StringBuffer();
      try {
        final code = await runner.run([
          'create',
          '--name',
          'Firestore App',
          '--org',
          'com.example',
          '--platforms',
          'ios',
          '--module',
          'backend-firestore',
          '--brick-dir',
          '../../bricks/project',
          '--output',
          destination.path,
        ], err: err.writeln);

        expect(code, 64);
        expect(err.toString(), contains('backend-firestore'));
        expect(err.toString(), contains('ios'));
        expect(destination.existsSync(), isFalse);
      } finally {
        await parent.delete(recursive: true);
      }
    });

    test('plans a core project with resolved modules', () async {
      final out = StringBuffer();
      final code = await runner.run([
        'create',
        '--name',
        'Shop App',
        '--org',
        'com.example',
        '--preset',
        'core',
        '--dry-run',
      ], out: out.writeln);

      expect(code, 0);
      expect(
        out.toString(),
        contains(
          'Modules: architecture-core, state-riverpod, navigation, '
          'design-system, feature-example',
        ),
      );
      expect(out.toString(), contains('flutter_riverpod'));
      expect(out.toString(), contains('go_router'));
    });

    test('plans a demo project with the showcase feature', () async {
      final out = StringBuffer();
      final code = await runner.run([
        'create',
        '--name',
        'Demo App',
        '--org',
        'com.example',
        '--preset',
        'demo',
        '--dry-run',
      ], out: out.writeln);

      expect(code, 0);
      expect(out.toString(), contains('showcase'));
    });

    test('selects no authentication provider by default', () async {
      final out = StringBuffer();
      final code = await runner.run([
        'create',
        '--name',
        'My App',
        '--org',
        'com.example',
        '--preset',
        'blank',
        '--dry-run',
      ], out: out.writeln);

      expect(code, 0);
      expect(out.toString(), contains('Authentication: none'));
    });

    test('selects the REST authentication adapter', () async {
      final out = StringBuffer();
      final code = await runner.run([
        'create',
        '--name',
        'My App',
        '--org',
        'com.example',
        '--preset',
        'blank',
        '--auth',
        'rest',
        '--dry-run',
      ], out: out.writeln);

      expect(code, 0);
      expect(out.toString(), contains('auth-rest'));
      expect(out.toString(), contains('Authentication: auth-rest'));
      expect(out.toString(), contains('email-password-sign-in'));
    });

    test('selects the Firebase authentication adapter', () async {
      final out = StringBuffer();
      final code = await runner.run([
        'create',
        '--name',
        'My App',
        '--org',
        'com.example',
        '--preset',
        'blank',
        '--auth',
        'firebase',
        '--dry-run',
      ], out: out.writeln);

      expect(code, 0);
      expect(out.toString(), contains('auth-firebase'));
      expect(out.toString(), contains('firebase_auth: ^7.0.0'));
      expect(out.toString(), contains('one-time-password-sign-in'));
    });

    test('rejects an unknown authentication provider', () async {
      final err = StringBuffer();
      final code = await runner.run([
        'create',
        '--name',
        'My App',
        '--org',
        'com.example',
        '--auth',
        'magic',
        '--dry-run',
      ], err: err.writeln);

      expect(code, 64);
      expect(err.toString(), contains('Invalid --auth value "magic"'));
      expect(err.toString(), contains('none, rest, firebase, supabase'));
    });

    test('accepts a capability the selected provider implements', () async {
      final out = StringBuffer();
      final code = await runner.run([
        'create',
        '--name',
        'My App',
        '--org',
        'com.example',
        '--preset',
        'blank',
        '--auth',
        'firebase',
        '--auth-capability',
        'one-time-password-sign-in',
        '--dry-run',
      ], out: out.writeln);

      expect(code, 0);
      expect(out.toString(), contains('Authentication: auth-firebase'));
    });

    test('rejects a capability the selected provider does not implement', () async {
      final err = StringBuffer();
      final code = await runner.run([
        'create',
        '--name',
        'My App',
        '--org',
        'com.example',
        '--preset',
        'blank',
        '--auth',
        'rest',
        '--auth-capability',
        'one-time-password-sign-in',
        '--dry-run',
      ], err: err.writeln);

      expect(code, 64);
      expect(err.toString(), contains('one-time-password-sign-in'));
      expect(err.toString(), contains('auth-firebase'));
      expect(err.toString(), contains('auth-supabase'));
    });

    test('rejects an unknown capability', () async {
      final err = StringBuffer();
      final code = await runner.run([
        'create',
        '--name',
        'My App',
        '--org',
        'com.example',
        '--preset',
        'blank',
        '--auth',
        'rest',
        '--auth-capability',
        'telepathy',
        '--dry-run',
      ], err: err.writeln);

      expect(code, 64);
      expect(err.toString(), contains('Unknown capability "telepathy"'));
    });

    test('rejects a capability when no provider is selected', () async {
      final err = StringBuffer();
      final code = await runner.run([
        'create',
        '--name',
        'My App',
        '--org',
        'com.example',
        '--preset',
        'blank',
        '--auth-capability',
        'email-password-sign-in',
        '--dry-run',
      ], err: err.writeln);

      expect(code, 64);
      expect(err.toString(), contains('email-password-sign-in'));
    });

    test('rejects two authentication providers', () async {
      final err = StringBuffer();
      final code = await runner.run([
        'create',
        '--name',
        'My App',
        '--org',
        'com.example',
        '--preset',
        'blank',
        '--auth',
        'firebase',
        '--module',
        'auth-supabase',
        '--dry-run',
      ], err: err.writeln);

      expect(code, 64);
      expect(err.toString(), contains('conflict'));
    });

    test('rejects an invalid project name', () async {
      final err = StringBuffer();
      final code = await runner.run([
        'create',
        '--name',
        '123',
        '--org',
        'com.example',
      ], err: err.writeln);

      expect(code, 64);
      expect(err.toString(), contains('Invalid project name'));
    });

    test('rejects an unknown preset', () async {
      final err = StringBuffer();
      final code = await runner.run([
        'create',
        '--name',
        'My App',
        '--org',
        'com.example',
        '--preset',
        'does-not-exist',
      ], err: err.writeln);

      expect(code, 64);
      expect(err.toString(), contains('Unknown preset'));
    });

    test('refuses to overwrite a non-empty directory without --force', () async {
      final dir = Directory('${Directory.systemTemp.path}/nonempty_test')..createSync();
      File('${dir.path}/existing.txt').writeAsStringSync('keep me');

      final err = StringBuffer();
      final code = await runner.run([
        'create',
        '--name',
        'My App',
        '--org',
        'com.example',
        '--output',
        dir.path,
      ], err: err.writeln);

      expect(code, 64);
      expect(err.toString(), contains('is not empty'));
      expect(File('${dir.path}/existing.txt').existsSync(), isTrue);
      dir.deleteSync(recursive: true);
    });

    test('overwrites a non-empty directory with --force', () async {
      final dir = Directory('${Directory.systemTemp.path}/force_test')..createSync();
      File('${dir.path}/existing.txt').writeAsStringSync('delete me');

      final out = StringBuffer();
      final code = await runner.run([
        'create',
        '--name',
        'My App',
        '--org',
        'com.example',
        '--output',
        dir.path,
        '--force',
        '--brick-dir',
        '../../bricks/project',
      ], out: out.writeln);

      expect(code, 0);
      expect(File('${dir.path}/pubspec.yaml').existsSync(), isTrue);
      dir.deleteSync(recursive: true);
    });
  });
}
