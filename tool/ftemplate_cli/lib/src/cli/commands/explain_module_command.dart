import 'dart:io';

import 'package:args/args.dart';

import '../../manifest/manifest_repository.dart';
import '../../manifest/module_manifest.dart';
import '../command.dart';

/// `ftemplate explain-module` — shows the details of a single module.
class ExplainModuleCommand extends FtemplateCommand {
  ExplainModuleCommand(this._repository);

  final ManifestRepository _repository;

  @override
  String get name => 'explain-module';

  @override
  String get description => 'Show the details of a single module.';

  @override
  ArgParser get parser => ArgParser()..addOption('id', abbr: 'i', help: 'Module ID.');

  @override
  Future<int> run(
    ArgResults results, {
    void Function(String)? out,
    void Function(String)? err,
  }) async {
    final emit = out ?? (line) => stdout.writeln(line);
    final error = err ?? (line) => stderr.writeln(line);

    final id = results.option('id');
    if (id == null || id.isEmpty) {
      error('Missing --id. Usage: ftemplate explain-module --id <module>.');
      return 64;
    }

    final module = _repository.moduleById(id, _repository.loadModules());
    if (module == null) {
      error(
        'Unknown module "$id". Run `ftemplate list-modules` to see the '
        'available modules.',
      );
      return 64;
    }

    _describe(module, emit);
    return 0;
  }

  void _describe(ModuleManifest module, void Function(String) emit) {
    emit('Module: ${module.id}');
    emit('Version: ${module.version}');
    emit('Category: ${module.category}');
    emit('Summary: ${module.summary}');
    emit('Platforms: ${module.platforms.join(', ')}');
    emit('Requires: ${module.requires.isEmpty ? 'none' : module.requires.join(', ')}');
    emit(
      'Conflicts with: '
      '${module.conflictsWith.isEmpty ? 'none' : module.conflictsWith.join(', ')}',
    );
    emit('Pub dependencies: ${_formatDeps(module.pubDependencies)}');
    emit('Permissions: ${module.permissions.isEmpty ? 'none' : module.permissions.join(', ')}');
    emit('Config keys: ${module.configKeys.isEmpty ? 'none' : module.configKeys.join(', ')}');
    emit('Outputs:');
    for (final output in module.outputs) {
      emit('  $output');
    }
    emit('Required setup:');
    if (module.requiredSetup.isEmpty) {
      emit('  none');
    } else {
      for (final step in module.requiredSetup) {
        emit('  $step');
      }
    }
  }

  String _formatDeps(List<PubDependency> dependencies) {
    if (dependencies.isEmpty) {
      return 'none';
    }
    return dependencies.map((dependency) => dependency.toString()).join(', ');
  }
}
