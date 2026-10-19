import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import '../../generator/generation_engine.dart';
import '../../graph/compatibility_exception.dart';
import '../../graph/project_planner.dart';
import '../../manifest/manifest_repository.dart';
import '../../manifest/module_manifest.dart';
import '../../models/project_spec.dart';
import '../command.dart';

/// `ftemplate create` — resolves a project selection and generates the project.
///
/// Argument parsing and selection resolution live here; the Mason generation
/// engine writes the files.
class CreateCommand extends FtemplateCommand {
  CreateCommand({required this.repository, this.brickPath = 'bricks/project'})
    : _planner = ProjectPlanner(repository);

  final ManifestRepository repository;
  final ProjectPlanner _planner;
  final String brickPath;

  @override
  String get name => 'create';

  @override
  String get description => 'Generate a new project.';

  @override
  ArgParser get parser => ArgParser()
    ..addOption('name', abbr: 'n', help: 'Application name.')
    ..addOption('org', abbr: 'o', help: 'Reverse-domain organization (for example com.example).')
    ..addOption('preset', abbr: 'p', defaultsTo: 'blank', help: 'Preset to use.')
    ..addOption('output', abbr: 'O', defaultsTo: '.', help: 'Output directory.')
    ..addOption('platforms', defaultsTo: 'android', help: 'Comma-separated target platforms.')
    ..addOption('module', abbr: 'm', help: 'Additional module IDs (repeatable).')
    ..addOption('brick-dir', help: 'Override the path to the project brick.')
    ..addFlag(
      'dry-run',
      abbr: 'd',
      defaultsTo: false,
      help: 'Print the plan without writing files.',
    )
    ..addFlag('force', abbr: 'f', defaultsTo: false, help: 'Overwrite a non-empty destination.')
    ..addFlag('no-pub', defaultsTo: false, help: 'Skip dependency resolution.');

  @override
  Future<int> run(
    ArgResults results, {
    void Function(String)? out,
    void Function(String)? err,
  }) async {
    final emit = out ?? (line) => stdout.writeln(line);
    final error = err ?? (line) => stderr.writeln(line);

    final name = results.option('name');
    final org = results.option('org');
    if (name == null || name.isEmpty) {
      error('Missing --name. Usage: ftemplate create --name <app> --org <org>.');
      return 64;
    }
    if (org == null || org.isEmpty) {
      error('Missing --org. Usage: ftemplate create --name <app> --org <org>.');
      return 64;
    }

    try {
      final spec = ProjectSpec(
        name: name,
        org: org,
        preset: results.option('preset') as String,
        output: results.option('output') as String,
        platforms: _parsePlatforms(results.option('platforms') as String),
        modules: results.multiOption('module'),
        dryRun: results.flag('dry-run'),
        force: results.flag('force'),
        skipPub: results.flag('no-pub'),
      );
      final plan = _planner.plan(spec);

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
        return 0;
      }

      final brickDir = results.option('brick-dir');
      final engine = GenerationEngine(brickPath: p.absolute(brickDir ?? brickPath));
      final destination = Directory(spec.output);

      if (GenerationEngine.isNonEmpty(destination) && !spec.force) {
        error(
          'Destination "${spec.output}" is not empty. Use --force to overwrite '
          'or choose a different --output.',
        );
        return 64;
      }

      emit('Generating...');
      final result = await engine.generate(plan);
      if (spec.force && destination.existsSync()) {
        await destination.delete(recursive: true);
      }
      await GenerationEngine.moveInto(result.projectDir, destination);

      emit('Generated ${result.files.length} files into ${spec.output}.');
      if (!spec.skipPub) {
        emit('Next: run "flutter pub get" in ${spec.output}.');
      }
      return 0;
    } on CompatibilityException catch (planError) {
      error('Error: ${planError.message}');
      return 64;
    } on FormatException catch (specError) {
      error('Error: ${specError.message}');
      return 64;
    }
  }

  List<String> _parsePlatforms(String value) => value
      .split(',')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList();

  String _formatIds(Iterable<String> values) => values.isEmpty ? 'none' : values.join(', ');

  String _formatDeps(List<PubDependency> values) => values.isEmpty
      ? 'none'
      : values.map((dependency) => dependency.toString()).join(', ');
}
