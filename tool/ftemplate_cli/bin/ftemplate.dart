import 'dart:io';

import 'package:ftemplate_cli/ftemplate_cli.dart';

Future<void> main(List<String> arguments) async {
  final runner = FtemplateCommandRunner();
  exitCode = await runner.run(arguments);
}
