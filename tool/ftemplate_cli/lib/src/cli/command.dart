import 'dart:io';

import 'package:args/args.dart';

/// A single `ftemplate` subcommand.
abstract class FtemplateCommand {
  const FtemplateCommand();

  /// The command name as typed on the command line.
  String get name;

  /// One-line description shown in usage output.
  String get description;

  /// The argument parser for this command.
  ArgParser get parser;

  /// Runs the command and returns a process exit code.
  Future<int> run(ArgResults results);
}

/// Writes a line to stdout.
void writeOut(String message) => stdout.writeln(message);

/// Writes a line to stderr.
void writeErr(String message) => stderr.writeln(message);
