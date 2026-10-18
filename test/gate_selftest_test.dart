import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gate self-test: intentional failure', () {
    expect(1, equals(2), reason: 'intentional gate self-test failure');
  });
}
