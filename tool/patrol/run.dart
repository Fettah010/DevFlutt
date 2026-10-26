import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'test_summary.dart';

const _defaultTimeout = Duration(minutes: 20);
const _bootTimeout = Duration(minutes: 3);

Future<void> main(List<String> arguments) async {
  late final _Options options;
  try {
    options = _parseArguments(arguments);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    _printUsage();
    exit(2);
  }
  if (options.help) {
    _printUsage();
    return;
  }

  final projectRoot = File.fromUri(Platform.script).parent.parent.parent;
  Directory.current = projectRoot.path;
  final logDirectory = Directory('build/patrol-logs')..createSync(recursive: true);
  final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
  final logFile = File('${logDirectory.path}/patrol-$timestamp.log');
  final log = StringBuffer()
    ..writeln('Started: ${DateTime.now().toUtc().toIso8601String()}')
    ..writeln('Suite: ${options.suite}')
    ..writeln('Project: ${projectRoot.path}');
  var runnerExitCode = 0;
  String? deviceToStop;

  try {
    final selection = await _selectDevice(options, log);
    final deviceId = selection.deviceId;
    if (selection.startedByRunner) deviceToStop = deviceId;
    await _recordEnvironment(deviceId, log);

    final patrol = _patrolExecutable();
    final doctor = await _run(patrol, ['doctor'], log, timeout: _defaultTimeout);
    if (doctor != 0) {
      throw _RunnerFailure('`patrol doctor` failed with exit code $doctor.');
    }

    final patrolArgs = <String>[
      '--verbose',
      'test',
      '--device',
      deviceId,
      '--flavor',
      'dev',
      '--show-flutter-logs',
      '--record-video',
      '--video-output-dir',
      'patrol_test/videos',
      ..._targetsForSuite(options.suite),
    ];
    late final ProcessResult patrolResult;
    try {
      patrolResult = await _runForOutput(patrol, patrolArgs, log, timeout: options.testTimeout);
    } catch (_) {
      await _recordFailureLogcat(deviceId, log);
      rethrow;
    }
    final summary = PatrolTestSummary.parse('${patrolResult.stdout}\n${patrolResult.stderr}');
    log.writeln(
      'Patrol summary: total=${summary.total} successful=${summary.successful} '
      'failed=${summary.failed} skipped=${summary.skipped}',
    );
    final summaryError = summary.failure;
    if (patrolResult.exitCode != 0 || summaryError != null) {
      await _recordFailureLogcat(deviceId, log);
      throw _RunnerFailure(summaryError ?? 'Patrol exited with code ${patrolResult.exitCode}.');
    }
  } on _RunnerFailure catch (error) {
    log.writeln('ERROR: ${error.message}');
    stderr.writeln(error.message);
    runnerExitCode = 1;
  } catch (error, stackTrace) {
    log
      ..writeln('ERROR: $error')
      ..writeln(stackTrace);
    stderr.writeln('Patrol runner failed: $error');
    runnerExitCode = 1;
  }

  final launchedDevice = deviceToStop;
  if (launchedDevice != null) {
    log.writeln('Stopping emulator $launchedDevice because this runner started it.');
    await _run('adb', ['-s', launchedDevice, 'emu', 'kill'], log);
  }

  await _writeLog(logFile, log);
  if (runnerExitCode != 0) {
    stderr.writeln('Run log: ${logFile.path}');
    exit(runnerExitCode);
  }
  stdout.writeln('Patrol passed. Run log: ${logFile.path}');
}

class _Options {
  const _Options({
    this.device,
    this.emulator,
    this.suite = 'all',
    this.testTimeout = _defaultTimeout,
    this.help = false,
  });

  final String? device;
  final String? emulator;
  final String suite;
  final Duration testTimeout;
  final bool help;
}

class _RunnerFailure implements Exception {
  const _RunnerFailure(this.message);

  final String message;
}

_Options _parseArguments(List<String> arguments) {
  String? device;
  String? emulator;
  var suite = 'all';
  var timeoutSeconds = 1200;
  var help = false;

  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    String value(String name) {
      if (index + 1 >= arguments.length) {
        throw FormatException('Missing value for $name.');
      }
      index++;
      return arguments[index];
    }

    switch (argument) {
      case '--device':
        device = value(argument);
      case '--emulator':
        emulator = value(argument);
      case '--suite':
        suite = value(argument);
      case '--timeout-seconds':
        timeoutSeconds = int.tryParse(value(argument)) ?? 0;
      case '--help':
      case '-h':
        help = true;
      default:
        throw FormatException('Unknown option: $argument');
    }
  }

  if (!{'smoke', 'regression', 'all'}.contains(suite)) {
    throw FormatException('Suite must be smoke, regression, or all.');
  }
  if (device != null && emulator != null) {
    throw const FormatException('Choose either --device or --emulator, not both.');
  }
  if (timeoutSeconds < 30 || timeoutSeconds > 7200) {
    throw const FormatException('--timeout-seconds must be between 30 and 7200.');
  }

  return _Options(
    device: device,
    emulator: emulator,
    suite: suite,
    testTimeout: Duration(seconds: timeoutSeconds),
    help: help,
  );
}

