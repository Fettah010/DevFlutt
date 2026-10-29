# Patrol UI testing

Patrol covers the reference app on Android. The suite tests behavior that needs a
running app or Android system interaction; unit and widget tests remain in `test/`.

## Supported setup

- Flutter: 3.47.7 (same pinned CI toolchain as the rest of the repository).
- Patrol Flutter package: 4.10.0, pinned in `pubspec.yaml` and `pubspec.lock`.
- Patrol CLI: 4.8.0, pinned in CI and in the local install command below.
- CI device: one Android API 35 Google APIs emulator, Pixel 6 profile.
- UI test code lives in `patrol_test/`. Patrol's generated `test_bundle.dart` is ignored.

Patrol 4.10.0 adds Android native failure screenshots; the 4.8.0 CLI collects
them and supports per-test video on Android emulators. The pair is pinned because
these capabilities were introduced together. See the [Patrol 4.10.0 changelog](https://pub.dev/packages/patrol/changelog),
[Patrol CLI 4.8.0 changelog](https://pub.dev/packages/patrol_cli/changelog), and
[Patrol test command](https://patrol.leancode.co/cli-commands/test).

## Run locally

Install the same CLI version as CI and check the Android toolchain:

```powershell
dart pub global activate patrol_cli 4.8.0
patrol doctor
```

From the repository root, run a suite:

```powershell
dart run tool/patrol/run.dart --suite smoke
dart run tool/patrol/run.dart --suite regression
dart run tool/patrol/run.dart --suite all
```

For an agent-managed local emulator, let the runner check the SDK and create a
dedicated API 36 Google APIs AVD from an already-installed image:

```powershell
dart run tool/patrol/run.dart --suite smoke --prepare-emulator --keep-emulator
```

`--prepare-emulator` defaults to API 36 and names the AVD
`DevFluttAgent_API36_GoogleAPIs`. It does not modify existing AVDs, install
images, or accept SDK licenses. If the image is not installed, install it
yourself with SDK Manager and accept any license prompts, or explicitly opt into
the download with `--install-emulator-image`. Choose another API with
`--emulator-api <level>` (33 or newer). The runner stops an emulator it started
when the suite finishes unless `--keep-emulator` is supplied.

The runner selects a single online Android device. If none is online, it starts
the only available AVD. If there are multiple devices or AVDs, select one
explicitly:

```powershell
dart run tool/patrol/run.dart --suite smoke --device emulator-5554
dart run tool/patrol/run.dart --suite smoke --emulator Pixel_6_API_35
```

It waits for Android boot completion, runs `patrol doctor`, then invokes Patrol
with the chosen device and `dev` flavor. A missing device, ambiguous selection,
boot timeout, Patrol error, or test failure returns a nonzero exit code. Test
output and tool versions go to `build/patrol-logs/`. Each subprocess log entry
includes a UTC start time, separately labeled stdout/stderr, exit status, and
elapsed time. If setup or test execution fails after a device is selected, the
runner adds filtered Patrol, Flutter, and Android runtime logcat; a logcat
collection failure is recorded without replacing the original test error. An
AVD launched by the runner is shut down when the run ends unless
`--keep-emulator` is supplied; an already-online device is left running. Patrol
stores videos in `patrol_test/videos/` and failure screenshots in
`patrol_test/screenshots/`.

## Current test coverage

| Suite | Coverage |
|---|---|
| `smoke` | Launch the actual `DevFluttApp`; check home title, description, subtitle, and Flutter logo semantics. |
| `regression` | Return to the same home screen after Android background/resume; verify the app follows system light/dark mode; launch and render the blank home screen with Wi-Fi disabled. |

The generated v0.8 platform-service selection also has a native integration
smoke test. It initializes the app, schedules and cancels a WorkManager task,
checks notification display with permission denied or granted, and invokes the
Play update availability adapter. Run both notification states on an online
emulator with this PowerShell sequence from the repository root. CI runs the
same two states through `tool/patrol/run_platform_services_smoke.sh`, which
generates the project, derives its flavor application ID, and retains generator
output and emulator logcat under `build/patrol-logs/`:

```powershell
$project = Join-Path $env:TEMP ("devflutt-platform-services-smoke-" + [guid]::NewGuid().ToString("N"))
$appId = "com.example.platform_services_smoke.dev"
dart run tool/ftemplate_cli/bin/ftemplate.dart create `
  --name "Platform Services Smoke" --org com.example --preset blank `
  --module background-work --module local-notifications --module app-updates `
  --output $project --no-pub
Push-Location $project
try {
  flutter pub get
  flutter build apk --debug --flavor dev
  adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-dev-debug.apk
  adb -s emulator-5554 shell pm revoke $appId android.permission.POST_NOTIFICATIONS
  flutter drive --no-dds --driver=test_driver/integration_test.dart `
    --target=integration_test/platform_services_test.dart -d emulator-5554 --flavor dev
  adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-dev-debug.apk
  adb -s emulator-5554 shell pm grant $appId android.permission.POST_NOTIFICATIONS
  flutter drive --no-dds --driver=test_driver/integration_test.dart `
    --target=integration_test/platform_services_test.dart -d emulator-5554 --flavor dev `
    --dart-define=DEVFLUTT_EXPECT_NOTIFICATIONS_GRANTED=true
} finally {
  Pop-Location
}
```

The generated debug manifest includes `INTERNET` so Flutter's VM service can
bind during device tests; this permission is debug-only and does not change the
release permission contract. The tested `flutter drive --no-dds` invocation
avoids relying on DDS when an agent host cannot establish its local service.

The home screen has no buttons, permission requests, authenticated flows, or
network-backed states. Tests for those behaviors belong with the app feature that
adds them. The Wi-Fi test verifies launch and rendering with Wi-Fi disabled; it
does not claim to test an offline data layer. Every test restores changed device
settings, and Android's test orchestrator clears app data between tests.

## CI and diagnostics

`.github/workflows/patrol-ui-tests.yml` runs alongside the standard quality and
generated-project checks for the same pull request, starts one pinned
Android emulator, and runs `smoke` and `regression` separately. It also
generates the v0.8 composite project and runs the native service smoke with
notification permission explicitly denied and granted. Failures remain failures.
The workflow uploads runner logs, Android test reports, emulator logcat, videos,
and screenshots even when the test step fails. Logcat artifacts use test-only
data; never put real credentials or personal data into UI test fixtures.

The former version matrix generated synthetic `Hello Patrol` widgets rather than
launching generated apps and suppressed failures. It was removed. The targeted
v0.8 native integration test now exercises its generated composite app; broad
generated-project Patrol coverage remains deferred until the harness can import
and exercise every generated app's real entry point. The existing generated
project build/test matrix remains in `.github/workflows/ci.yml`.

## Limits

This is Android emulator evidence. It does not claim physical-device, iOS, Play
distribution, or generated-project Patrol coverage. The v0.8 update check can
return a typed failure on a Google APIs emulator without Play Store services;
live update availability requires an owner-provided Play internal-testing track.
Add scenarios when the corresponding product UI or native feature exists, and
keep test assertions tied to visible app behavior or verified system state.
