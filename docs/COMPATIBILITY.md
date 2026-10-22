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
| `dio` | `^5.11.1` | `networking` |
| `flutter_secure_storage` | `^11.2.0` | `secure-storage` |
| `firebase_auth` | `^7.0.0` | `auth-firebase` |
| `firebase_core` | `^5.0.0` | `auth-firebase` |
| `supabase_flutter` | `^2.18.3` | `auth-supabase` |

`go_router` 18 migrated to the `material_ui` and `cupertino_ui` packages internally. The public
API used by the template (`GoRouter`, `GoRoute`, `GoRouterState`) is unchanged, and generated
applications still import `package:flutter/material.dart`.

Riverpod 3 moved `StateProvider` and `StateNotifierProvider` to
`package:flutter_riverpod/legacy.dart`. The template uses `Notifier` and `NotifierProvider`, so no
generated project depends on the legacy library.

`dio` 5.11.1 is pure Dart, so it adds no Android native code, no permission, and no APK
surface. `flutter_secure_storage` 11.2.0 needs Android API 23 or newer; the template uses
`minSdk 24`. Both are `^`-ranged in a generated project, and the generated project's lockfile
is the developer's to commit.

`firebase_auth` 7.0.0 and `firebase_core` 5.0.0 need Android API 24 or newer, which is
exactly the template's `minSdk`. Both still apply the Kotlin Gradle Plugin, and Flutter 3.47
warns that future Flutter versions will refuse plugins that apply it. The build succeeds on
the pinned toolchain, and the warning is recorded rather than hidden.

`supabase_flutter` 2.18.3 needs Flutter 3.35 or newer and brings `app_links`,
`shared_preferences`, `url_launcher`, and `supabase` with it. The 3.0.0 pre-release is
rejected: a pre-release needs a documented material benefit and a fallback, and there is
neither. The session is persisted through the template's secure store rather than the
package's `shared_preferences` default, but `shared_preferences` remains a transitive
dependency of the package.

## Generation matrix

| Preset | pub get | analyze | test | debug APK | release APK |
|---|---|---|---|---|---|
| `blank` | pass | pass | pass | pass | - |
| `core` | pass | pass | pass | pass | - |
| `demo` | pass | pass | pass | pass | - |
| `recommended` | pass | pass | pass | pass | - |
| `core` + `--auth rest` | pass | pass | pass | pass | pass |
| `core` + `--auth firebase` | pass | pass | pass | pass | pass |
| `core` + `--auth supabase` | pass | pass | pass | pass | pass |

The release APK column is exercised for the three authentication presets, and their merged
release manifest is reviewed for permissions.

## Coverage method

The matrix is exercised in CI on every pull request. Each named preset is generated
into a temporary directory and then resolved, format-checked, analyzed, tested, and
fully built with `flutter build apk --debug --flavor dev`. Individual module manifests
are validated separately. The generator's own tests enumerate the acceptance and
absence rules for the four service modules: a blank project has no service file, no
service dependency, and no service import; a core project has the logger and no
transport or store; a recommended project has every service file, the composition
root, and the Android backup rules. Pairwise and maximum-coverage combinations are
scheduled for v0.9.0.

The three authentication presets are covered by the same method. Every adapter is verified
against one shared contract-test suite, and the generator's own tests enumerate the
selection rules: an unknown provider is refused, two providers are refused, an unknown
capability is refused, and a capability the chosen provider does not implement is refused
with a message that names the providers that do.

**The gap.** The matrix covers the four presets and the three authentication presets. It
does not cover every combination of the modules that can coexist, and it does not cover the
maximum-capability composition. The exhaustive pairwise set is v0.9.0 work, and the
remaining gap is recorded in `docs/DEFERRED.md`.

## Generator dependencies

The generator package depends on `dart_style` and `pub_semver` in addition to `mason`.
The formatter runs over the generated files so that a generated project is
format-clean without the brick having to encode the formatter's layout rules. These
are generator-only dependencies; a generated application depends on the Flutter SDK
and the modules it selects.

## Supply-chain checks

| Check | Tool | Scope |
|---|---|---|
| Secret scan | `gitleaks` 8.30.1, pinned with a verified checksum | The whole repository history, with redaction |
| Dependency audit | `osv-scanner` 2.7.0, pinned with a verified checksum | `pubspec.lock` and the generator's lockfile |
| Licence inventory | `tool/license_inventory.dart` | Every locked package, with the licence read from the resolved `LICENSE` file |

The generator's lockfile is not committed, because the generator is a Dart package and
the Dart convention is not to commit a library's lockfile. The dependency audit resolves
it in the runner first, so the generator's dependencies are scanned too.

## Known gaps

- iOS build smoke is scheduled for v0.9.0. The new modules are platform-neutral in
  their Dart, but no iOS build has been observed.
- Emulator/device smoke and performance baselines are scheduled for v0.9.0.
- The `DioApiClient` error mapping is verified by review and by the contract tests over
  the fake client; the Dio transport itself is not exercised against a live server.
- The live Firebase and Supabase auth flows are not exercised: no provider project was
  available, so every provider behaviour is verified by contract tests over a fake. The
  provider configuration placeholders and the start-up configuration check are verified.
- The built matrix covers the four presets and the three authentication presets, not every
  combination of the modules that can coexist. The exhaustive pairwise set is v0.9.0 work.
- The generator is a CLI proof of scope; `doctor` and `update-guide` arrive later.
- The release signing configuration is still the debug key; real signing arrives later.
