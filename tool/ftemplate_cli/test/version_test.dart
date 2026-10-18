import 'dart:io';

import 'package:ftemplate_cli/ftemplate_cli.dart';
import 'package:test/test.dart';

void main() {
  group('version', () {
    test('prints the package version', () async {
      final output = await _captureStdout(() async {
        final code = await FtemplateCommandRunner().run(['version']);
        expect(code, 0);
      });

      expect(output, contains(packageVersion));
    });

    test('usage is printed when no command is given', () async {
      final code = await FtemplateCommandRunner().run([]);
      expect(code, 64);
    });
  });
}

Future<String> _captureStdout(Future<void> Function() body) async {
  final buffer = StringBuffer();
  final spec = ZoneSpecification(
    print: (self, parent, zone, line) => buffer.writeln(line),
  );
  await runZoned(body, zoneSpecification: spec);
  return buffer.toString();
}
