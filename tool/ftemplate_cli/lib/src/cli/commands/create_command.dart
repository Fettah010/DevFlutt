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
    ..addMultiOption('module', abbr: 'm', help: 'Additional module IDs (repeatable).')
    ..addOption(
      'backend',
      defaultsTo: 'none',
      help: 'Data backend: none, rest, firebase, or supabase.',
    )
    ..addOption(
      'auth',
      defaultsTo: 'none',
      help: 'Authentication provider: none, rest, firebase, or supabase.',
    )
    ..addMultiOption('auth-capability', help: 'A capability the application needs (repeatable).')
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
      final backendChoice = results.option('backend') as String;
      if (!_backendChoices.contains(backendChoice)) {
        error(
          'Invalid --backend value "$backendChoice". Expected one of: '
          '${_backendChoices.join(', ')}.',
        );
        return 64;
      }

      final authChoice = results.option('auth') as String;
      final authModule = _authModuleFor(authChoice);
      if (authModule == null && authChoice != 'none') {
        error(
          'Invalid --auth value "$authChoice". Expected one of: '
          '${_authChoices.join(', ')}.',
        );
        return 64;
      }

      final requestedCapabilities = results.multiOption('auth-capability');
      final backendModule = _backendModuleFor(backendChoice);
      final modules = <String>[...results.multiOption('module'), ?backendModule, ?authModule];

      final spec = ProjectSpec(
        name: name,
        org: org,
        preset: results.option('preset') as String,
        output: results.option('output') as String,
        platforms: _parsePlatforms(results.option('platforms') as String),
        modules: modules,
        dryRun: results.flag('dry-run'),
        force: results.flag('force'),
        skipPub: results.flag('no-pub'),
      );
      final plan = _planner.plan(spec);
      _planner.validateCapabilities(plan, requestedCapabilities);
      if (backendChoice == 'none' &&
          results.wasParsed('backend') &&
          _providerBackendModuleIds.any(
            (moduleId) => plan.modules.any((module) => module.id == moduleId),
          )) {
        error(
          'Error: --backend none cannot be combined with a provider data-backend module. '
          'Remove the module or choose --backend firebase or --backend supabase.',
        );
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
      emit('Backend: ${_effectiveBackendOf(backendChoice, plan.modules)}');
      final authModule_ = _authModuleOf(plan.modules);
      if (authModule_ != null) {
        final capabilities = authModule_.capabilities;
        emit(
          'Authentication: ${authModule_.id} '
          '(${capabilities.isEmpty ? 'no capabilities' : capabilities.join(', ')})',
        );
      } else {
        emit('Authentication: none');
      }
      if (plan.permissions.isNotEmpty) {
        emit('Permissions: ${plan.permissions.join(', ')}');
      }
      if (plan.androidNativeChanges.isNotEmpty) {
        emit('Android native changes: ${plan.androidNativeChanges.join('; ')}');
      }
      if (plan.iosNativeChanges.isNotEmpty) {
        emit('iOS native changes: ${plan.iosNativeChanges.join('; ')}');
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
      final result = await engine.generate(
        plan,
        tempParent: _nearestExistingParent(destination.parent),
      );
      try {
        if (spec.force && destination.existsSync()) {
          await destination.delete(recursive: true);
        }
        await GenerationEngine.moveInto(result.projectDir, destination);
      } finally {
        if (result.projectDir.existsSync()) {
          await result.projectDir.delete(recursive: true);
        }
      }

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

  List<String> _parsePlatforms(String value) =>
      value.split(',').map((entry) => entry.trim()).where((entry) => entry.isNotEmpty).toList();

  Directory _nearestExistingParent(Directory directory) {
    var candidate = Directory(p.absolute(directory.path));
    while (!candidate.existsSync()) {
      final parentPath = p.dirname(candidate.path);
      if (parentPath == candidate.path) {
        throw FileSystemException(
          'No existing parent directory for the output path.',
          directory.path,
        );
      }
      candidate = Directory(parentPath);
    }
    return candidate;
  }

  /// The authentication providers the command accepts.
  static const List<String> _authChoices = <String>['none', 'rest', 'firebase', 'supabase'];

  /// The data backends the command accepts.
  static const List<String> _backendChoices = <String>['none', 'rest', 'firebase', 'supabase'];

  /// Provider-specific data modules that cannot be selected together.
  static const List<String> _providerBackendModuleIds = <String>[
    'backend-firestore',
    'backend-supabase',
  ];

  /// The module an authentication choice selects, or null for `none`.
  static String? _authModuleFor(String choice) => switch (choice) {
    'rest' => 'auth-rest',
    'firebase' => 'auth-firebase',
    'supabase' => 'auth-supabase',
    _ => null,
  };

  /// The module a data-backend choice selects, or null for `none`.
  static String? _backendModuleFor(String choice) => switch (choice) {
    'rest' => 'networking',
    'firebase' => 'backend-firestore',
    'supabase' => 'backend-supabase',
    _ => null,
  };

  /// Resolves the displayed backend when it was selected through `--module`.
  String _effectiveBackendOf(String choice, List<ModuleManifest> modules) {
    if (choice != 'none') {
      return choice;
    }
    final moduleIds = modules.map((module) => module.id).toSet();
    if (moduleIds.contains('backend-firestore')) {
      return 'firebase';
    }
    if (moduleIds.contains('backend-supabase')) {
      return 'supabase';
    }
    return 'none';
  }

  /// The selected authentication adapter, or null when there is none.
  static ModuleManifest? _authModuleOf(List<ModuleManifest> modules) {
    for (final module in modules) {
      if (module.id == 'auth-rest' ||
          module.id == 'auth-firebase' ||
          module.id == 'auth-supabase') {
        return module;
      }
    }
    return null;
  }

  String _formatIds(Iterable<String> values) => values.isEmpty ? 'none' : values.join(', ');

  String _formatDeps(List<PubDependency> values) =>
      values.isEmpty ? 'none' : values.map((dependency) => dependency.toString()).join(', ');
}
