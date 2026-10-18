import 'package:ftemplate_cli/ftemplate_cli.dart';
import 'package:test/test.dart';

void main() {
  group('version', () {
    test('prints the package version', () async {
      final out = StringBuffer();
      final code = await FtemplateCommandRunner().run(['version'], out: out.writeln);

      expect(code, 0);
      expect(out.toString(), contains(packageVersion));
    });

    test('usage is printed when no command is given', () async {
      final out = StringBuffer();
      final code = await FtemplateCommandRunner().run([], out: out.writeln);

      expect(code, 64);
      expect(out.toString(), contains('Usage:'));
    });

    test('an unknown command returns a usage error', () async {
      final out = StringBuffer();
      final code = await FtemplateCommandRunner().run(['nope'], out: out.writeln);

      expect(code, 64);
    });
  });
}
