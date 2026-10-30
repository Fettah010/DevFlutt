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

The Android-only `background-work`, `local-notifications`, and `app-updates` modules are
rejected for unsupported target platforms before generation. `background-work` declares
the WorkManager boot, wake-lock, and network-state permissions and removes the plugin's
unused foreground-service permissions. `local-notifications` alone declares
`POST_NOTIFICATIONS` and `VIBRATE`, and enables core-library desugaring required by its
plugin. The notification permission is requested at runtime only after an explicit
application action.
`app-updates` requires an installation distributed through Google Play for Play availability
and update flows to work. Its HTTPS listing fallback can be used when the Play API is
unavailable; the module does not add the `INTERNET` permission.

The template targets Android API 24 or newer. The `INTERNET` permission is declared only by
a module that ships a network client - `networking`, `auth-firebase`, and `auth-supabase` -
and is written into the main manifest, so a release build can reach the network. A project
that selects none of them declares no permission at all. The `INTERNET` permission is a
normal install-time permission and raises no runtime prompt.

The Firebase Android SDK contributes `ACCESS_NETWORK_STATE` and `READ_GSERVICES` from its
own manifest. Those are the provider's permissions, not the template's, and they are visible
in the merged release manifest of an `auth-firebase` project.

- Conservative Kotlin flags (`android.builtInKotlin=false`, `android.newDsl=false`,
  `android.enableIncrementalKotlin=false`, `kotlin.incremental=false`) are used because of
  flutter/flutter#192167 (built-in Kotlin validation fails on AGP 9.1+) and to avoid
  Kotlin incremental-cache corruption on generated-project Gradle runs.
- The release manifest requests `INTERNET` only when the selection includes a network
  client (`networking`, `auth-firebase`, or `auth-supabase`). CI verifies that match with
  `aapt2 dump permissions`.
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
| `shared_preferences` | `^2.5.6` | `preferences` |
| `drift` | `^2.35.3` | `local-database` |
| `drift_flutter` | `^0.3.1` | `local-database` |
| `drift_dev` | `^2.35.2` | `local-database` development dependency |
| `build_runner` | `^2.17.1` | `local-database` development dependency |
| `workmanager` | `^0.10.10` | `background-work` |
| `flutter_local_notifications` | `^22.3.3` | `local-notifications` |
| `in_app_update` | `^5.0.0` | `app-updates` |
| `url_launcher` | `^6.3.3` | `app-updates` |

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
| `preferences` | pass | pass | pass | pass | pass |
| `local-database` | pass | pass | pass | pass | pass |
| `offline-data` | pass | pass | pass | pass | pass |
| `commerce` | pass | pass | pass | pass | pass |
| `commerce-persistence` | pass | pass | pass | pass | pass |
| `background-work` | pass (local) | pass (local) | pass (local) | pass (local) | pass (local) |
| `local-notifications` | pass (local) | pass (local) | pass (local) | pass (local) | pass (local) |
| `app-updates` | pass (local) | pass (local) | pass (local) | pass (local) | pass (local) |
| `background-work` + `local-notifications` | pass (local) | pass (local) | pass (local) | pass (local) | pass (local) |

The release APK column is exercised for the three authentication presets and the five
v0.7 persistence/commerce compositions in CI, and those merged release manifests are reviewed
for permissions. The v0.8 module rows record local generated-project validation; release
manifest permission checks and the WorkManager component presence/absence check are wired
into CI, whose run evidence is pending.

## Coverage method

The matrix is exercised in CI on every pull request. Each named preset is generated
into a temporary directory and then resolved, format-checked, analyzed, tested, and
fully built with debug and release APKs. Individual module manifests are validated
separately. The generator's own tests enumerate acceptance and absence rules for service
and platform modules: a blank project has no optional service files, dependencies,
imports, or module-specific permissions; selected projects receive only their declared
files and native configuration. Pairwise and maximum-coverage combinations are scheduled
for v0.10.0.

The three authentication presets are covered by the same method. Every adapter is verified
against one shared contract-test suite, and the generator's own tests enumerate the
selection rules: an unknown provider is refused, two providers are refused, an unknown
capability is refused, and a capability the chosen provider does not implement is refused
with a message that names the providers that do.

**The gap.** The matrix covers the four presets, the three authentication presets, the
five v0.7 compositions, and the three v0.8 platform modules individually. It does not
cover every combination of the modules that can coexist, and it does not cover the
maximum-capability composition. The exhaustive pairwise set is v0.10.0 work, and the
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
| Dependency audit | `osv-scanner` 2.7.0, pinned with a verified checksum | root, generator, and optional module dependency lockfiles |
| Licence inventory | `tool/license_inventory.dart` | Every locked package, including the optional module dependency union, with licence read from resolved `LICENSE` files |

The generator's lockfile is committed so license inventory, generator tests, and the
dependency audit use the same package graph locally and in CI. The
`tool/module_dependency_audit` lockfile is also committed: it is a versioned union of
optional generated-app dependencies, not a reusable-library lockfile.

## Known gaps

- The v0.8 API 33+ emulator and physical-device permission/tap/background smoke, and the
  Play internal-track update test, remain unverified. The local AVD entries could not be
  started because their configuration files contain unresolved placeholders.
- v0.8 release APK sizes are recorded as single-build reference values in the completion
  report; no repeated performance measurement or size budget is claimed.
- iOS build smoke is scheduled for v0.10.0. The three v0.8 modules are Android-only and
  are rejected for iOS before generation.
- The `DioApiClient` error mapping is verified by review and by the contract tests over
  the fake client; the Dio transport itself is not exercised against a live server.
- The live Firebase and Supabase auth flows are not exercised: no provider project was
  available, so every provider behaviour is verified by contract tests over a fake. The
  provider configuration placeholders and the start-up configuration check are verified.
- The built matrix covers the four presets, the three authentication presets, the five
  v0.7 compositions, and the three v0.8 platform modules individually, not every
  combination of the modules that can coexist. The exhaustive pairwise set is v0.10.0 work.
- The generator is a CLI proof of scope; `doctor` and `update-guide` arrive later.
- The release signing configuration is still the debug key; real signing arrives later.
