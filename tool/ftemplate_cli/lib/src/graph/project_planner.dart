import '../manifest/manifest_repository.dart';
import '../manifest/module_manifest.dart';
import '../models/generation_plan.dart';
import '../models/project_spec.dart';
import 'compatibility_exception.dart';
import 'compatibility_graph.dart';

/// Resolves a [ProjectSpec] into a validated [GenerationPlan].
class ProjectPlanner {
  ProjectPlanner(this._repository);

  final ManifestRepository _repository;

  /// Plans the generation, throwing [CompatibilityException] when the
  /// selection cannot be resolved.
  GenerationPlan plan(ProjectSpec spec) {
    final modules = _repository.loadModules();
    final presets = _repository.loadPresets();

    if (spec.platforms.isEmpty) {
      throw CompatibilityException('Select at least one target platform: android or ios.');
    }
    for (final platform in spec.platforms.toSet()) {
      if (!_supportedPlatforms.contains(platform)) {
        throw CompatibilityException(
          'Unsupported target platform "$platform". Supported platforms: '
          '${_supportedPlatforms.join(', ')}.',
        );
      }
    }

    final preset = _repository.presetById(spec.preset, presets);
    if (preset == null) {
      throw CompatibilityException(
        'Unknown preset "${spec.preset}". Run `ftemplate list-modules` to '
        'see the available presets.',
      );
    }

    final selected = <String>[...preset.modules, ...spec.modules];
    final graph = CompatibilityGraph(modules);
    final resolved = graph.resolve(selected);

    for (final module in resolved) {
      final unsupported = spec.platforms.toSet().difference(module.platforms.toSet());
      if (unsupported.isNotEmpty) {
        throw CompatibilityException(
          'Module "${module.id}" does not support the requested platform(s): '
          '${unsupported.join(', ')}. Supported platforms: ${module.platforms.join(', ')}.',
        );
      }
    }

    final dependencies = <PubDependency>[];
    final devDependencies = <PubDependency>[];
    final permissions = <String>[];
    final configKeys = <String>[];
    final androidNativeChanges = <String>[];
    final iosNativeChanges = <String>[];
    for (final module in resolved) {
      for (final dependency in module.pubDependencies) {
        if (!dependencies.contains(dependency)) {
          dependencies.add(dependency);
        }
      }
      for (final dependency in module.devDependencies) {
        if (!devDependencies.contains(dependency)) {
          devDependencies.add(dependency);
        }
      }
      for (final permission in module.permissions) {
        if (!permissions.contains(permission)) {
          permissions.add(permission);
        }
      }
      for (final key in module.configKeys) {
        if (!configKeys.contains(key)) {
          configKeys.add(key);
        }
      }
      if (spec.platforms.contains('android')) {
        for (final change in module.nativeChanges.android) {
          if (!androidNativeChanges.contains(change)) {
            androidNativeChanges.add(change);
          }
        }
      }
      if (spec.platforms.contains('ios')) {
        for (final change in module.nativeChanges.ios) {
          if (!iosNativeChanges.contains(change)) {
            iosNativeChanges.add(change);
          }
        }
      }
    }

    return GenerationPlan(
      spec: spec,
      modules: resolved,
      dependencies: dependencies,
      devDependencies: devDependencies,
      permissions: permissions,
      configKeys: configKeys,
      androidNativeChanges: androidNativeChanges,
      iosNativeChanges: iosNativeChanges,
    );
  }

  /// Validates that [plan] provides every capability in [required].
  ///
  /// Throws [CompatibilityException] with an actionable message when the
  /// selection cannot satisfy a requirement.
  void validateCapabilities(GenerationPlan plan, List<String> required) {
    final modules = _repository.loadModules();
    CompatibilityGraph(modules).validateCapabilities(plan.modules, required);
  }

  static const List<String> _supportedPlatforms = <String>['android', 'ios'];
}
