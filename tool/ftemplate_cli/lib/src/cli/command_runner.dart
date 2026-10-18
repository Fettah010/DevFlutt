import 'dart:io';

import 'package:args/args.dart';

import 'command.dart';
import 'commands/create_command.dart';
import 'commands/explain_module_command.dart';
import 'commands/list_modules_command.dart';
import 'commands/validate_command.dart';
import 'commands/version_command.dart';
import 'manifest/manifest_repository.dart';

/// Parses the top-level `ftemplate` invocation and dispatches to a subcommand.
class FtemplateCommandRunner {
  FtemplateCommandRunner({String? manifestsDir})
    : _repository = ManifestRepository(
        manifestsDir: manifestsDir ?? 'manifests',
      ) {
    _commands = <FtemplateCommand>[
      CreateCommand(_repository),
      ListModulesCommand(_repository),
      ExplainModuleCommand(_repository),
      const ValidateCommand(),
      const VersionCommand(),
    ];
    for (final command in _commands) {
      _parser.addCommand(command.name, command.parser);
    }
  }

  final ManifestRepository _repository;

  late final List<FtemplateCommand> _commands;

  final ArgParser _parser = ArgParser();

  /// Runs the runner and returns the process exit code.
  Future<int> run(
    List<String> arguments, {
    void Function(String)? out,
    void Function(String)? err,
  }) async {
    final output = out ?? (line) => stdout.writeln(line);
    final error = err ?? (line) => stderr.writeln(line);

    final ArgResults results;
    try {
      results = _parser.parse(arguments);
    } on FormatException catch (parseError) {
      error('Error: ${parseError.message}');
      _printUsage(output);
      return 64;
    }

    final command = results.command;
    if (command == null) {
      _printUsage(output);
      return 64;
    }

    final handler = _commands.firstWhere((candidate) => candidate.name == command.name);
    return handler.run(command, out: output, err: error);
  }

  void _printUsage(void Function(String) output) {
    output('Usage: ftemplate <command> [options]\n');
    output('Commands:');
    for (final command in _commands) {
      output('  ${command.name.padRight(16)} ${command.description}');
    }
  }
}
