import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _defaultRuns = 5;

Future<void> main(List<String> arguments) async {
  late final _Options options;
  try {
    options = _parseArguments(arguments);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    _printUsage();
    exitCode = 2;
    return;
  }
  if (options.help) {
    _printUsage();
    return;
  }

  Directory.current = File.fromUri(Platform.script).parent.parent.parent.path;
  try {
    final result = await _measure(options);
    stdout
      ..writeln('Device measurement saved: ${result.file.path}')
      ..writeln(result.summary);
  } on _ProbeFailure catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('Could not access a measurement artifact: ${error.message}');
    exitCode = 1;
  }
}

class ActivityLaunchTiming {
  const ActivityLaunchTiming({required this.waitTimeMs, required this.totalTimeMs});

  final int waitTimeMs;
  final int totalTimeMs;
}

class AndroidFrameStats {
  const AndroidFrameStats({
    required this.totalFrames,
    required this.jankyFrames,
    required this.jankyPercent,
  });

  final int? totalFrames;
  final int? jankyFrames;
  final double? jankyPercent;
}

ActivityLaunchTiming? parseActivityLaunchTiming(String output) {
  if (!RegExp(r'^Status:\s*ok$', multiLine: true).hasMatch(output)) return null;
  final waitTime = _parseIntField(output, 'WaitTime');
  final totalTime = _parseIntField(output, 'TotalTime');
  if (waitTime == null || totalTime == null) return null;
  return ActivityLaunchTiming(waitTimeMs: waitTime, totalTimeMs: totalTime);
}

int? parseAndroidTotalPssKb(String output) {
  final match = RegExp(r'^\s*TOTAL\s+(\d+)\s+', multiLine: true).firstMatch(output);
  return int.tryParse(match?.group(1) ?? '');
}

bool androidPackageListContains(String output, String packageName) =>
    output.split('\n').any((line) => line.trim() == 'package:$packageName');

AndroidFrameStats? parseAndroidFrameStats(String output) {
  final totalFrames = _parseIntField(output, 'Total frames rendered');
  final jankyMatch = RegExp(r'Janky frames:\s*(\d+)\s*\(([\d.]+)%\)').firstMatch(output);
  final jankyFrames = int.tryParse(jankyMatch?.group(1) ?? '');
  final jankyPercent = double.tryParse(jankyMatch?.group(2) ?? '');
  if (totalFrames == null && jankyFrames == null) return null;
  return AndroidFrameStats(
    totalFrames: totalFrames,
    jankyFrames: jankyFrames,
    jankyPercent: jankyPercent,
  );
}

int? parseAndroidDisplayedStartupMs(
  String output,
  String packageName, {
  required int startedAtEpochSeconds,
}) {
  final matches = RegExp(
    r'^\s*(\d+(?:\.\d+)?)\s+\d+\s+\d+\s+I ActivityTaskManager: '
    r'Displayed\s+([A-Za-z0-9._]+)/[^:]+:\s+(.+)$',
    multiLine: true,
  ).allMatches(output);
  int? displayedMs;
  for (final match in matches) {
    final timestamp = double.tryParse(match.group(1) ?? '');
    if (match.group(2) != packageName || timestamp == null || timestamp < startedAtEpochSeconds) {
      continue;
    }
    displayedMs = _parseAndroidDurationMs(match.group(3)!);
  }
  return displayedMs;
}

int? _parseAndroidDurationMs(String value) {
  final secondsMatch = RegExp(r'(\d+)s').firstMatch(value);
  final millisecondsMatch = RegExp(r'(\d+)ms').firstMatch(value);
  if (secondsMatch == null && millisecondsMatch == null) return null;
  final seconds = int.tryParse(secondsMatch?.group(1) ?? '') ?? 0;
  final milliseconds = int.tryParse(millisecondsMatch?.group(1) ?? '') ?? 0;
  return seconds * 1000 + milliseconds;
}

Future<bool> filesAreByteIdentical(File first, File second) async {
  if (await first.length() != await second.length()) return false;
  final firstHandle = await first.open();
  final secondHandle = await second.open();
  try {
    while (true) {
      final firstChunk = await firstHandle.read(64 * 1024);
      final secondChunk = await secondHandle.read(64 * 1024);
      if (firstChunk.length != secondChunk.length) return false;
      if (firstChunk.isEmpty) return true;
      for (var index = 0; index < firstChunk.length; index++) {
        if (firstChunk[index] != secondChunk[index]) return false;
      }
    }
  } finally {
    await firstHandle.close();
    await secondHandle.close();
  }
}

