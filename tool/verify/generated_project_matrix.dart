import 'dart:convert';
import 'dart:io';

const _presets = {'blank', 'core', 'demo', 'recommended', 'commerce', 'full'};
const _authProviders = {'none', 'rest', 'firebase', 'supabase'};
const _backends = {'none', 'rest', 'firebase', 'supabase'};
const Map<String, Map<String, Object?>> _requiredCases = {
  'blank': {
    'preset': 'blank',
    'auth': 'none',
    'backend': 'none',
    'modules': <String>[],
    'expects_network': false,
    'expects_notifications': false,
  },
  'core': {
    'preset': 'core',
    'auth': 'none',
    'backend': 'none',
    'modules': <String>[],
    'expects_network': false,
    'expects_notifications': false,
  },
  'demo': {
    'preset': 'demo',
    'auth': 'none',
    'backend': 'none',
    'modules': <String>[],
    'expects_network': false,
    'expects_notifications': false,
  },
  'demo-localization': {
    'preset': 'demo',
    'auth': 'none',
    'backend': 'none',
    'modules': <String>['localization'],
    'expects_network': false,
    'expects_notifications': false,
  },
  'recommended': {
    'preset': 'recommended',
    'auth': 'none',
    'backend': 'none',
    'modules': <String>[],
    'expects_network': true,
    'expects_notifications': false,
  },
  'commerce-module': {
    'preset': 'blank',
    'auth': 'none',
    'backend': 'none',
    'modules': <String>['commerce'],
    'expects_network': false,
    'expects_notifications': false,
  },
  'commerce-preset': {
    'preset': 'commerce',
    'auth': 'none',
    'backend': 'none',
    'modules': <String>[],
    'expects_network': true,
    'expects_notifications': false,
  },
  'full-preset': {
    'preset': 'full',
    'auth': 'none',
    'backend': 'none',
    'modules': <String>[],
    'expects_network': true,
    'expects_notifications': true,
  },
  'auth-rest': {
    'preset': 'core',
    'auth': 'rest',
    'backend': 'none',
    'modules': <String>[],
    'expects_network': true,
    'expects_notifications': false,
  },
  'auth-firebase': {
    'preset': 'core',
    'auth': 'firebase',
    'backend': 'none',
    'modules': <String>[],
    'expects_network': true,
    'expects_notifications': false,
  },
  'auth-supabase': {
    'preset': 'core',
    'auth': 'supabase',
    'backend': 'none',
    'modules': <String>[],
    'expects_network': true,
    'expects_notifications': false,
  },
  'backend-rest': {
    'preset': 'blank',
    'auth': 'none',
    'backend': 'rest',
    'modules': <String>[],
    'expects_network': true,
    'expects_notifications': false,
  },
  'backend-firestore': {
    'preset': 'blank',
    'auth': 'none',
    'backend': 'firebase',
    'modules': <String>[],
    'expects_network': true,
    'expects_notifications': false,
  },
  'backend-supabase': {
    'preset': 'blank',
    'auth': 'none',
    'backend': 'supabase',
    'modules': <String>[],
    'expects_network': true,
    'expects_notifications': false,
  },
  'firebase-auth-firestore': {
    'preset': 'core',
    'auth': 'firebase',
    'backend': 'firebase',
    'modules': <String>[],
    'expects_network': true,
    'expects_notifications': false,
  },
  'supabase-auth-data': {
    'preset': 'core',
    'auth': 'supabase',
    'backend': 'supabase',
    'modules': <String>[],
    'expects_network': true,
    'expects_notifications': false,
  },
  'full-maximum': {
    'preset': 'full',
    'auth': 'firebase',
    'backend': 'firebase',
    'modules': <String>[],
    'expects_network': true,
    'expects_notifications': true,
  },
  'preferences': {
    'preset': 'blank',
    'auth': 'none',
    'backend': 'none',
    'modules': <String>['preferences'],
    'expects_network': false,
    'expects_notifications': false,
  },
  'local-database': {
    'preset': 'blank',
    'auth': 'none',
    'backend': 'none',
    'modules': <String>['local-database'],
    'expects_network': false,
    'expects_notifications': false,
  },
  'offline-data': {
    'preset': 'blank',
    'auth': 'none',
    'backend': 'none',
    'modules': <String>['offline-data'],
    'expects_network': true,
    'expects_notifications': false,
  },
  'commerce-persistence': {
    'preset': 'blank',
    'auth': 'none',
    'backend': 'none',
    'modules': <String>['commerce-persistence'],
    'expects_network': false,
    'expects_notifications': false,
  },
  'background-work': {
    'preset': 'blank',
    'auth': 'none',
    'backend': 'none',
    'modules': <String>['background-work'],
    'expects_network': false,
    'expects_notifications': false,
  },
  'local-notifications': {
    'preset': 'blank',
    'auth': 'none',
    'backend': 'none',
    'modules': <String>['local-notifications'],
    'expects_network': false,
    'expects_notifications': true,
  },
  'app-updates': {
    'preset': 'blank',
    'auth': 'none',
    'backend': 'none',
    'modules': <String>['app-updates'],
    'expects_network': false,
    'expects_notifications': false,
  },
  'background-work-notifications': {
    'preset': 'blank',
    'auth': 'none',
    'backend': 'none',
    'modules': <String>['background-work', 'local-notifications'],
    'expects_network': false,
    'expects_notifications': true,
  },
};

