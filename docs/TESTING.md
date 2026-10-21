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
| Format check | `dart format --output=none --set-exit-if-changed .` |
| Static analysis | `flutter analyze --fatal-infos` |
| Unit and widget tests | `flutter test` |
| Android debug build | `flutter build apk --debug --flavor dev` |
| Android release build | `flutter build apk --release --flavor prod` |
| Release permission check | `aapt2 dump permissions build/app/outputs/flutter-apk/app-prod-release.apk` |

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
| CI | `.github/workflows/ci.yml` | Format, analyze, test, debug and release Android builds. |

The generated projects carry their own tests. The `blank` preset ships the configuration,
theme, and home-screen tests; `core` adds the router tests (deep link, unknown route, and
redirect) and the counter tests; `demo` adds the showcase test. The generator runs the
canonical Dart formatter over the generated files, so CI can format-check every
generated project as well.

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
