import 'dart:io';

import 'package:path/path.dart' as p;

import 'module_manifest.dart';

/// Loads module manifests and presets from the `manifests/` directory.
class ManifestRepository {
  ManifestRepository({required this.manifestsDir});

  final String manifestsDir;

  Iterable<File> _yamlFiles(Directory directory) {
    if (!directory.existsSync()) {
      throw FormatException('Directory not found: ${directory.path}');
    }
    return directory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.yaml'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  }

  /// Loads every module manifest, sorted by ID.
  List<ModuleManifest> loadModules() => _yamlFiles(Directory(
    p.join(manifestsDir, 'modules'),
  ))
      .map((file) => loadModuleManifest(file.readAsStringSync()))
      .toList();

  /// Loads every preset, sorted by ID.
  List<Preset> loadPresets() => _yamlFiles(Directory(
    p.join(manifestsDir, 'presets'),
  ))
      .map((file) => loadPreset(file.readAsStringSync()))
      .toList();

  /// Loads a single module manifest from an arbitrary path.
  ModuleManifest loadModuleFromFile(String path) =>
      loadModuleManifest(File(path).readAsStringSync());

  /// Looks up a loaded module by ID.
  ModuleManifest? moduleById(String id, List<ModuleManifest> modules) {
    for (final module in modules) {
      if (module.id == id) {
        return module;
      }
    }
    return null;
  }

  /// Looks up a loaded preset by ID.
  Preset? presetById(String id, List<Preset> presets) {
    for (final preset in presets) {
      if (preset.id == id) {
        return preset;
      }
    }
    return null;
  }
}
