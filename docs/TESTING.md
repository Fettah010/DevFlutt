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
| Third-party notices | `dart run tool/ftemplate_cli/tool/license_inventory.dart --check` |
| Secret scan (needs `gitleaks`) | `gitleaks git --redact --verbose .` |
| Dependency audit (needs `osv-scanner`) | `osv-scanner scan --lockfile=pubspec.lock --lockfile=tool/ftemplate_cli/pubspec.lock` |

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

## CI evidence

CI run IDs and logs are the authoritative verification record. Local runs are
evidence only when the same command and toolchain are used.

## Notes

- Android release builds use the debug signing configuration so no real signing
  material is required. Replace it with a documented signing configuration before
  publishing.
- The release manifest must not request `INTERNET`. CI fails if it does.
- The Flutter and Dart SDKs are not required to build the generator; only the generator
  package's own toolchain is needed for `tool/ftemplate_cli`.
- The `secret-scan` and `dependency-audit` jobs download a pinned binary and verify its
  published SHA-256 checksum before running it. The local wrapper skips them when the
  tool is not installed, and says so.
- The secret scan is proven to fail: a canary credential on a throwaway branch turns the
  job red. A gate that was never seen failing is unproven.
