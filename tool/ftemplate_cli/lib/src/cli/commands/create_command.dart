import 'dart:io';

import 'package:args/args.dart';

import '../../graph/compatibility_exception.dart';
import '../../graph/project_planner.dart';
import '../../manifest/manifest_repository.dart';
import '../../manifest/module_manifest.dart';
import '../../models/generation_plan.dart';
import '../../models/project_spec.dart';
import '../command.dart';

/// `ftemplate create` — resolves a project selection and prints the plan.
///
/// File generation is performed by the generation engine; this command owns
/// argument parsing, selection resolution, and the plan summary.
class CreateCommand extends FtemplateCommand {
  CreateCommand(this._repository)
    : _planner = ProjectPlanner(_repository);

  final ManifestRepository _repository;
  final ProjectPlanner _planner;

  @override
  String get name => 'create';

  @override
  String get description => 'Generate a new project.';

  @override
  ArgParser get parser => ArgParser()
    ..addOption('name', abbr: 'n', mandatory: true, help: 'Application name.')
    ..addOption(
      'org',
      abbr: 'o',
      mandatory: true,
      help: 'Reverse-domain organization (for example com.example).',
    )
    ..addOption('preset', abbr: 'p', defaultsTo: 'blank', help: 'Preset to use.')
    ..addOption('output', abbr: 'O', defaultsTo: '.', help: 'Output directory.')
    ..addOption(
      'platforms',
      defaultsTo: 'android',
      help: 'Comma-separated target platforms.',
    )
    ..addOption(
      'module',
      abbr: 'm',
      allowMultiple: true,
      help: 'Additional module IDs (repeatable).',
    )
    ..addFlag(
      'dry-run',
      abbr: 'd',
      defaultsTo: false,
      help: 'Print the plan without writing files.',
    )
    ..addFlag(
      'force',
      abbr: 'f',
      defaultsTo: false,
      help: 'Overwrite a non-empty destination.',
    )
    ..addFlag(
      'no-pub',
      defaultsTo: false,
      help: 'Skip dependency resolution in the generated project.',
    );

  @override
  Future<int> run(
    ArgResults results, {
    void Function(String)? out,
    void Function(String)? err,
  }) async {
    final emit = out ?? (line) => stdout.writeln(line);
    final error = err ?? (line) => stderr.writeln(line);

    ProjectSpec spec;
    try {
      spec = ProjectSpec(
        name: results.option('name') as String,
        org: results.option('org') as String,
        preset: results.option('preset') as String,
        output: results.option('output') as String,
        platforms: _parsePlatforms(results.option('platforms') as String),
        modules: results.multiOption('module'),
        dryRun: results.flag('dry-run'),
        force: results.flag('force'),
        skipPub: results.flag('no-pub'),
      );
    } on FormatException catch (nameError) {
      error('Error: ${nameError.message}');
      return 64;
    }

    final GenerationPlan plan;
    try {
      plan = _planner.plan(spec);
    } on CompatibilityException catch (planError) {
      error('Error: ${planError.message}');
      return 64;
    }

    emit('Project: ${spec.name}');
    emit('Package: ${spec.projectName}');
    emit('Application ID: ${spec.applicationId}');
    emit('Preset: ${spec.preset}');
    emit('Output: ${spec.output}');
    emit('Platforms: ${spec.platforms.join(', ')}');
    emit('Modules: ${_formatIds(plan.modules.map((module) => module.id))}');
    emit('Dependencies: ${_formatDeps(plan.dependencies)}');
    if (plan.permissions.isNotEmpty) {
      emit('Permissions: ${plan.permissions.join(', ')}');
    }
    if (plan.configKeys.isNotEmpty) {
      emit('Config keys: ${plan.configKeys.join(', ')}');
    }

    if (spec.dryRun) {
      emit('Dry run — no files written.');
    }
    return 0;
  }

  List<String> _parsePlatforms(String value) => value
      .split(',')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList();

  String _formatIds(Iterable<String> values) =>
      values.isEmpty ? 'none' : values.join(', ');

  String _formatDeps(List<PubDependency> values) =>
      values.isEmpty ? 'none' : values.map((d) => d.toString()).join(', ');
}
