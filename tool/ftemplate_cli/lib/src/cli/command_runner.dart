import 'dart:io';

import 'package:args/args.dart';

import 'command.dart';
import 'commands/version_command.dart';

/// Parses the top-level `ftemplate` invocation and dispatches to a subcommand.
class FtemplateCommandRunner {
  FtemplateCommandRunner() {
    for (final command in _commands) {
      _parser.addCommand(command.name, command.parser);
    }
  }

  final List<FtemplateCommand> _commands = [const VersionCommand()];

  final ArgParser _parser = ArgParser();

  /// Runs the runner and returns the process exit code.
  Future<int> run(List<String> arguments) async {
    final ArgResults results;
    try {
      results = _parser.parse(arguments);
    } on FormatException catch (error) {
      writeErr('Error: ${error.message}');
      _printUsage();
      return 64;
    }

    final command = results.command;
    if (command == null) {
      _printUsage();
      return 64;
    }

    final handler = _commands.firstWhere(
      (candidate) => candidate.name == command.name,
      orElse: () => throw StateError('Unknown command ${command.name}'),
    );
    return handler.run(command);
  }

  void _printUsage() {
    writeOut('Usage: ftemplate <command> [options]\n');
    writeOut('Commands:');
    for (final command in _commands) {
      writeOut('  ${command.name.padRight(16)} ${command.description}');
    }
  }
}
