# Upgrading

## v0.7.0 module additions

The v0.7.0 generator adds optional `devDependencies` to module manifests. Existing manifests
without that key remain valid. A selected `local-database` module adds Drift runtime packages
and Drift/build_runner development packages; other generated projects receive none of them.

The new `preferences`, `local-database`, `offline-data`, `commerce`, and
`commerce-persistence` modules are not added to existing presets. Regenerate an app to add a
module, or copy its listed outputs and dependencies into an existing app. If you change Drift
tables or queries, run `dart run build_runner build` and keep the generated database source
with the table declaration. Schema changes require an explicit migration and a test that
starts from the previous schema.

## "Use this template" copies a snapshot

Clicking **Use this template** creates a **copy** of the repository at that moment. Later
commits to the template do **not** flow into the copy. There is no automatic update channel,
and the template does not pretend otherwise.

Two consequences follow:

- A copied project pins the template version it was created from. The version is recorded in
  `.devflutt.yaml`.
- Moving a copy forward is a manual, reviewed change — exactly like any other dependency
  upgrade. The notes below say what changed in each release so that the change can be made
  deliberately.

The generator is different: it always generates from the template version you have checked
out, so upgrading the generator is a `git pull` in the template repository.

## Comparing a project with the current template

Every generated project carries `.devflutt.yaml`:

```yaml
template_version: 0.4.0
project_name: My App
package: my_app
application_id: com.example.my_app
modules:
  - architecture-core
  - logging
sdk_constraints:
  dart: ">=3.13.0 <4.0.0"
  flutter: ">=3.47.0 <3.48.0"
```

It records the template version, the selected modules, and the SDK constraints. It contains no
timestamp and no host-specific path, so generation stays deterministic.

To see what a newer template would produce for the same selection, generate it into a
temporary directory and diff the result against the project:

```bash
# In the template repository, at the version you want to move to
dart run tool/ftemplate_cli/bin/ftemplate.dart create \
  --name "My App" --org com.example --preset core --output /tmp/my_app_new

# In the project
diff -ru /tmp/my_app_new/lib ./lib
```

The files the generator owns are the ones it writes. Files you have edited are yours: the
generator never rewrites an existing project, and there is no merge tool. Review the diff and
apply what you want.

## Release notes for upgrading

### To v0.8.0

**What changed**

- New opt-in Android-only modules: `background-work`, `local-notifications`, and
  `app-updates`. No preset changes; projects that do not select them remain unaffected.
- `local-notifications` adds the `POST_NOTIFICATIONS` permission and Android core-library
  desugaring only when selected. The service does not request permission on startup.
- WorkManager scheduling is best-effort and exposes success/retry only. Task input is
  persisted and must not contain credentials or sensitive user data.
- Play in-app updates require distribution through Google Play. The module provides an
  app-specific HTTPS Store listing fallback; it does not provide production-track or
  Play Console configuration.
- Android-only module selections are refused for unsupported target platforms.

**How to upgrade**

1. Compare against the new template as described above; generated projects are not updated
   automatically.
2. To add notifications, regenerate with `--module local-notifications` and copy its
   dependencies, generated Android changes, service files, and tests. The module brings
   `navigation` as a prerequisite. Request permission after a user action and handle denial.
3. To add background work, regenerate with `--module background-work`, register app-owned
   task logic in the top-level callback dispatcher, and pass only small serializable,
   non-sensitive input values.
4. To add app updates, regenerate with `--module app-updates`, supply the generated
   application ID to `PlayAppUpdateClient`, and test the flow using a build installed from a
   Google Play internal-testing track. Observe `installStatus` for flexible download
   progress and call `completeFlexibleUpdate()` after the status becomes `downloaded`.

### To v0.5.0

**What changed**

- New modules: `auth-core` and the three mutually exclusive adapters `auth-rest`,
  `auth-firebase`, and `auth-supabase`. They are opt-in; a project that does not select one
  is unaffected. **No preset changes**: the road map says the provider is chosen explicitly
  rather than guessed, so `blank`, `core`, `demo`, and `recommended` still select no
  provider.