List<Map<String, Object?>> validateMatrix(Object? document) {
  if (document is! Map<String, dynamic> || document['cases'] is! List) {
    throw const FormatException('Matrix must be an object with a cases array.');
  }

  final cases = <Map<String, Object?>>[];
  final names = <String>{};
  for (final entry in document['cases'] as List<Object?>) {
    if (entry is! Map<String, dynamic>) {
      throw const FormatException('Every matrix case must be an object.');
    }

    final name = entry['name'];
    final preset = entry['preset'];
    final auth = entry['auth'];
    final backend = entry['backend'];
    final modules = entry['modules'];
    if (name is! String ||
        !RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(name) ||
        !names.add(name)) {
      throw FormatException(
        'Matrix case names must be non-empty and unique: $name',
      );
    }
    if (preset is! String || !_presets.contains(preset)) {
      throw FormatException(
        'Matrix case "$name" has an unknown preset: $preset',
      );
    }
    if (auth is! String || !_authProviders.contains(auth)) {
      throw FormatException(
        'Matrix case "$name" has an unknown auth provider: $auth',
      );
    }
    if (backend is! String || !_backends.contains(backend)) {
      throw FormatException(
        'Matrix case "$name" has an unknown backend: $backend',
      );
    }
    if (modules is! List<Object?> ||
        modules.any((module) => module is! String)) {
      throw FormatException(
        'Matrix case "$name" modules must be a list of strings.',
      );
    }
    if (modules.any(
      (module) =>
          !RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(module as String),
    )) {
      throw FormatException(
        'Matrix case "$name" contains an invalid module ID.',
      );
    }
    if (entry['expects_network'] is! bool ||
        entry['expects_notifications'] is! bool) {
      throw FormatException(
        'Matrix case "$name" must declare permission expectations.',
      );
    }
    cases.add(Map<String, Object?>.from(entry));
  }

  if (cases.isEmpty) {
    throw const FormatException(
      'Generated-project matrix must contain at least one case.',
    );
  }
  final requiredCaseNames = _requiredCases.keys.toSet();
  final missingCases = requiredCaseNames.difference(names);
  final unexpectedCases = names.difference(requiredCaseNames);
  if (missingCases.isNotEmpty || unexpectedCases.isNotEmpty) {
    throw FormatException(
      'Generated-project matrix case set mismatch. '
      'Missing: ${missingCases.join(', ')}. Unexpected: ${unexpectedCases.join(', ')}.',
    );
  }

  for (final entry in cases) {
    final name = entry['name'] as String;
    final expected = _requiredCases[name]!;
    for (final field in const [
      'preset',
      'auth',
      'backend',
      'expects_network',
      'expects_notifications',
    ]) {
      if (entry[field] != expected[field]) {
        throw FormatException(
          'Generated-project matrix case "$name" has an invalid "$field".',
        );
      }
    }

    final modules = entry['modules'] as List<Object?>;
    final expectedModules = expected['modules'] as List<String>;
    if (modules.length != expectedModules.length ||
        !List.generate(
          modules.length,
          (index) => modules[index] == expectedModules[index],
        ).every((matches) => matches)) {
      throw FormatException(
        'Generated-project matrix case "$name" has an invalid module list.',
      );
    }
  }

  return cases;
}

int countPassedTestEvents(Iterable<String> lines) {
  var passed = 0;
  var skipped = 0;
  var failed = 0;
  var completedSuccessfully = false;
  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    final event = jsonDecode(line);
    if (event is! Map<String, dynamic>) {
      throw const FormatException(
        'Flutter test output contains a non-object JSON event.',
      );
    }
    if (event['type'] == 'testDone' && event['hidden'] != true) {
      if (event['skipped'] == true) {
        skipped++;
      } else if (event['result'] == 'success') {
        passed++;
      } else {
        failed++;
      }
    } else if (event['type'] == 'done') {
      completedSuccessfully = event['success'] == true;
    }
  }

  if (!completedSuccessfully) {
    throw const FormatException(
      'Flutter test output has no successful completion event.',
    );
  }
  if (passed == 0) {
    throw const FormatException(
      'Generated-project test run executed zero visible tests.',
    );
  }
  if (skipped > 0 || failed > 0) {
    throw FormatException(
      'Generated-project tests include $skipped skips and $failed failures.',
    );
  }
  return passed;
}

Future<void> main(List<String> args) async {
  try {
    if (args.length == 1 && args.single == '--check') {
      final cases = validateMatrix(
        jsonDecode(
          await File.fromUri(
            Platform.script.resolve('generated_project_matrix.json'),
          ).readAsString(),
        ),
      );
      stdout.writeln('Generated-project matrix valid: ${cases.length} cases.');
      return;
    }
    if (args.length == 2 && args[0] == '--github-output') {
      final cases = validateMatrix(
        jsonDecode(
          await File.fromUri(
            Platform.script.resolve('generated_project_matrix.json'),
          ).readAsString(),
        ),
      );
      final output = File(args[1]);
      await output.writeAsString(
        'include=${jsonEncode(cases)}\ncount=${cases.length}\n',
        mode: FileMode.append,
      );
      stdout.writeln('Enumerated ${cases.length} generated-project cases.');
      return;
    }
    if (args.length == 2 && args[0] == '--check-test-results') {
      final count = countPassedTestEvents(await File(args[1]).readAsLines());
      stdout.writeln(
        'Generated-project tests executed: $count passed, 0 skipped.',
      );
      return;
    }
    stderr.writeln(
      'Usage: dart generated_project_matrix.dart --check | '
      '--github-output <path> | --check-test-results <jsonl>',
    );
    exitCode = 64;
  } on FormatException catch (error) {
    stderr.writeln('Generated-project matrix check failed: ${error.message}');
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('Generated-project matrix check failed: ${error.message}');
    exitCode = 1;
  }
}
