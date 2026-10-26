// Regenerates `THIRD-PARTY-NOTICES.md` from the committed lockfiles.
//
// The licence of every package is detected from the `LICENSE` file of the
// resolved package in the pub cache, so the inventory reflects the bytes that
// are actually used rather than a hand-maintained list.
//
// Usage:
//
//   dart run tool/ftemplate_cli/tool/license_inventory.dart
//   dart run tool/ftemplate_cli/tool/license_inventory.dart --check
//
// A package whose licence cannot be detected is reported as `UNKNOWN` and
// makes the check fail. Add an explicit entry to `tool/package_licenses.yaml`
// for such a package.

import 'dart:io';

import 'package:yaml/yaml.dart';

const String noticesFileName = 'THIRD-PARTY-NOTICES.md';

const String overridesFileName = 'tool/package_licenses.yaml';

/// The lockfiles the inventory covers.
const List<String> lockfilePaths = <String>[
  'pubspec.lock',
  'tool/ftemplate_cli/pubspec.lock',
  'tool/module_dependency_audit/pubspec.lock',
];

/// A package resolved by a lockfile.
class LockedPackage {
  const LockedPackage({
    required this.name,
    required this.version,
    required this.dependency,
    required this.source,
  });

  final String name;
  final String version;
  final String dependency;
  final String source;

  /// Whether the package is a direct dependency of its project.
  bool get isDirect => dependency.startsWith('direct');

  /// The directory that holds the resolved package, or `null` when it is not
  /// a hosted package.
  Directory? get directory => _hostedDirectory(name, version);

  static Directory? _hostedDirectory(String packageName, String packageVersion) {
    for (final cache in pubCacheDirectories()) {
      final hosted = Directory('${cache.path}${Platform.pathSeparator}hosted');
      if (!hosted.existsSync()) {
        continue;
      }
      final expected = '$packageName-$packageVersion';
      for (final host in hosted.listSync().whereType<Directory>()) {
        final candidate = Directory('${host.path}${Platform.pathSeparator}$expected');
        if (candidate.existsSync()) {
          return candidate;
        }
      }
    }
    return null;
  }
}

/// The pub cache directory of the current machine.
List<Directory> pubCacheDirectories() {
  final result = <Directory>[];
  final configured = Platform.environment['PUB_CACHE'];
  if (configured != null && configured.isNotEmpty) {
    result.add(Directory(configured));
  }
  if (Platform.isWindows) {
    final local = Platform.environment['LOCALAPPDATA'];
    if (local != null && local.isNotEmpty) {
      result.add(Directory('$local${Platform.pathSeparator}Pub${Platform.pathSeparator}Cache'));
    }
  }
  final home = Platform.environment['HOME'];
  if (home != null && home.isNotEmpty) {
    result.add(Directory('$home${Platform.pathSeparator}.pub-cache'));
  }
  final paths = <String>{};
  return result.where((directory) => paths.add(directory.path)).toList(growable: false);
}

/// Detects the SPDX identifier of a licence text.
String detectLicense(String text) {
  final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  final lower = normalized.toLowerCase();

  if (lower.contains('apache license') && lower.contains('version 2.0')) {
    return 'Apache-2.0';
  }
  if (lower.contains('mozilla public license') && lower.contains('version 2.0')) {
    return 'MPL-2.0';
  }
  if (lower.contains('gnu lesser general public license')) {
    return 'LGPL-3.0';
  }
  if (lower.contains('gnu general public license')) {
    return 'GPL-3.0';
  }
  if (lower.contains('this is free and unencumbered software released into the public domain')) {
    return 'Unlicense';
  }
  if (lower.contains(
    'permission to use, copy, modify, and/or distribute this software for any purpose with or without',
  )) {
    return '0BSD';
  }
  if (lower.contains(
    'permission to use, copy, modify, and/or distribute this software for any purpose',
  )) {
    return 'ISC';
  }
  if (lower.contains('redistribution and use in source and binary forms')) {
    if (lower.contains('all advertising materials')) {
      return 'BSD-4-Clause';
    }
    if (lower.contains('neither the name')) {
      return 'BSD-3-Clause';
    }
    return 'BSD-2-Clause';
  }
  if (lower.contains('permission is hereby granted, free of charge')) {
    return 'MIT';
  }
  return 'UNKNOWN';
}

/// Reads the licence text of [package] from its resolved directory.
String? readLicenseText(LockedPackage package) {
  final directory = package.directory;
  if (directory == null || !directory.existsSync()) {
    return null;
  }
  for (final name in const <String>[
    'LICENSE',
    'LICENSE.md',
    'LICENSE.txt',
    'LICENSE-MIT',
    'LICENSE-APACHE',
    'COPYING',
  ]) {
    final file = File('${directory.path}${Platform.pathSeparator}$name');
    if (file.existsSync()) {
      return file.readAsStringSync();
    }
  }
  return null;
}

