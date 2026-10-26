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

    final dependencies = <PubDependency>[];
    final devDependencies = <PubDependency>[];
    final permissions = <String>[];
    final configKeys = <String>[];
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
    }

    return GenerationPlan(
      spec: spec,
      modules: resolved,
      dependencies: dependencies,
      devDependencies: devDependencies,
      permissions: permissions,
      configKeys: configKeys,
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
}
