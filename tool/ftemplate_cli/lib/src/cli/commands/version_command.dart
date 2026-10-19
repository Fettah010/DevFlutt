import 'dart:io';

import 'package:args/args.dart';

import '../command.dart';
import '../../version.dart';

/// `ftemplate version` — prints the generator version.
class VersionCommand extends FtemplateCommand {
  const VersionCommand();

  @override
  String get name => 'version';

  @override
  String get description => 'Print the generator version.';

  @override
  ArgParser get parser => ArgParser();

  @override
  Future<int> run(
    ArgResults results, {
    void Function(String)? out,
    void Function(String)? err,
  }) async {
    final emit = out ?? (line) => stdout.writeln(line);
    emit('ftemplate $packageVersion');
    return 0;
  }
}
