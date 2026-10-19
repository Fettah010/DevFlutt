# Compatibility

## Tested toolchain

| Component | Version |
|---|---|
| Flutter | 3.47.6 |
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

## Generation matrix

| Preset | pub get | analyze | test | debug APK |
|---|---|---|---|---|
| `blank` | pass | pass | pass | pass |
| `core` | pass | pass | pass | pass |

## Coverage method

The matrix is exercised in CI on every pull request. Each named preset is generated
into a temporary directory and fully built. Individual module manifests are
validated separately. Pairwise and maximum-coverage combinations are scheduled for
v0.9.0.

## Known gaps

- iOS build smoke is scheduled for v0.9.0.
- Emulator/device smoke and performance baselines are scheduled for v0.9.0.
- The generator is a CLI proof of scope; `doctor` and `update-guide` arrive later.