- New generator options: `--auth none|rest|firebase|supabase` selects a provider, and
  `--auth-capability` declares a capability the application needs. A selection whose
  provider cannot satisfy a declared capability is refused before anything is written, with
  a message that names the providers that can.
- The module manifest schema gains one **optional** field, `capabilities`. A manifest
  without it still validates.
- A project that selects an authentication adapter gains an `AppServices.authAdapter`
  field, and the `auth-core` contract files under `lib/core/auth/`.
- The routing module gains an `authRouteGuard` helper when an adapter is selected too. The
  default redirect hook is unchanged, so the behaviour of an existing project does not
  change until the application opts in.
- `firebase_auth` 7.0.0 and `firebase_core` 5.0.0 apply the Kotlin Gradle Plugin, and
  Flutter 3.47 warns that future Flutter versions will refuse such plugins. The build
  succeeds on the pinned toolchain. `supabase_flutter` 2.18.3 is the pinned version; the
  3.0.0 pre-release is not used.

**How to upgrade**

1. Compare against the new template as described above.
2. Authentication is opt-in, so nothing changes unless you want it. To add it, regenerate
   with `--auth firebase`, `--auth supabase`, or `--auth rest`, and copy the new
   `lib/core/auth/` tree into the project.
3. For `auth-firebase`, run `flutterfire configure` in the project. It replaces the
   placeholder `lib/firebase_options.dart` with your own configuration. Until then the
   application refuses to start with a message that names the command.
4. For `auth-supabase`, replace the values in `lib/core/auth/supabase/supabase_config.dart`
   with your project URL and publishable key.
5. For `auth-rest`, fill in `defaultRestAuthConfig` in
   `lib/core/auth/rest/rest_auth_config.dart` with your backend's paths and field names.
6. The application supplies its own login route and screen; the template ships the
   contract, the redirect, and the states, not the form. See `docs/DEFERRED.md`.

### To v0.4.0

**What changed**

- The `core` preset now includes the `logging` module. A core project gains
  `lib/core/logging/`, an `AppServices.logger` field, and a `services` field on the root
  widget. The logger adds **no** dependency, so the lockfile does not change.
- The root widget `DevFluttApp` gains a nullable `services` field when a service module is
  selected. Its constructor stays `const` when no service module is installed, so a project
  without one needs no change.
- The new `networking`, `secure-storage`, and `diagnostics` modules are opt-in. A project that
  does not select them is unaffected.
- The `secure-storage` module generates Android backup-exclusion resources and two
  `<application>` attributes. A project that does not select it is unaffected.

**How to upgrade**

1. Compare against the new template as described above.
2. If you use the `core` preset, copy `lib/core/logging/` from the new template and add the
   `AppServices` file and the `services` field. The `logging` module has no dependency, so
   nothing changes in `pubspec.yaml`.
3. If you already had your own logger, keep it, or switch to the template's `AppLogger` and
   delete the duplicate. The template's logger redacts before the sink, which a hand-rolled
   logger usually does not.

### To v0.3.0

**What changed**

- The `core` preset gained the `design-system` and `feature-example` modules.
- `APP_ENV` wire names changed from `development`/`staging`/`production` to
  `dev`/`staging`/`prod`, so they match the Gradle flavor names. Update the `--dart-define`
  values in your build commands.
- Android builds must name a flavor: `flutter build apk --debug --flavor dev`.

**How to upgrade**

1. Rename the `APP_ENV` values in your build scripts and CI.
2. Add `--flavor` to every Android build command.
3. Copy the new theme, tokens, and route files if you want them; the theme API is unchanged
   from v0.1.0.

### To v0.2.0

The first release with a generator. A project created before v0.2.0 was copied from the
repository root; from v0.2.0 onward, use the generator so the metadata marker and the module
selection are recorded.

## When a change breaks a published contract

Before `v1.0.0`, a change to a CLI flag, a module ID, the manifest schema, a preset's
contents, or the generated layout is allowed, and each one is listed in `CHANGELOG.md` with
the note you are reading here. The compatibility table in
[COMPATIBILITY.md](COMPATIBILITY.md) records the current state of every module and preset.
