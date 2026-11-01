import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../verify/generated_project_matrix.dart';

void main() {
  group('generated project matrix', () {
    final document = jsonDecode(File('../verify/generated_project_matrix.json').readAsStringSync());

    test('enumerates all required presets, backends, and key compositions', () {
      final cases = validateMatrix(document);

      expect(cases, hasLength(25));
      expect(cases.map((entry) => entry['name']), contains('commerce-preset'));
      expect(cases.map((entry) => entry['name']), contains('full-preset'));
      expect(cases.map((entry) => entry['name']), contains('full-maximum'));
    });

    test('rejects a matrix missing a required preset', () {
      final incomplete = Map<String, Object?>.from(document as Map<String, dynamic>);
      incomplete['cases'] = (incomplete['cases'] as List<Object?>)
          .where((entry) => (entry as Map<String, dynamic>)['name'] != 'full-preset')
          .toList();

      expect(() => validateMatrix(incomplete), throwsFormatException);
    });

    test('rejects an auth case with the wrong provider', () {
      final malformed = jsonDecode(jsonEncode(document)) as Map<String, dynamic>;
      final cases = (malformed['cases'] as List<Object?>).cast<Map<String, dynamic>>();
      cases.singleWhere((entry) => entry['name'] == 'auth-firebase')['auth'] = 'none';

      expect(() => validateMatrix(malformed), throwsFormatException);
    });

    test('rejects a standalone module case with the wrong selection', () {
      final malformed = jsonDecode(jsonEncode(document)) as Map<String, dynamic>;
      final cases = (malformed['cases'] as List<Object?>).cast<Map<String, dynamic>>();
      cases.singleWhere((entry) => entry['name'] == 'commerce-module')['modules'] = <String>[];

      expect(() => validateMatrix(malformed), throwsFormatException);
    });

    test('rejects incorrect permission expectations', () {
      final malformed = jsonDecode(jsonEncode(document)) as Map<String, dynamic>;
      final cases = (malformed['cases'] as List<Object?>).cast<Map<String, dynamic>>();
      cases.singleWhere((entry) => entry['name'] == 'full-preset')['expects_notifications'] = false;

      expect(() => validateMatrix(malformed), throwsFormatException);
    });
  });

  group('generated project test result guard', () {
    test('counts visible passing tests and ignores hidden suite events', () {
      const events = [
        '{"type":"testDone","hidden":true,"skipped":false,"result":"success"}',
        '{"type":"testDone","hidden":false,"skipped":false,"result":"success"}',
        '{"type":"done","success":true}',
      ];

      expect(countPassedTestEvents(events), 1);
    });

    test('rejects zero-test runs', () {
      const events = ['{"type":"done","success":true}'];

      expect(() => countPassedTestEvents(events), throwsFormatException);
    });

    test('rejects skipped required tests', () {
      const events = [
        '{"type":"testDone","hidden":false,"skipped":true,"result":"success"}',
        '{"type":"done","success":true}',
      ];

      expect(() => countPassedTestEvents(events), throwsFormatException);
    });
  });
}
