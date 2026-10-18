import 'dart:io';

import 'package:args/args.dart';

import '../../manifest/manifest_repository.dart';
import '../command.dart';

/// `ftemplate list-modules` — lists the available modules and presets.
class ListModulesCommand extends FtemplateCommand {
  ListModulesCommand(this._repository);

  final ManifestRepository _repository;

  @override
  String get name => 'list-modules';

  @override
  String get description => 'List the available modules and presets.';

  @override
  ArgParser get parser => ArgParser();

  @override
  Future<int> run(
    ArgResults results, {
    void Function(String)? out,
    void Function(String)? err,
  }) async {
    final emit = out ?? (line) => stdout.writeln(line);

    final modules = _repository.loadModules();
    emit('Modules:');
    for (final module in modules) {
      emit('  ${module.id.padRight(20)} ${module.summary}');
    }

    final presets = _repository.loadPresets();
    emit('');
    emit('Presets:');
    for (final preset in presets) {
      emit('  ${preset.id.padRight(20)} ${preset.summary}');
    }
    return 0;
  }
}
