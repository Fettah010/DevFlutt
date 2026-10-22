# Flutter Android App Template

A blank-first Flutter starter and project generator for Android-first applications. Start with a
clean, runnable app — or generate only the modules your product needs.

> **Status:** v0.3.0 (production architecture, themes, navigation, and environments). The generator
> produces `blank`, `core`, and `demo` projects; later releases add networking, auth, persistence,
> and more.

## What this is

- **A GitHub template repository** with a small, runnable Flutter app as the blank reference.
- **A bundled generator** (`ftemplate`) that creates tailored projects from presets and optional
  modules, with a versioned manifest schema and dependency/conflict graph.
- **A documented architecture baseline** that grows module by module — never a giant example app.

## Generate a project

```bash
# Resolve the generator's dependencies
dart pub get

# Generate a blank project into ./my_app
dart run tool/ftemplate_cli/bin/ftemplate.dart create \
  --name "My App" --org com.example --preset blank --output ./my_app

# Generate a core project (adds Riverpod, go_router, the design system, and the counter example)
dart run tool/ftemplate_cli/bin/ftemplate.dart create \
  --name "My App" --org com.example --preset core --output ./my_app

# Generate a demo project (adds the component showcase)
dart run tool/ftemplate_cli/bin/ftemplate.dart create \
  --name "My App" --org com.example --preset demo --output ./my_app

# Generate a recommended project (adds the HTTP, diagnostic, and secure-storage plumbing)
dart run tool/ftemplate_cli/bin/ftemplate.dart create \
  --name "My App" --org com.example --preset recommended --output ./my_app

# Preview without writing files
dart run tool/ftemplate_cli/bin/ftemplate.dart create \
  --name "My App" --org com.example --preset core --dry-run
```

The generated project is independent of the generator at runtime. It carries a
`.devflutt.yaml` origin marker with the template version and selected modules. The
generator runs the canonical Dart formatter over the generated files, so a generated
project is format-clean out of the box.

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
flutter run --flavor dev
```

## Project structure

```
lib/
  main.dart                 # entry point
  bootstrap/bootstrap.dart  # single startup path
  app.dart                  # MaterialApp root
  core/
    config/app_config.dart  # typed, validated configuration boundary
    theme/app_tokens.dart   # spacing, radius, and motion tokens
    theme/app_theme.dart    # Material 3 light/dark themes
  features/
    home/home_page.dart     # example screen
test/
  unit/                     # domain + config tests
  widget/                   # UI + theme tests
android/                    # Android platform project (dev/staging/prod flavors)
tool/ftemplate_cli/         # bundled generator (Dart CLI)
  bin/ lib/ test/
bricks/project/            # Mason brick that scaffolds generated projects
manifests/                  # module manifests, presets, schema
tool/verify/                # local quality gate scripts
.github/workflows/          # CI
docs/                       # plans, reports, ADRs, modules
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
# Reference app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug --flavor dev

# Generator package
cd tool/ftemplate_cli
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
dart test
```

## Blank-first guarantees

The blank app:

- makes **no network requests** and requests **no Android permissions**;
- includes **no** auth, HTTP client, database, analytics, crash reporting, or background work;
- has **zero third-party runtime dependencies** beyond the Flutter SDK and `cupertino_icons`.

The `core` preset adds the logger, which adds no dependency either. The HTTP client, the
secure store, and the error reporter arrive only when the `networking`, `secure-storage`,
and `diagnostics` modules are selected.

## Documentation

- [Roadmap](Flutter-Android-App-Template-Roadmap-v0.1.0-to-v1.0.0.md)
- [Execution protocol](FLUTTER-AGENT-EXECUTION-PROTOCOL.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Modules](docs/MODULES.md)
- [Compatibility](docs/COMPATIBILITY.md)
- [Security baseline](docs/SECURITY-BASELINE.md)
- [Testing](docs/TESTING.md)
- [Upgrading](docs/UPGRADING.md)
- [Contributing](CONTRIBUTING.md)
- [Security policy](SECURITY.md)
- [Changelog](CHANGELOG.md)

## License

[MIT](LICENSE)
