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
  ///
  /// [out] and [err] default to stdout and stderr; tests inject their own
  /// callbacks.
  Future<int> run(ArgResults results, {void Function(String)? out, void Function(String)? err});
}
