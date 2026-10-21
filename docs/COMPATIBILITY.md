# Compatibility

## Tested toolchain

| Component | Version |
|---|---|
| Flutter | 3.47.7 |
| Dart | 3.13.x |
| Gradle | 9.3.1 |
| AGP | 9.1.0 |
| Kotlin | 2.4.0 |
| JDK | 17 |
| compileSdk / targetSdk | 36 |
| minSdk | 24 |

## Android

- Conservative Kotlin flags (`android.builtInKotlin=false`, `android.newDsl=false`)
  are used because of flutter/flutter#192167 (built-in Kotlin validation fails on
  AGP 9.1+).
- The generated app requests no Android permissions. The release manifest must not
  request `INTERNET`; CI verifies this with `aapt2 dump permissions`.
- Every environment is an Android product flavor: `dev`, `staging`, and `prod`. The flavor
  decides the application ID suffix (`.dev`, `.staging`, none) and the launcher label.
- Because flavors are defined, an Android build must name one: `flutter build apk --flavor dev`.
  Without `--flavor`, the Flutter tool cannot pick a variant.

## Packages

| Package | Version | Used by |
|---|---|---|
| `flutter_riverpod` | `^3.4.3` | `state-riverpod`, `feature-example`, `showcase` |
| `go_router` | `^18.1.1` | `navigation`, `feature-example`, `showcase` |

`go_router` 18 migrated to the `material_ui` and `cupertino_ui` packages internally. The public
API used by the template (`GoRouter`, `GoRoute`, `GoRouterState`) is unchanged, and generated
applications still import `package:flutter/material.dart`.

Riverpod 3 moved `StateProvider` and `StateNotifierProvider` to
`package:flutter_riverpod/legacy.dart`. The template uses `Notifier` and `NotifierProvider`, so no
generated project depends on the legacy library.

## Generation matrix

| Preset | pub get | analyze | test | debug APK |
|---|---|---|---|---|
| `blank` | pass | pass | pass | pass |
| `core` | pass | pass | pass | pass |
| `demo` | pass | pass | pass | pass |

## Coverage method

The matrix is exercised in CI on every pull request. Each named preset is generated
into a temporary directory and then resolved, format-checked, analyzed, tested, and
fully built with `flutter build apk --debug --flavor dev`. Individual module manifests
are validated separately. Pairwise and maximum-coverage combinations are scheduled for
v0.9.0.

## Generator dependencies

The generator package depends on `dart_style` and `pub_semver` in addition to `mason`.
The formatter runs over the generated files so that a generated project is
format-clean without the brick having to encode the formatter's layout rules. These
are generator-only dependencies; a generated application depends on the Flutter SDK
and the modules it selects.

## Known gaps

- iOS build smoke is scheduled for v0.9.0.
- Emulator/device smoke and performance baselines are scheduled for v0.9.0.
- The generator is a CLI proof of scope; `doctor` and `update-guide` arrive later.
- The release signing configuration is still the debug key; real signing arrives later.
