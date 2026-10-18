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
| Android debug build | `flutter build apk --debug` |
| Android release build | `flutter build apk --release` |
| Release permission check | `aapt2 dump permissions build/app/outputs/flutter-apk/app-release.apk` |

## Test layers

| Layer | Location | Scope |
|-------|----------|-------|
| Unit | `test/unit/` | Configuration parsing and validation. |
| Widget | `test/widget/` | Theming and the home screen. |
| CI | `.github/workflows/ci.yml` | Format, analyze, test, debug and release Android builds. |

## CI evidence

CI run IDs and logs are the authoritative verification record. Local runs are
evidence only when the same command and toolchain are used.

## Notes

- Android release builds use the debug signing configuration so no real signing
  material is required. Replace it with a documented signing configuration before
  publishing.
- The release manifest must not request `INTERNET`. CI fails if it does.