class _DeviceSelection {
  const _DeviceSelection(this.deviceId, {this.startedByRunner = false});

  final String deviceId;
  final bool startedByRunner;
}

Future<_DeviceSelection> _selectDevice(_Options options, StringBuffer log) async {
  final onlineDevices = await _onlineDevices(log);
  if (options.emulator != null && onlineDevices.isNotEmpty) {
    throw _RunnerFailure(
      'An Android device is already online (${onlineDevices.join(', ')}). '
      'Use --device <serial>, or disconnect it before launching --emulator ${options.emulator}.',
    );
  }
  if (options.device != null) {
    if (!onlineDevices.contains(options.device)) {
      throw _RunnerFailure(
        'Device `${options.device}` is not online. Run `adb devices -l` and check its status.',
      );
    }
    await _waitForBoot(options.device!, log);
    return _DeviceSelection(options.device!);
  }

  if (onlineDevices.length == 1) {
    await _waitForBoot(onlineDevices.single, log);
    return _DeviceSelection(onlineDevices.single);
  }
  if (onlineDevices.length > 1) {
    throw _RunnerFailure(
      'More than one Android device is online (${onlineDevices.join(', ')}). '
      'Select one with --device <serial>.',
    );
  }

  final emulators = await _availableEmulators(log);
  final emulatorId = options.emulator ?? (emulators.length == 1 ? emulators.single : null);
  if (emulatorId == null) {
    final available = emulators.isEmpty ? 'none found' : emulators.join(', ');
    throw _RunnerFailure(
      'No Android device is online; available AVDs: $available. '
      'Start one or select it with --emulator <id>.',
    );
  }
  if (options.emulator != null && !emulators.contains(options.emulator)) {
    throw _RunnerFailure(
      'Emulator `${options.emulator}` was not found. Available AVDs: ${emulators.join(', ')}.',
    );
  }

  final launch = await _run('flutter', ['emulators', '--launch', emulatorId], log);
  if (launch != 0) {
    throw _RunnerFailure('Could not launch emulator `$emulatorId` (exit code $launch).');
  }
  try {
    final launchedDevices = await _waitForDevice(log);
    if (launchedDevices.length != 1) {
      throw _RunnerFailure(
        'Expected one online device after launching `$emulatorId`; found ${launchedDevices.join(', ')}.',
      );
    }
    await _waitForBoot(launchedDevices.single, log);
    return _DeviceSelection(launchedDevices.single, startedByRunner: true);
  } catch (_) {
    final possiblyLaunched = await _onlineDevices(log);
    if (possiblyLaunched.length == 1 && possiblyLaunched.single.startsWith('emulator-')) {
      await _run('adb', ['-s', possiblyLaunched.single, 'emu', 'kill'], log);
    }
    rethrow;
  }
}

List<String> _targetsForSuite(String suite) => switch (suite) {
  'smoke' => ['--target', 'patrol_test/smoke/smoke_test.dart'],
  'regression' => [
    '--target',
    'patrol_test/flows/app_lifecycle_test.dart',
    '--target',
    'patrol_test/flows/theme_test.dart',
    '--target',
    'patrol_test/native/device_settings_test.dart',
  ],
  _ => const [],
};

Future<List<String>> _onlineDevices(StringBuffer log) async {
  final result = await _runForOutput('adb', ['devices', '-l'], log);
  if (result.exitCode != 0) {
    throw _RunnerFailure('`adb devices -l` failed with exit code ${result.exitCode}.');
  }
  return _parseOnlineDevices('${result.stdout}');
}

List<String> _parseOnlineDevices(String output) => output
    .split('\n')
    .map((line) => RegExp(r'^\s*(\S+)\s+device(?:\s|$)').firstMatch(line)?.group(1))
    .whereType<String>()
    .toList();

Future<List<String>> _availableEmulators(StringBuffer log) async {
  final result = await _runForOutput('flutter', ['emulators'], log);
  if (result.exitCode != 0) {
    throw _RunnerFailure('`flutter emulators` failed with exit code ${result.exitCode}.');
  }
  // `flutter emulators` has no machine-readable output in the pinned Flutter
  // version. Parse the stable ID column and ignore headings/instructions.
  final output = '${result.stdout}';
  return output
      .split('\n')
      .where((line) => line.contains('•'))
      .map((line) => line.split('•').first.trim())
      .where((id) => id.isNotEmpty && id != 'Id' && !id.contains(' '))
      .toList();
}

Future<List<String>> _waitForDevice(StringBuffer log) async {
  final deadline = DateTime.now().add(_bootTimeout);
  while (DateTime.now().isBefore(deadline)) {
    final devices = await _onlineDevices(log);
    if (devices.isNotEmpty) return devices;
    await Future<void>.delayed(const Duration(seconds: 3));
  }
  throw const _RunnerFailure('The emulator did not appear in `adb devices` within 3 minutes.');
}