int? _parseIntField(String output, String label) {
  final match = RegExp('${RegExp.escape(label)}:\\s*(\\d+)').firstMatch(output);
  return int.tryParse(match?.group(1) ?? '');
}

class _Options {
  const _Options({
    required this.device,
    required this.packageName,
    required this.apkPath,
    required this.label,
    required this.runs,
    this.help = false,
  });

  final String? device;
  final String? packageName;
  final String? apkPath;
  final String label;
  final int runs;
  final bool help;
}

class _ProbeFailure implements Exception {
  const _ProbeFailure(this.message);

  final String message;
}

class _ProbeResult {
  const _ProbeResult({required this.file, required this.summary});

  final File file;
  final String summary;
}

Future<_ProbeResult> _measure(_Options options) async {
  final device = options.device!;
  final packageName = options.packageName!;
  final apk = File(options.apkPath!);
  if (!await apk.exists()) {
    throw _ProbeFailure('APK not found: ${apk.path}');
  }

  final deviceState = await _adb(device, ['get-state']);
  if (deviceState.trim() != 'device') {
    throw _ProbeFailure('ADB device $device is not online (state: ${deviceState.trim()}).');
  }

  final installedPackagesOutput = await _adb(device, [
    'shell',
    'pm',
    'list',
    'packages',
    packageName,
  ]);
  if (!androidPackageListContains(installedPackagesOutput, packageName)) {
    throw _ProbeFailure(
      'Package $packageName is not installed. Install the exact single-APK artifact '
      'manually before measuring; this probe never installs or uninstalls apps.',
    );
  }

  final packagePathsOutput = await _adb(device, ['shell', 'pm', 'path', packageName]);
  final packagePaths = RegExp(
    r'^package:(.+)$',
    multiLine: true,
  ).allMatches(packagePathsOutput).map((match) => match.group(1)!.trim()).toList();
  if (packagePaths.length != 1 || !packagePaths.single.endsWith('/base.apk')) {
    throw _ProbeFailure(
      'Expected one installed base APK for $packageName, but found ${packagePaths.length}. '
      'Install the exact single-APK artifact manually on the device; this probe never '
      'installs or uninstalls apps.',
    );
  }

  final tempDirectory = await Directory.systemTemp.createTemp('devflutt-perf-probe-');
  final installedApk = File('${tempDirectory.path}${Platform.pathSeparator}installed.apk');
  try {
    await _adb(device, ['pull', packagePaths.single, installedApk.path]);
    if (!await filesAreByteIdentical(apk, installedApk)) {
      throw _ProbeFailure(
        'The installed $packageName APK is not byte-identical to ${apk.path}. '
        'Manually install that exact APK before measuring; this probe never installs '
        'or updates apps.',
      );
    }
  } finally {
    try {
      await tempDirectory.delete(recursive: true);
    } on FileSystemException catch (error) {
      stderr.writeln('Could not remove temporary APK comparison files: ${error.message}');
    }
  }

  final componentOutput = await _adb(device, [
    'shell',
    'cmd',
    'package',
    'resolve-activity',
    '--brief',
    packageName,
  ]);
  final component = componentOutput
      .split('\n')
      .map((line) => line.trim())
      .lastWhere((line) => line.contains('/'), orElse: () => '');
  if (component.isEmpty || component.startsWith('No activity')) {
    throw _ProbeFailure('Could not resolve a launch activity for $packageName.');
  }

  final model = (await _adb(device, ['shell', 'getprop', 'ro.product.model'])).trim();
  final manufacturer = (await _adb(device, ['shell', 'getprop', 'ro.product.manufacturer'])).trim();
  final apiLevel = (await _adb(device, ['shell', 'getprop', 'ro.build.version.sdk'])).trim();
  final apkBytes = await apk.length();

  await _adb(device, ['shell', 'dumpsys', 'gfxinfo', packageName, 'reset']);
  final launchSamples = <Map<String, int>>[];
  final rawLaunchOutput = <Map<String, Object>>[];
  for (var run = 1; run <= options.runs; run++) {
    await _adb(device, ['shell', 'am', 'force-stop', packageName]);
    final startedAtText = await _adb(device, ['shell', 'date', '+%s']);
    final startedAt = int.tryParse(startedAtText.trim());
    if (startedAt == null) {
      throw _ProbeFailure('Android did not return a valid epoch timestamp before launch $run.');
    }
    final activityOutput = await _adb(device, ['shell', 'am', 'start', '-W', '-n', component]);
    final timing = parseActivityLaunchTiming(activityOutput);
    if (timing == null) {
      throw _ProbeFailure('Android did not report complete launch timings on run $run.');
    }
    final logcatOutput = await _adb(device, [
      'shell',
      'logcat',
      '-d',
      '-v',
      'epoch',
      '-s',
      'ActivityTaskManager:I',
    ]);
    final displayedMs = parseAndroidDisplayedStartupMs(
      logcatOutput,
      packageName,
      startedAtEpochSeconds: startedAt,
    );
    if (displayedMs == null) {
      throw _ProbeFailure(
        'Android did not report a first-display event for $packageName on launch $run.',
      );
    }
    final displayEvents = logcatOutput
        .split('\n')
        .where((line) => line.contains('ActivityTaskManager: Displayed $packageName/'))
        .join('\n');
    rawLaunchOutput.add({
      'activityManager': activityOutput,
      'displayEvents': displayEvents,
      'startedAtEpochSeconds': startedAt,
    });
    launchSamples.add({
      'timeToInitialDisplayMs': displayedMs,
      'waitTimeMs': timing.waitTimeMs,
      'totalTimeMs': timing.totalTimeMs,
    });
  }

  await Future<void>.delayed(const Duration(seconds: 1));
  final memoryOutput = await _adb(device, ['shell', 'dumpsys', 'meminfo', packageName]);
  final totalPssKb = parseAndroidTotalPssKb(memoryOutput);
  if (totalPssKb == null) {
    throw _ProbeFailure('Could not parse total PSS from Android memory diagnostics.');
  }
  final frameOutput = await _adb(device, ['shell', 'dumpsys', 'gfxinfo', packageName]);
  final frameStats = parseAndroidFrameStats(frameOutput);
  final hasFrameSamples = (frameStats?.totalFrames ?? 0) > 0;
  final availableFrameStats = hasFrameSamples ? frameStats! : null;

  final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
  final outputDirectory = Directory('build/patrol-logs/device-performance')
    ..createSync(recursive: true);
  final outputFile = File('${outputDirectory.path}/${options.label}-$timestamp.json');
  final document = <String, Object?>{
    'schemaVersion': 1,
    'measuredAtUtc': DateTime.now().toUtc().toIso8601String(),
    'device': {
      'serial': device,
      'manufacturer': manufacturer,
      'model': model,
      'apiLevel': apiLevel,
    },
    'package': packageName,
    'artifact': {'path': apk.path, 'bytes': apkBytes, 'installedBaseApkByteIdentical': true},
    'launch': {
      'method':
          'ActivityTaskManager Displayed event after am force-stop (process-cold); '
          'am start -W is also recorded',
      'samples': launchSamples,
      'timeToInitialDisplayP50Ms': _percentile(
        launchSamples.map((sample) => sample['timeToInitialDisplayMs']!).toList(),
        0.50,
      ),
      'timeToInitialDisplayP95Ms': _percentile(
        launchSamples.map((sample) => sample['timeToInitialDisplayMs']!).toList(),
        0.95,
      ),
      'waitTimeP50Ms': _percentile(
        launchSamples.map((sample) => sample['waitTimeMs']!).toList(),
        0.50,
      ),
      'waitTimeP95Ms': _percentile(
        launchSamples.map((sample) => sample['waitTimeMs']!).toList(),
        0.95,
      ),
    },
    'memory': {'source': 'dumpsys meminfo', 'totalPssKb': totalPssKb},
    'frames': {
      'source': 'dumpsys gfxinfo after ${options.runs} process-cold launches',
      'totalFrames': frameStats?.totalFrames,
      'jankyFrames': frameStats?.jankyFrames,
      'jankyPercent': frameStats?.jankyPercent,
      'available': hasFrameSamples,
      'sampleNote': !hasFrameSamples ? 'No frame samples were reported.' : 'Descriptive only; frame samples cover app launch, not an animated or scrolling workload.',
    },
    'raw': {'launchOutputs': rawLaunchOutput, 'meminfo': memoryOutput, 'gfxinfo': frameOutput},
    'limitations': [
      'Force-stop starts are process-cold, not device-cold.',
      if (!hasFrameSamples) 'Android returned no frame samples; null jank is not zero.',
      'Frame/jank observations cover process-cold launches only; this blank screen has no '
          'representative animated or scrolling workload.',
      'No install, update, uninstall, device-setting change, or UI tap was performed.',
    ],
  };
  await outputFile.writeAsString(const JsonEncoder.withIndent('  ').convert(document));
  final frameSummary = availableFrameStats == null
      ? 'frame/jank data unavailable (not zero)'
      : '${availableFrameStats.jankyFrames ?? 0}/${availableFrameStats.totalFrames} janky frames '
            '(${availableFrameStats.jankyPercent?.toStringAsFixed(2) ?? 'unknown'}%, launch-only sample)';
  return _ProbeResult(
    file: outputFile,
    summary:
        '${options.label}: ${options.runs} process-cold launches; '
        'PSS ${totalPssKb}KB; $frameSummary.',
  );
}

