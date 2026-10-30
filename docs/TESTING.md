# Testing

Canonical commands for the DevFlutt reference app. Every command propagates its
exit code; a non-zero exit means the check failed.

## Single quality gate

```bash
# macOS / Linux
./tool/verify/verify.sh
```

```powershell
# Windows
.\tool\verify\verify.ps1
```

The wrapper prints each command, writes per-command logs to
`build/verify-logs/`, and exits non-zero if any check fails.

On Windows, install the same pinned security-scanner versions used in CI before
running the complete local gate:

```powershell
.\tool\setup\install-security-tools.ps1
.\tool\verify\verify.ps1
```

The installer verifies the official Windows x64 release asset SHA-256 values
before installation and adds the per-user tool directory to `PATH`. Scanner
logs and JSON reports are written under `build/verify-logs/`; Gitleaks scans
repository history and the current working tree, and OSV-Scanner audits the
three committed lockfiles.

## Individual commands

| Check | Command |
|-------|---------|
| Resolve dependencies | `flutter pub get` |
| Format check | `dart format --output=none --set-exit-if-changed lib test` |
| Static analysis | `flutter analyze --fatal-infos` |
| Unit and widget tests | `flutter test` |
| Android debug build | `flutter build apk --debug --flavor dev` |
| Android release build | `flutter build apk --release --flavor prod` |
| Release permission check | `aapt2 dump permissions build/app/outputs/flutter-apk/app-prod-release.apk` |
| Resolve generator dependencies | `cd tool/ftemplate_cli && dart pub get` |
| Generator format check | `cd tool/ftemplate_cli && dart format --output=none --set-exit-if-changed .` |
| Generator analysis | `cd tool/ftemplate_cli && dart analyze --fatal-infos` |
| Generator tests | `cd tool/ftemplate_cli && dart test` |
| Patrol smoke UI test | `dart run tool/patrol/run.dart --suite smoke` |
| Patrol Android regression tests | `dart run tool/patrol/run.dart --suite regression` |
| Third-party notices | `dart run tool/ftemplate_cli/tool/license_inventory.dart --check` |
| Optional module dependency graph | `cd tool/module_dependency_audit && flutter pub get` |
| Secret scan history | `gitleaks git --redact --verbose .` |
| Secret scan working tree | `gitleaks dir --redact --verbose .` |
| Dependency audit | `osv-scanner scan source --lockfile pubspec.lock --lockfile tool/ftemplate_cli/pubspec.lock --lockfile tool/module_dependency_audit/pubspec.lock --format json` |