Future<void> _waitForBoot(String deviceId, StringBuffer log) async {
  final deadline = DateTime.now().add(_bootTimeout);
  while (DateTime.now().isBefore(deadline)) {
    final result = await _runForOutput('adb', [
      '-s',
      deviceId,
      'shell',
      'getprop',
      'sys.boot_completed',
    ], log);
    if (result.exitCode == 0 && '${result.stdout}'.trim() == '1') {
      log.writeln('Boot completed on $deviceId.');
      return;
    }
    await Future<void>.delayed(const Duration(seconds: 3));
  }
  throw _RunnerFailure('Android device `$deviceId` did not finish booting within 3 minutes.');
}

Future<void> _recordEnvironment(String deviceId, StringBuffer log) async {
  for (final command in <(String, List<String>)>[
    ('flutter', ['--version']),
    ('dart', ['--version']),
    (_patrolExecutable(), ['--version']),
    ('adb', ['version']),
    ('adb', ['-s', deviceId, 'shell', 'getprop', 'ro.product.model']),
    ('adb', ['-s', deviceId, 'shell', 'getprop', 'ro.build.version.sdk']),
  ]) {
    await _run(command.$1, command.$2, log);
  }
}

Future<void> _recordFailureLogcat(String deviceId, StringBuffer log) async {
  final args = [
    '-s',
    deviceId,
    'logcat',
    '-d',
    '-v',
    'threadtime',
    '-s',
    'Patrol:I',
    'PatrolServer:I',
    'flutter:E',
    'AndroidRuntime:E',
  ];
  final result = await _runForOutput('adb', args, log);
  log
    ..writeln('--- app logcat after Patrol failure ---')
    ..writeln(result.stdout)
    ..writeln(result.stderr)
    ..writeln('--- end logcat ---');
}

Future<int> _run(
  String executable,
  List<String> arguments,
  StringBuffer log, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final result = await _runForOutput(executable, arguments, log, timeout: timeout);
  return result.exitCode;
}

String _patrolExecutable() {
  final pubCache = Platform.environment['PUB_CACHE'];
  if (pubCache != null && pubCache.isNotEmpty) {
    final executable = Platform.isWindows ? 'patrol.bat' : 'patrol';
    final candidate = File(
      '$pubCache${Platform.pathSeparator}bin${Platform.pathSeparator}$executable',
    );
    if (candidate.existsSync()) return candidate.path;
  }
  return 'patrol';
}

Future<ProcessResult> _runForOutput(
  String executable,
  List<String> arguments,
  StringBuffer log, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final command = '$executable ${arguments.join(' ')}';
  stdout.writeln('> $command');
  log.writeln('> $command');
  late final Process process;
  try {
    process = await Process.start(executable, arguments, runInShell: Platform.isWindows);
  } on ProcessException catch (error) {
    log.writeln('Process error: $error');
    throw _RunnerFailure('Could not start `$executable`: ${error.message}');
  }

  final stdoutBuffer = StringBuffer();
  final stderrBuffer = StringBuffer();
  final stdoutDone = Completer<void>();
  final stderrDone = Completer<void>();
  process.stdout
      .transform(utf8.decoder)
      .listen(
        (chunk) {
          stdout.write(chunk);
          stdoutBuffer.write(chunk);
          log.write(chunk);
        },
        onError: stdoutDone.completeError,
        onDone: stdoutDone.complete,
      );
  process.stderr
      .transform(utf8.decoder)
      .listen(
        (chunk) {
          stderr.write(chunk);
          stderrBuffer.write(chunk);
          log.write(chunk);
        },
        onError: stderrDone.completeError,
        onDone: stderrDone.complete,
      );
  late final int processExitCode;
  try {
    processExitCode = await process.exitCode.timeout(timeout);
  } on TimeoutException {
    process.kill();
    await process.exitCode;
    await Future.wait([stdoutDone.future, stderrDone.future]);
    log.writeln('Timed out after ${timeout.inSeconds} seconds.');
    throw _RunnerFailure('`$command` exceeded ${timeout.inSeconds} seconds.');
  }

  await Future.wait([stdoutDone.future, stderrDone.future]);
  log.writeln('Exit code: $processExitCode');
  return ProcessResult(
    process.pid,
    processExitCode,
    stdoutBuffer.toString(),
    stderrBuffer.toString(),
  );
}

Future<void> _writeLog(File file, StringBuffer log) => file.writeAsString(log.toString());

void _printUsage() {
  stdout.writeln('''
Run Patrol UI tests against one online Android device or emulator.

Usage: dart run tool/patrol/run.dart [options]
  --suite <smoke|regression|all>  Test tags to run (default: all)
  --device <serial>               Use this already-online adb device
  --emulator <id>                 Launch this Flutter AVD if no device is online
  --timeout-seconds <seconds>     Patrol test timeout, 30..7200 (default: 1200)
  --help                          Show this help

With no device selection, one online device is used, or the only available AVD
is launched. Multiple choices require explicit selection. Logs are written to
build/patrol-logs; failure artifacts include filtered app logcat.
''');
}
