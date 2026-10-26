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
output and tool versions go to `build/patrol-logs/`; after a test failure, the
runner adds filtered Patrol, Flutter, and Android runtime logcat. An AVD launched by the runner is shut down when the run ends;
an already-online device is left running. Patrol stores videos in `patrol_test/videos/` and failure
screenshots in `patrol_test/screenshots/`.

## Current test coverage

| Suite | Coverage |
|---|---|
| `smoke` | Launch the actual `DevFluttApp`; check home title, description, subtitle, and Flutter logo semantics. |
| `regression` | Return to the same home screen after Android background/resume; verify the app follows system light/dark mode; launch and render the blank home screen with Wi-Fi disabled. |

The home screen has no buttons, permission requests, authenticated flows, or
network-backed states. Tests for those behaviors belong with the app feature that
adds them. The Wi-Fi test verifies launch and rendering with Wi-Fi disabled; it
does not claim to test an offline data layer. Every test restores changed device
settings, and Android's test orchestrator clears app data between tests.

## CI and diagnostics

`.github/workflows/patrol-ui-tests.yml` runs alongside the standard quality and
generated-project checks for the same pull request, starts one pinned
Android emulator, and runs `smoke` and `regression` separately. Failures remain
failures. The workflow uploads runner logs, Android test reports, videos, and
screenshots even when the test step fails. Logcat artifacts use test-only data;
never put real credentials or personal data into UI test fixtures.

The former version matrix generated synthetic `Hello Patrol` widgets rather than
launching generated apps and suppressed failures. It was removed. Patrol checks
for generated-project combinations remain deferred until the harness can import
and exercise each generated app's real entry point. The existing generated
project build/test matrix remains in `.github/workflows/ci.yml`.

## Limits

This is Android emulator evidence. It does not claim physical-device, iOS, Play
distribution, or generated-project Patrol coverage. Add scenarios when the
corresponding product UI or native feature exists, and keep test assertions tied
to visible app behavior or verified system state.
