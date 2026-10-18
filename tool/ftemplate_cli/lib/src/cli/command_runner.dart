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
  Future<int> run(List<String> arguments, {StringSink? out, StringSink? err}) async {
    final output = out ?? stdout;
    final error = err ?? stderr;

    final ArgResults results;
    try {
      results = _parser.parse(arguments);
    } on FormatException catch (parseError) {
      error.writeln('Error: ${parseError.message}');
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

  void _printUsage(StringSink output) {
    output.writeln('Usage: ftemplate <command> [options]\n');
    output.writeln('Commands:');
    for (final command in _commands) {
      output.writeln('  ${command.name.padRight(16)} ${command.description}');
    }
  }
}
