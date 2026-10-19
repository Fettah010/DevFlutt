import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

import '../../manifest/manifest_validator.dart';
import '../../manifest/module_manifest.dart';
import '../command.dart';

/// `ftemplate validate` — validates a module manifest file.
class ValidateCommand extends FtemplateCommand {
  const ValidateCommand();

  @override
  String get name => 'validate';

  @override
  String get description => 'Validate a module manifest file.';

  @override
  ArgParser get parser =>
      ArgParser()..addOption('manifest', abbr: 'm', help: 'Path to a module manifest YAML file.');

  @override
  Future<int> run(
    ArgResults results, {
    void Function(String)? out,
    void Function(String)? err,
  }) async {
    final emit = out ?? (line) => stdout.writeln(line);
    final error = err ?? (line) => stderr.writeln(line);

    final path = results.option('manifest');
    if (path == null || path.isEmpty) {
      error('Missing --manifest. Usage: ftemplate validate --manifest <file>.');
      return 64;
    }

    final file = File(path);
    if (!file.existsSync()) {
      error('Cannot read "$path": file not found.');
      return 66;
    }

    final decoded = loadYaml(file.readAsStringSync());
    if (decoded is! YamlMap) {
      error('Invalid manifest "$path": must be a YAML mapping.');
      return 65;
    }

    final errors = const ManifestValidator().validate(decoded);
    if (errors.isEmpty) {
      final manifest = ModuleManifest.fromYaml(decoded);
      emit('${manifest.id} is valid.');
      return 0;
    }

    error('Invalid manifest "$path":');
    for (final message in errors) {
      error('  - $message');
    }
    return 65;
  }
}
