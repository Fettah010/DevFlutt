import 'package:flutter_test/flutter_test.dart';

import '../../tool/patrol/test_summary.dart';

void main() {
  group('PatrolTestSummary', () {
    test('accepts a non-empty fully successful run', () {
      const output = '''
Test summary:
📝 Total: 3
✅ Successful: 3
❌ Failed: 0
⏩ Skipped: 0
''';

      expect(PatrolTestSummary.parse(output).failure, isNull);
    });

    test('rejects an empty selection', () {
      const output = '''
📝 Total: 0
✅ Successful: 0
❌ Failed: 0
⏩ Skipped: 0
''';

      expect(PatrolTestSummary.parse(output).failure, contains('zero tests'));
    });

    test('rejects failed or skipped tests', () {
      const output = '''
📝 Total: 3
✅ Successful: 1
❌ Failed: 1
⏩ Skipped: 1
''';

      expect(PatrolTestSummary.parse(output).failure, contains('not fully green'));
    });

    test('rejects missing summary counts', () {
      expect(PatrolTestSummary.parse('Patrol command finished').failure, contains('complete'));
    });
  });
}
