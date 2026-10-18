import '../manifest/module_manifest.dart';
import 'compatibility_exception.dart';

/// Resolves a module selection against the dependency/conflict graph.
class CompatibilityGraph {
  CompatibilityGraph(Iterable<ModuleManifest> manifests)
    : _manifests = {for (final manifest in manifests) manifest.id: manifest};

  final Map<String, ModuleManifest> _manifests;

  /// Resolves [selection] into the topologically ordered list of modules to
  /// install, including transitive requirements.
  ///
  /// Throws [CompatibilityException] with an actionable message when the
  /// selection is invalid.
  List<ModuleManifest> resolve(List<String> selection) {
    final requested = selection.toSet();

    for (final id in requested) {
      if (!_manifests.containsKey(id)) {
        throw CompatibilityException(
          'Unknown module "$id". Run `ftemplate list-modules` to see the '
          'available modules.',
        );
      }
    }

    final resolved = <String>{};
    for (final id in requested) {
      _collectRequires(id, resolved, <String>[]);
    }

    for (final id in resolved) {
      final manifest = _manifests[id]!;
      for (final conflict in manifest.conflictsWith) {
        if (resolved.contains(conflict)) {
          throw CompatibilityException(
            'Modules "$id" and "$conflict" conflict. Remove one of them.',
          );
        }
      }
    }

    final ordered = <ModuleManifest>[];
    final visited = <String>{};
    for (final id in requested) {
      _topologicalSort(id, ordered, visited, <String>[]);
    }

    return ordered;
  }

  /// The known module IDs.
  Iterable<String> get moduleIds => _manifests.keys;

  /// Looks up a manifest by ID, or null when unknown.
  ModuleManifest? manifestFor(String id) => _manifests[id];

  void _collectRequires(
    String id,
    Set<String> resolved,
    List<String> path,
  ) {
    if (resolved.contains(id)) {
      return;
    }
    if (path.contains(id)) {
      throw CompatibilityException(
        'Circular dependency detected: ${[...path, id].join(' -> ')}. '
        'Fix the "requires" entries in the module manifests.',
      );
    }
    final manifest = _manifests[id];
    if (manifest == null) {
      throw CompatibilityException(
        'Module "$id" requires an unknown module "${path.isEmpty ? '' : path.last}". '
        'Run `ftemplate list-modules` to see the available modules.',
      );
    }
    resolved.add(id);
    for (final dependency in manifest.requires) {
      _collectRequires(dependency, resolved, [...path, id]);
    }
  }

  void _topologicalSort(
    String id,
    List<ModuleManifest> ordered,
    Set<String> visited,
    List<String> path,
  ) {
    if (visited.contains(id)) {
      return;
    }
    if (path.contains(id)) {
      return;
    }
    final manifest = _manifests[id];
    if (manifest == null) {
      return;
    }
    visited.add(id);
    for (final dependency in manifest.requires) {
      _topologicalSort(dependency, ordered, visited, [...path, id]);
    }
    if (!ordered.contains(manifest)) {
      ordered.add(manifest);
    }
  }
}
