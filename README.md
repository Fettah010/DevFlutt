# Flutter Android App Template

A blank-first Flutter starter and project generator for Android-first applications. Start with a
clean, runnable app — or generate only the modules your product needs.

> **Status:** v0.1.0 (verified blank foundation). The generator and optional modules are planned for
> later releases.

## What this is

- **A GitHub template repository** with a small, runnable Flutter app as the blank reference.
- **A planned bundled generator** (v0.2.0+) that creates tailored projects from presets and
  optional modules.
- **A documented architecture baseline** that grows module by module — never a giant example app.

## Requirements

| Tool | Version |
|------|---------|
| Flutter | `>=3.47.0 <3.48.0` (stable channel) |
| Dart | `3.13.x` (bundled with Flutter 3.47) |
| JDK | 17 |
| Android SDK | compileSdk 36, minSdk 24, targetSdk 36 |

Install Flutter from the [official guide](https://docs.flutter.dev/install).

## Quickstart

```bash
# 1. Use this template (GitHub button) or clone
git clone https://github.com/Fettah010/DevFlutt.git
cd DevFlutt

# 2. Resolve dependencies
flutter pub get

# 3. Run the tests
flutter test

# 4. Run the app (needs a connected device or a running emulator)
flutter run
```

## Project structure

```
lib/
  main.dart                 # entry point
  app.dart                  # MaterialApp root
  core/
    config/app_config.dart  # typed, validated configuration boundary
    theme/app_theme.dart    # minimal light/dark theme tokens
  features/
    home/home_page.dart     # example screen
test/
  unit/                     # domain + config tests
  widget/                   # UI + theme tests
android/                    # Android platform project
tool/verify/                # local quality gate scripts
.github/workflows/          # CI
docs/releases/              # per-version plans and reports
```

## Verifying

The canonical quality command is the verify wrapper:

```bash
# Windows
.\tool\verify\verify.ps1

# macOS / Linux
./tool/verify/verify.sh
```

It prints every command, propagates every exit code, and writes per-command logs. It never ends with
an unconditional success message.

Individual commands:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

## Blank-first guarantees

The blank app:

- makes **no network requests** and requests **no Android permissions**;
- includes **no** auth, HTTP client, database, analytics, crash reporting, or background work;
- has **zero third-party runtime dependencies** beyond the Flutter SDK and `cupertino_icons`.

## Documentation

- [Roadmap](Flutter-Android-App-Template-Roadmap-v0.1.0-to-v1.0.0.md)
- [Execution protocol](FLUTTER-AGENT-EXECUTION-PROTOCOL.md)
- [Contributing](CONTRIBUTING.md)
- [Security policy](SECURITY.md)
- [Changelog](CHANGELOG.md)

## License

[MIT](LICENSE)
