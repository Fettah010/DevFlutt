import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../models/generation_plan.dart';
import '../version.dart';

/// The machine-readable origin marker written into every generated project.
///
/// It records the template version, the selected modules, and the SDK
/// constraints so a project can be compared with the template later. It
/// deliberately contains no timestamps or host-specific paths, so generation
/// stays deterministic.
class TemplateMetadata {
  const TemplateMetadata();

  static const String fileName = '.devflutt.yaml';

  /// Builds the metadata YAML for [plan].
  String build(GenerationPlan plan) {
    final modules = plan.modules.map((module) => module.id).toList();
    final buffer = StringBuffer()
      ..writeln('template_version: $packageVersion')
      ..writeln('project_name: ${plan.spec.name}')
      ..writeln('package: ${plan.spec.projectName}')
      ..writeln('application_id: ${plan.spec.applicationId}')
      ..writeln('modules:');
    if (modules.isEmpty) {
      buffer.writeln('  []');
    } else {
      for (final module in modules) {
        buffer.writeln('  - $module');
      }
    }
    buffer
      ..writeln('sdk_constraints:')
      ..writeln('  dart: ">=3.13.0 <4.0.0"')
      ..writeln('  flutter: ">=3.47.0 <3.48.0"');
    return buffer.toString();
  }

  /// Writes the metadata file into [projectDir].
  Future<void> write(Directory projectDir, GenerationPlan plan) async {
    final file = File(p.join(projectDir.path, fileName));
    await file.writeAsString(build(plan));
  }
}

/// Loads the metadata from a generated project, returning null when absent.
Map<String, dynamic>? readMetadata(Directory projectDir) {
  final file = File(p.join(projectDir.path, TemplateMetadata.fileName));
  if (!file.existsSync()) {
    return null;
  }
  final decoded = loadYaml(file.readAsStringSync());
  if (decoded is! YamlMap) {
    return null;
  }
  return Map<String, dynamic>.from(decoded);
}
