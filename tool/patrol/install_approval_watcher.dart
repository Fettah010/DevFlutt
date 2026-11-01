import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _installerPackages = {
  'com.android.packageinstaller',
  'com.google.android.packageinstaller',
  'com.miui.packageinstaller',
  'com.miui.securitycenter',
};

String? installerPackageFromWindowDump(String dump) {
  final package = RegExp(r'mCurrentFocus=.*?u\d+\s+([A-Za-z0-9._]+)/').firstMatch(dump)?.group(1);
  return _installerPackages.contains(package) ? package : null;
}

class DeviceInstallApprovalWatcher {
  DeviceInstallApprovalWatcher({
    required this.deviceId,
    required this.log,
    required this.logDirectory,
    this.captureScreens = false,
  });

  final String deviceId;
  final StringBuffer log;
  final Directory logDirectory;
  final bool captureScreens;

  Timer? _timer;
  bool _polling = false;
  bool _stopped = false;
  String? _activeInstaller;
  String? _lastQueryError;

  static Future<DeviceInstallApprovalWatcher> start({
    required String deviceId,
    required StringBuffer log,
    required Directory logDirectory,
    bool captureScreens = false,
  }) async {
    final watcher = DeviceInstallApprovalWatcher(
      deviceId: deviceId,
      log: log,
      logDirectory: logDirectory,
      captureScreens: captureScreens,
    );
    unawaited(watcher._poll());
    watcher._timer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(watcher._poll());
    });
    return watcher;
  }

  Future<void> _poll() async {
    if (_stopped || _polling) return;
    _polling = true;
    try {
      final result = await Process.run(
        'adb',
        ['-s', deviceId, 'shell', 'dumpsys', 'window'],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      ).timeout(const Duration(seconds: 10));
      if (result.exitCode != 0) {
        _recordQueryError('adb dumpsys window exited with code ${result.exitCode}.');
        return;
      }

      _lastQueryError = null;
      final installer = installerPackageFromWindowDump('${result.stdout}');
      if (installer != null && installer != _activeInstaller) {
        _activeInstaller = installer;
        const message =
            'Android installer confirmation is open. Approve or cancel it on the device; '
            'the runner will continue when the installer returns a result.';
        log.writeln('$message Foreground package: $installer.');
        stdout.writeln(message);
        if (captureScreens) await _captureScreen(installer);
      } else if (installer == null && _activeInstaller != null) {
        log.writeln('Android installer screen closed; waiting for Patrol install/test result.');
        _activeInstaller = null;
      }
    } on ProcessException catch (error) {
      _recordQueryError('Could not inspect Android window state: ${error.message}');
    } on TimeoutException {
      _recordQueryError('Timed out while inspecting Android window state.');
    } finally {
      _polling = false;
    }
  }

  void _recordQueryError(String message) {
    if (_lastQueryError == message) return;
    _lastQueryError = message;
    log.writeln(message);
    stderr.writeln(message);
  }

  Future<void> _captureScreen(String installer) async {
    final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final file = File('${logDirectory.path}/install-approval-$timestamp.png');
    try {
      final process = await Process.start('adb', ['-s', deviceId, 'exec-out', 'screencap', '-p']);
      final imageBytes = process.stdout.expand((chunk) => chunk).toList();
      final errorOutput = utf8.decoder.bind(process.stderr).join();
      final exitCode = await process.exitCode;
      final stderrText = await errorOutput;
      final bytes = await imageBytes;
      if (exitCode != 0 || bytes.isEmpty) {
        log.writeln(
          'Could not capture the installer screen for $installer '
          '(exit $exitCode): $stderrText',
        );
        return;
      }
      await file.writeAsBytes(bytes);
      final message = 'Captured installer screen: ${file.path}';
      log.writeln(message);
      stdout.writeln(message);
    } on ProcessException catch (error) {
      log.writeln('Could not capture the installer screen: ${error.message}');
    } on FileSystemException catch (error) {
      log.writeln('Could not save the installer screen: ${error.message}');
    }
  }

  Future<void> stop() async {
    _stopped = true;
    _timer?.cancel();
    while (_polling) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }
}