Future<String> _adb(String device, List<String> arguments) async {
  late final ProcessResult result;
  try {
    result = await Process.run(
      'adb',
      ['-s', device, ...arguments],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
  } on ProcessException catch (error) {
    throw _ProbeFailure('Could not run adb: ${error.message}');
  }
  if (result.exitCode != 0) {
    throw _ProbeFailure(
      'adb ${arguments.join(' ')} failed with exit code ${result.exitCode}: '
              '${result.stderr}'
          .trim(),
    );
  }
  return '${result.stdout}';
}

int _percentile(List<int> values, double percentile) {
  final sorted = [...values]..sort();
  final index = (sorted.length * percentile).ceil() - 1;
  return sorted[index < 0 ? 0 : index];
}

_Options _parseArguments(List<String> arguments) {
  String? device;
  String? packageName;
  String? apkPath;
  var label = 'device';
  var runs = _defaultRuns;
  var help = false;
  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    String nextValue() {
      if (index + 1 >= arguments.length) {
        throw FormatException('Missing value for $argument.');
      }
      return arguments[++index];
    }

    switch (argument) {
      case '--device':
        device = nextValue();
        break;
      case '--package':
        packageName = nextValue();
        break;
      case '--apk':
        apkPath = nextValue();
        break;
      case '--label':
        label = nextValue();
        break;
      case '--runs':
        runs = int.tryParse(nextValue()) ?? -1;
        break;
      case '-h':
      case '--help':
        help = true;
        break;
      default:
        throw FormatException('Unknown option: $argument');
    }
  }

  if (help) {
    return _Options(
      device: device,
      packageName: packageName,
      apkPath: apkPath,
      label: label,
      runs: runs,
      help: true,
    );
  }
  if (device == null || device.isEmpty) throw const FormatException('--device is required.');
  if (packageName == null ||
      !RegExp(r'^[A-Za-z0-9_]+(?:\.[A-Za-z0-9_]+)+$').hasMatch(packageName)) {
    throw const FormatException('--package must be a fully qualified Android package name.');
  }
  if (apkPath == null || apkPath.isEmpty) throw const FormatException('--apk is required.');
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9-]*$').hasMatch(label)) {
    throw const FormatException('--label may contain only letters, numbers, and hyphens.');
  }
  if (runs < 3 || runs > 20) throw const FormatException('--runs must be between 3 and 20.');
  return _Options(
    device: device,
    packageName: packageName,
    apkPath: apkPath,
    label: label,
    runs: runs,
  );
}

void _printUsage() {
  stdout.writeln('''
Usage: dart run tool/patrol/device_performance_probe.dart \\
  --device <serial> --package <application-id> --apk <installed-apk> [options]

Options:
  --label <name>  Measurement label for the JSON evidence file (default: device)
  --runs <count>  Process-cold launch samples, 3-20 (default: $_defaultRuns)
  -h, --help      Show this help

Safety: this probe never installs, updates, or uninstalls an app and never taps
device UI. It requires the supplied APK to be byte-identical to the installed
single base APK. Manually approve installation or updates before running it.
''');
}
