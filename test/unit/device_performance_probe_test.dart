import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/patrol/device_performance_probe.dart';

void main() {
  group('parseActivityLaunchTiming', () {
    test('parses Android activity manager timing fields', () {
      const output = '''
Status: ok
Activity: com.example.devflutt/.MainActivity
ThisTime: 412
TotalTime: 428
WaitTime: 437
Complete
''';

      final result = parseActivityLaunchTiming(output);

      expect(result?.waitTimeMs, 437);
      expect(result?.totalTimeMs, 428);
    });

    test('rejects incomplete activity timing output', () {
      expect(parseActivityLaunchTiming('Status: ok\nWaitTime: 25'), isNull);
    });

    test('rejects timing values when Android reports a failed launch', () {
      const output = '''
Status: timeout
TotalTime: 428
WaitTime: 437
''';

      expect(parseActivityLaunchTiming(output), isNull);
    });
  });

  group('parseAndroidTotalPssKb', () {
    test('parses the PSS column from Android 10 meminfo output', () {
      const output = '''
Applications Memory Usage (in Kilobytes):
                   Pss  Private  Private
                 Total    Dirty    Clean
                ------   ------   ------
        TOTAL    227641   109940    50068
 App Summary
               TOTAL:   227641       TOTAL SWAP PSS: 12369
''';

      expect(parseAndroidTotalPssKb(output), 227641);
    });

    test('returns null when the total PSS row is absent', () {
      expect(parseAndroidTotalPssKb('Applications Memory Usage'), isNull);
    });
  });

  group('androidPackageListContains', () {
    test('matches the exact installed package', () {
      expect(
        androidPackageListContains(
          'package:com.example.devflutt_physical_performance\n',
          'com.example.devflutt_physical_performance',
        ),
        isTrue,
      );
    });

    test('does not match a package with a similar prefix', () {
      expect(
        androidPackageListContains(
          'package:com.example.devflutt_physical_performance.debug\n',
          'com.example.devflutt_physical_performance',
        ),
        isFalse,
      );
    });
  });

  group('parseAndroidFrameStats', () {
    test('parses total and janky frame counts', () {
      const output = '''
Total frames rendered: 6941
Janky frames: 1513 (21.80%)
''';

      final result = parseAndroidFrameStats(output);

      expect(result?.totalFrames, 6941);
      expect(result?.jankyFrames, 1513);
      expect(result?.jankyPercent, 21.8);
    });

    test('does not turn missing frame data into a zero-jank result', () {
      expect(parseAndroidFrameStats('Applications Graphics Acceleration Info'), isNull);
    });
  });

  group('parseAndroidDisplayedStartupMs', () {
    test('parses a current first-display event for the requested package', () {
      const output =
          '1793560717.043 3966 3996 I ActivityTaskManager: Displayed '
          'com.example.devflutt/.MainActivity: +1s325ms';

      expect(
        parseAndroidDisplayedStartupMs(
          output,
          'com.example.devflutt',
          startedAtEpochSeconds: 1793560717,
        ),
        1325,
      );
    });

    test('ignores stale display events and events for other packages', () {
      const output = '''
1793560716.999 3966 3996 I ActivityTaskManager: Displayed com.example.devflutt/.MainActivity: +400ms
1793560717.043 3966 3996 I ActivityTaskManager: Displayed com.example.other/.MainActivity: +500ms
''';

      expect(
        parseAndroidDisplayedStartupMs(
          output,
          'com.example.devflutt',
          startedAtEpochSeconds: 1793560717,
        ),
        isNull,
      );
    });
  });

  group('filesAreByteIdentical', () {
    late Directory directory;
    late File first;
    late File second;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('devflutt-perf-probe-test-');
      first = File('${directory.path}${Platform.pathSeparator}first.apk');
      second = File('${directory.path}${Platform.pathSeparator}second.apk');
    });

    tearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    test('accepts files with identical bytes', () async {
      await first.writeAsBytes([1, 2, 3, 4]);
      await second.writeAsBytes([1, 2, 3, 4]);

      expect(await filesAreByteIdentical(first, second), isTrue);
    });

    test('rejects files that differ', () async {
      await first.writeAsBytes([1, 2, 3, 4]);
      await second.writeAsBytes([1, 2, 3, 5]);

      expect(await filesAreByteIdentical(first, second), isFalse);
    });
  });
}
