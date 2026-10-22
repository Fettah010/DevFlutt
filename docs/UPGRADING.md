# Upgrading

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
