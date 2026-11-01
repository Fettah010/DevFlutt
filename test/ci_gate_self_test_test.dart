import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CI failure-gate self-test intentionally fails', () {
    expect(true, isFalse, reason: 'Intentional failure-gate self-test.');
  });
}
