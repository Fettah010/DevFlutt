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

The release APK column is exercised for the three authentication presets and the five
v0.7 persistence/commerce compositions, and those merged release manifests are reviewed
for permissions.

## Coverage method

The matrix is exercised in CI on every pull request. Each named preset is generated
into a temporary directory and then resolved, format-checked, analyzed, tested, and
fully built with debug and release APKs. Individual module manifests
are validated separately. The generator's own tests enumerate the acceptance and
absence rules for the four service modules: a blank project has no service file, no
service dependency, and no service import; a core project has the logger and no
transport or store; a recommended project has every service file, the composition
root, and the Android backup rules. Pairwise and maximum-coverage combinations are
scheduled for v0.10.0.

The three authentication presets are covered by the same method. Every adapter is verified
against one shared contract-test suite, and the generator's own tests enumerate the
selection rules: an unknown provider is refused, two providers are refused, an unknown
capability is refused, and a capability the chosen provider does not implement is refused
with a message that names the providers that do.

**The gap.** The matrix covers the four presets, the three authentication presets, and the
five v0.7 compositions (`preferences`, `local-database`, `offline-data`, `commerce`,
`commerce-persistence`). It does not cover every combination of the modules that can
coexist, and it does not cover the maximum-capability composition. The exhaustive pairwise
set is v0.10.0 work, and the remaining gap is recorded in `docs/DEFERRED.md`.

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

- iOS build smoke is scheduled for v0.10.0. The new modules are platform-neutral in
  their Dart, but no iOS build has been observed.
- Emulator/device smoke and performance baselines are scheduled for v0.10.0.
- The `DioApiClient` error mapping is verified by review and by the contract tests over
  the fake client; the Dio transport itself is not exercised against a live server.
- The live Firebase and Supabase auth flows are not exercised: no provider project was
  available, so every provider behaviour is verified by contract tests over a fake. The
  provider configuration placeholders and the start-up configuration check are verified.
- The built matrix covers the four presets, the three authentication presets, and the five
  v0.7 compositions individually, not every combination of the modules that can coexist.
  The exhaustive pairwise set is v0.10.0 work.
- The generator is a CLI proof of scope; `doctor` and `update-guide` arrive later.
- The release signing configuration is still the debug key; real signing arrives later.