/// Reads the explicit licence overrides.
Map<String, String> readOverrides(String repositoryRoot) {
  final file = File('$repositoryRoot${Platform.pathSeparator}$overridesFileName');
  if (!file.existsSync()) {
    return const <String, String>{};
  }
  final decoded = loadYaml(file.readAsStringSync());
  if (decoded is! YamlMap) {
    return const <String, String>{};
  }
  return <String, String>{
    for (final entry in decoded.entries) entry.key.toString(): entry.value.toString(),
  };
}

/// Reads the packages of a lockfile.
List<LockedPackage> readLockfile(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return const <LockedPackage>[];
  }
  final decoded = loadYaml(file.readAsStringSync());
  if (decoded is! YamlMap) {
    return const <LockedPackage>[];
  }
  final packages = decoded['packages'];
  if (packages is! YamlMap) {
    return const <LockedPackage>[];
  }
  return <LockedPackage>[
    for (final entry in packages.entries)
      LockedPackage(
        name: entry.key.toString(),
        version: (entry.value['version'] ?? '').toString(),
        dependency: (entry.value['dependency'] ?? 'transitive').toString(),
        source: (entry.value['source'] ?? 'unknown').toString(),
      ),
  ];
}

/// Builds the inventory text.
String buildNotices(
  Map<String, String> inventory, {
  required Map<String, String> overrides,
  required Set<String> unknown,
}) {
  final buffer = StringBuffer()
    ..writeln('# Third-party notices')
    ..writeln()
    ..writeln(
      'This file is generated. Run '
      '`dart run tool/ftemplate_cli/tool/license_inventory.dart` to '
      'regenerate it from the committed lockfiles, and '
      '`dart run tool/ftemplate_cli/tool/license_inventory.dart --check` to '
      'verify that it is current.',
    )
    ..writeln()
    ..writeln(
      'The licence of each package is detected from the `LICENSE` file of the '
      'resolved package in the pub cache.',
    )
    ..writeln()
    ..writeln('| Package | Version | Scope | Licence |')
    ..writeln('| --- | --- | --- | --- |');
  for (final name in inventory.keys.toList()..sort()) {
    final entry = inventory[name]!;
    final parts = entry.split('|');
    buffer.writeln('| `${parts[0]}` | ${parts[1]} | ${parts[2]} | ${parts[3]} |');
  }
  if (unknown.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## Packages with an undetected licence')
      ..writeln()
      ..writeln(
        'The licence of the following packages could not be detected from their '
        '`LICENSE` file. Record their licence in '
        '`$overridesFileName` before publishing a release.',
      )
      ..writeln();
    for (final name in unknown.toList()..sort()) {
      buffer.writeln('- `$name`');
    }
  }
  return buffer.toString();
}

/// Locates the repository root from the script location.
String findRepositoryRoot() {
  var directory = File(Platform.script.toFilePath()).parent;
  while (true) {
    if (Directory('${directory.path}${Platform.pathSeparator}manifests').existsSync()) {
      return directory.path;
    }
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError(
        'Could not locate the repository root. Run this script from the '
        'repository.',
      );
    }
    directory = parent;
  }
}

Future<void> main(List<String> arguments) async {
  final check = arguments.contains('--check');
  final root = findRepositoryRoot();
  final overrides = readOverrides(root);

  final inventory = <String, String>{};
  final unknown = <String>{};
  for (final lockfile in lockfilePaths) {
    final path = '$root${Platform.pathSeparator}$lockfile';
    for (final package in readLockfile(path)) {
      if (package.source != 'hosted') {
        continue;
      }
      final override = overrides[package.name];
      String licence;
      if (override != null) {
        licence = override;
      } else {
        final text = readLicenseText(package);
        licence = text == null ? 'UNKNOWN' : detectLicense(text);
      }
      if (licence == 'UNKNOWN') {
        unknown.add(package.name);
      }
      final scope = package.isDirect ? 'direct' : 'transitive';
      inventory[package.name] = '${package.name}|${package.version}|$scope|$licence';
    }
  }

  final notices = buildNotices(inventory, overrides: overrides, unknown: unknown);
  final target = File('$root${Platform.pathSeparator}$noticesFileName');

  if (check) {
    final current = target.existsSync() ? target.readAsStringSync() : '';
    if (current != notices) {
      stderr.writeln(
        '$noticesFileName is out of date. Run "dart run tool/license_inventory.dart".',
      );
      exitCode = 1;
      return;
    }
    stdout.writeln('$noticesFileName is current (${inventory.length} packages).');
    if (unknown.isNotEmpty) {
      stderr.writeln(
        'The licence of ${unknown.length} package(s) could not be detected: '
        '${unknown.join(', ')}.',
      );
      exitCode = 1;
    }
    return;
  }

  target.writeAsStringSync(notices);
  stdout.writeln(
    'Wrote $noticesFileName (${inventory.length} packages).'
    '${unknown.isEmpty ? '' : ' ${unknown.length} package(s) have an undetected licence.'}',
  );
}
