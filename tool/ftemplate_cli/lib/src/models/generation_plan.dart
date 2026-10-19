import '../manifest/module_manifest.dart';
import 'project_spec.dart';

/// The resolved, validated plan for a generation run.
class GenerationPlan {
  const GenerationPlan({
    required this.spec,
    required this.modules,
    required this.dependencies,
    required this.permissions,
    required this.configKeys,
  });

  /// The project specification the plan was derived from.
  final ProjectSpec spec;

  /// The resolved modules in installation order.
  final List<ModuleManifest> modules;

  /// The union of pub dependencies across the resolved modules.
  final List<PubDependency> dependencies;

  /// The union of Android permissions across the resolved modules.
  final List<String> permissions;

  /// The union of configuration keys across the resolved modules.
  final List<String> configKeys;

  /// Whether the plan is empty (blank preset with no additions).
  bool get isEmpty => modules.isEmpty;
}