The format check scopes to `lib` and `test`. The repository also holds the Mason brick
templates, whose content is not parseable Dart until it is rendered, so formatting the
whole tree is not a meaningful check. The generator's own tree is formatted with `dart
format .` from `tool/ftemplate_cli`.

## Build flavours

The Android project defines the product flavors `dev`, `staging`, and `prod`. A build must
name one:

```bash
flutter build apk --debug --flavor dev      # build/app/outputs/flutter-apk/app-dev-debug.apk
flutter build apk --release --flavor prod   # build/app/outputs/flutter-apk/app-prod-release.apk
```

The flavor also selects the runtime environment. Pass the matching `APP_ENV` when the
application reads configuration at compile time:

```bash
flutter run --flavor dev --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=https://api.example.com
```

## Test layers

| Layer | Location | Scope |
|-------|----------|-------|
| Unit | `test/unit/` | Configuration parsing and validation. |
| Widget | `test/widget/` | Theme, home screen, and the application root. |
| CI | `.github/workflows/ci.yml` | Format, analyze, test, debug and release Android builds, the generated-project matrix, and the supply-chain gates. |

The generated projects carry their own tests. The `blank` preset ships the configuration,
theme, and home-screen tests; `core` adds the router tests (deep link, unknown route, and
redirect), the counter tests, and the logger tests; `demo` adds the showcase test;
`recommended` adds the networking tests, the secure-store tests, and the error-reporter
tests. An authentication preset adds the authentication contract tests, the shared
contract suite run against the selected adapter, and the router tests for the
authentication redirect. The generator runs the canonical Dart formatter over the
generated files, so CI can format-check every generated project as well.

### Generated localization module

For a project generated with `--module localization`, resolve dependencies and generate
the localized Dart API before analysis or builds:

```sh
flutter pub get
flutter gen-l10n
flutter analyze --fatal-infos
flutter test
```

The module contributes English and Arabic ARB resources, Flutter SDK localization delegates,
and locale-aware formatters. The blank preset omits the localization dependency, `l10n.yaml`,
ARB resources, and generated localization imports.

The v0.7 matrix also generates `preferences`, `local-database`, `offline-data`, `commerce`,
and `commerce-persistence` independently. Each selection is format-checked, analyzed,
tested, built in debug and release, and checked for expected Android permissions. The
offline sample's unit tests cover freshness invalidation, local persistence, queued operation
IDs, offline behavior, and local-wins conflict policy; widget tests cover refresh states.
The commerce tests check money arithmetic, checkout request fields, and failure/success UI.
These are generated-project widget tests; Patrol still targets the reference app.

The v0.8 `background-work` selection adds fake-backed tests for task constraints,
retry/backoff mapping, supported persisted input values, cancellation, and callback
success/retry behavior. A generated `background-work` project has been resolved,
formatted, analyzed, tested, and built with the `dev` debug flavor. The generated
`local-notifications` project tests explicit permission handling, disabled-send behavior,
and validated warm/cold-start route hand-off. The `app-updates` tests cover Play outcomes,
flexible-install progress, the app-specific HTTPS fallback, and launch failures. All three
projects have been resolved, formatted, analyzed, tested, and built locally in debug and
release. Their release permissions were inspected locally, and CI verifies conditional
permissions plus WorkManager component presence/absence. A generated composite Android
integration test exercises app bootstrap, WorkManager schedule/cancel, notification display
with permission denied/granted, and the typed Play update availability response. It runs
through `flutter drive --no-dds`; the integration-test scaffolding is opt-in and the debug
manifest alone declares `INTERNET` for the VM service. The local API 36 Google APIs emulator
passed both permission cases, while the Play update check returned a typed failure because
this image has no usable Play Store update backend. API 33+ tap/lifecycle coverage,
physical-device evidence, and Play internal-track testing remain separate gates.

`tool/module_dependency_audit` locks the union of optional generated-module runtime and
development dependencies. The dependency and license gates include that lockfile, so optional
Drift and preferences packages are covered even though they do not appear in the root app's
lockfile.

The service modules are tested against fakes, never against a live service. The
`networking` module's retry, cancellation, timeout, and correlation rules are exercised
through `FakeApiClient`, so the suite needs no network. The `secure-storage` module's
plugin is not exercised in a unit test — the plugin needs a device — so the module's
tests use `InMemorySecureStore` and the platform requirement is checked by inspecting
the merged Android manifest.

The authentication modules are tested the same way. One shared contract-test suite,
`test/unit/auth/auth_contract_suite.dart`, is run against every adapter over the
capabilities that adapter implements, so the three providers are verified against one
definition of correct behaviour. Each adapter's own test adds the cases that only it
has: the session store and the refresh coordinator for `auth-rest`, the forced refresh
and the email link for `auth-firebase`, and the forced refresh and the one-time
password for `auth-supabase`. No provider SDK is contacted, and no provider project is
needed to run the suite.

## Android UI tests

Patrol runs only on an Android device or emulator and is intentionally separate
from the fast `flutter test` gate. Install Patrol CLI 4.8.0 with
`dart pub global activate patrol_cli 4.8.0`, then run the commands above from the
repository root. The runner picks one online device or launches the only
available AVD; use `--device <serial>` or `--emulator <id>` to disambiguate.
Runner logs are written to `build/patrol-logs/`. Test failures also collect
filtered Patrol, Flutter, and Android runtime logcat. Videos and failure screenshots are retained under
`patrol_test/` and uploaded by the Patrol CI workflow.

See [Patrol UI testing](testing/UI_TESTING_PLAN_PATROL.md) for the current suite,
agent-facing emulator preparation, generated service integration-test commands,
diagnostics, and coverage limits. UI test fixtures must not contain production
credentials or personal data.

## CI evidence

CI run IDs and logs are the authoritative verification record. Local runs are
evidence only when the same command and toolchain are used.

## Notes

- Android release builds use the debug signing configuration so no real signing
  material is required. Replace it with a documented signing configuration before
  publishing.
- The release manifest requests `INTERNET` only when the generated selection includes a
  network client. CI fails if that match is wrong.
- The v0.8 generated-project matrix also checks that `POST_NOTIFICATIONS` is present only
  for `local-notifications`; that module's release build includes core-library desugaring.
- The Flutter and Dart SDKs are not required to build the generator; only the generator
  package's own toolchain is needed for `tool/ftemplate_cli`. Its lockfile is committed so
  generator tests, license inventory, and dependency audit use the same package graph locally
  and in CI.
- The `secret-scan` and `dependency-audit` jobs download a pinned binary and verify its
  published SHA-256 checksum before running it. The local gate requires both scanners,
  writes separate history/working-tree secret reports and an OSV JSON report under
  `build/verify-logs/`, and fails with setup instructions if a scanner is missing.
- On Windows, `.\tool\setup\install-security-tools.ps1` installs the same pinned scanner
  versions as CI after verifying their official Windows x64 release asset SHA-256 values.
- The secret scan is proven to fail: a canary credential on a throwaway branch turns the
  job red. A gate that was never seen failing is unproven.
