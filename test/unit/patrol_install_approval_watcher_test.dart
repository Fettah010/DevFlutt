import 'package:flutter_test/flutter_test.dart';

import '../../tool/patrol/install_approval_watcher.dart';

void main() {
  group('installerPackageFromWindowDump', () {
    test('recognizes MIUI installer windows', () {
      const dump =
          'mCurrentFocus=Window{d6d3b41 u0 '
          'com.miui.packageinstaller/com.miui.install.InstallActivity}';

      expect(installerPackageFromWindowDump(dump), 'com.miui.packageinstaller');
    });

    test('recognizes Android package installer windows', () {
      const dump =
          'mCurrentFocus=Window{d6d3b41 u0 '
          'com.android.packageinstaller/com.android.packageinstaller.InstallStart}';

      expect(installerPackageFromWindowDump(dump), 'com.android.packageinstaller');
    });

    test('ignores ordinary app and launcher windows', () {
      const dump =
          'mCurrentFocus=Window{d6d3b41 u0 '
          'bitpit.launcher/bitpit.launcher.ui.HomeActivity}';

      expect(installerPackageFromWindowDump(dump), isNull);
    });

    test('returns null when the focus line is absent', () {
      expect(installerPackageFromWindowDump('Window manager state'), isNull);
    });
  });
}
