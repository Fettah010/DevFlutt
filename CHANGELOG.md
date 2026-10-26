# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.7.0] - 2026-10-27

### Added

- v0.7 persistence and feature modules: non-sensitive preferences, Drift/SQLite with a v1→v2
  migration, an explicit-refresh offline notes sample, a demo cart/checkout contract, and an
  optional Drift-backed cart store. Existing presets remain unchanged.
- Generator support for optional module development dependencies and generated-project
  coverage for each v0.7 module composition.

### Security and behavior boundaries

- Offline refresh invalidates freshness before a request; failed refreshes preserve local
  records and leave queued writes for explicit replay with stable operation IDs.
- The database is unencrypted, preferences are not for secrets, and the commerce estimate is
  not authoritative checkout pricing. No payment SDK or background sync is included.

## [0.6.0] - 2026-10-26

### Added

- A Patrol smoke test that launches the actual reference app and verifies its visible home
  content and semantics, plus native lifecycle, system-theme, and Wi-Fi-disabled regression
  tests.
- A local Patrol runner that selects an explicit device or AVD, waits for Android boot,
  records tool/device details, enforces timeouts and nonempty successful test summaries, and
  captures Patrol/Flutter/Android logcat on failures.
- Android instrumentation host setup and build-time test discovery, so Patrol tests are
  reported as native JUnit tests instead of silently producing an empty Gradle report.
- An emulator-backed Patrol CI workflow with uploaded reports, videos, screenshots, and
  runner diagnostics.
- Unit tests for Patrol result-summary validation.

### Changed

- Pin Patrol 4.10.0 and Patrol CLI 4.8.0; refresh third-party license notices.
- Replace the synthetic generated-project Patrol matrix with real reference-app coverage.

### Removed

- Placeholder permission checks that passed without requesting a permission or observing a
  system permission flow.

### Notes

- The Wi-Fi test verifies that the blank app renders while Wi-Fi is disabled; it does not
  claim offline data synchronization. Physical-device, iOS, and generated-project Patrol
  coverage remain unverified or deferred.

## [0.5.0] - 2026-10-22

### Added

- ADR-006 (auth and backend adapters, capability descriptors, and token-refresh
  serialization), with dated evidence and revisit triggers.
- New modules: `auth-core`, `auth-rest`, `auth-firebase`, and `auth-supabase`. The three
  adapters are mutually exclusive.
- A provider-neutral authentication contract: `AuthAdapter`, `AuthSession`, `AuthUser`,
  `AuthState`, a sealed `AuthError`, and an `AuthCapability` descriptor. No provider SDK
  type appears in a signature.
- A shared contract-test suite, run against every adapter over the capabilities that
  adapter implements.
- A single-flight `TokenRefreshCoordinator`: concurrent expired-token requests cause
  exactly one refresh, and a refresh that fails signs the user out instead of being
  retried.
- A router redirect that sends an unauthenticated user to the login location and preserves
  the intended destination of a protected deep link, without looping.
- New generator options: `--auth none|rest|firebase|supabase` selects a provider, and
  `--auth-capability` declares a capability the application needs. A selection whose
  provider cannot satisfy a declared capability is refused before anything is written.
- An optional `capabilities` field in the module manifest schema.
- A `FakeAuthAdapter`, so an application can test its own features without a provider.
- Documentation: `docs/modules/auth-core.md`, `docs/modules/auth-rest.md`,
  `docs/modules/auth-firebase.md`, `docs/modules/auth-supabase.md`, and `docs/DEFERRED.md`.

### Changed

- The Supabase adapter persists the session through the template's secure store rather
  than the package's `shared_preferences` default, so the refresh token is not written to
  an unencrypted, auto-backed-up file.
- The `verify` script resolves `aapt2.exe` on Windows. The release-permission check
  previously always skipped locally, so it never ran outside CI.

### Fixed

- The Firebase configuration placeholder is no longer shaped like an API key, so a secret
  scanner cannot mistake it for a credential.
- **A project with a network client now declares the `INTERNET` permission.** The generator
  collected the permissions declared by the module manifests but never wrote them into the
  Android manifest, so a release build of a `recommended`, `auth-rest`, or `auth-supabase`
  project could not reach the network at all: Flutter's debug manifest adds the permission
  and the release manifest does not. The permission is now declared by the `networking`,
  `auth-firebase`, and `auth-supabase` modules and written into the main manifest through
  a bounded insertion point. A project without a network client still declares none.

### Notes

- No preset changes. The provider is chosen explicitly, never guessed.
- The live Firebase and Supabase flows are not verified: no provider project was available.
  Every provider behaviour in this release is contract-tested against a fake.

## [0.4.0] - 2026-10-22

### Added

- ADR-004 (HTTP client, typed error model, retry policy, cache policy, and token-refresh
  serialization) and ADR-007 (logging, crash-reporting, and analytics adapters with their privacy
  defaults), both with dated evidence and revisit triggers.
- New modules: `logging`, `networking`, `secure-storage`, and `diagnostics`.
- New `recommended` preset: the core project plus the HTTP, diagnostic, and secure-storage
  plumbing.
- A structured logger with severity, category context, a debug/release verbosity policy, and a
  redactor that runs before any sink, so a sink cannot leak a sensitive value by omission.
- A typed HTTP layer behind an app-owned `ApiClient`: timeouts, cancellation, request
  correlation, typed error mapping, and a bounded retry that never replays a non-idempotent
  request. Only one file imports `dio`.\
- A `FakeApiClient`, so every transport rule is tested with no live service.
- Secure key-value storage behind a `SecureStore` interface, backed by
  `flutter_secure_storage`, with the Android backup exclusion generated so encrypted values are
  never restored without their Keystore key.
- An app-owned `ErrorReporter` interface with a local, in-memory adapter. No provider SDK, no
  analytics, and no telemetry.
- A generated composition root, `lib/app/app_services.dart`, that wires the selected services
  once at startup.
- Three supply-chain gates in CI: a pinned `gitleaks` secret scan, a pinned `osv-scanner`
  dependency audit, and a licence-inventory check.
- `THIRD-PARTY-NOTICES.md`, generated from the lockfiles with each licence read from the
  resolved package's `LICENSE` file.
- `docs/SECURITY-BASELINE.md`, the threat-model boundary, and a mapping of the relevant OWASP
  MASVS areas to the checks that verify them.

### Changed

- The `core` preset now includes `logging`, so a core project has a baseline logging interface
  with no extra dependency.
- The generated root widget gains a nullable `services` field when a service module is selected.
  The constructor stays `const` when no service module is installed.
- The local verify script now runs the generator checks and the licence-inventory check, and its
  format check scopes to `lib` and `test` — the brick templates are not parseable Dart.
- CI adds the `recommended` preset to the generated-project matrix.

### Fixed

- The local verify script formatted the whole repository, which always failed on the Mason
  brick templates. It now formats `lib` and `test`, exactly as CI does.

## [0.3.0] - 2026-10-21

### Added

- ADR-001 (Riverpod) and ADR-003 (go_router) with dated evidence and revisit triggers.
- New modules: `design-system`, `feature-example`, `showcase`.
- New `demo` preset: the core project plus the component showcase page.
- Single startup path: `main()` delegates to `bootstrap()`, which owns configuration and
  the provider scope.
- Design tokens (`AppSpacing`, `AppRadius`, `AppDurations`) and an expanded Material 3
  light/dark theme.
- Typed environment configuration for `APP_NAME`, `APP_ENV`, `API_BASE_URL`, and
  `FEATURE_FLAGS`; invalid values fail fast without echoing the offending value.
- Route registry (`AppRoutes`), guarded redirect extension point (`RouteRedirect`,
  `routeGuard`), and a not-found screen for unknown locations.
- Shared application state (`AppState`, `appStateProvider`) and a single root provider scope.
- Reusable widgets: primary and secondary buttons, text field, card, inline message, and
  loading/empty/error views.
- Counter feature example across the domain, data, application, and presentation layers.
- Android product flavors `dev`, `staging`, and `prod` with a per-flavor application ID
  suffix and launcher label.
- Generated-project tests for the theme, the router, the counter, and the configuration.
- A format gate for the generated projects in CI.

### Changed

- The `core` preset now includes `design-system` and `feature-example`.
- The `blank` preset lists `architecture-core` explicitly, because the base scaffold has
  always been architecture-core and the manifest must say so.
- `APP_ENV` wire names changed from `development`/`staging`/`production` to
  `dev`/`staging`/`prod` so that they match the Gradle flavor names.
- CI pins Flutter 3.47.7, adds `demo` to the generated-project matrix, and builds every
  APK with an explicit `--flavor`.
- The generator now runs the canonical Dart formatter over the generated files, so every
  generated project is format-clean whatever the brick looks like. The generator package
  depends on `dart_style` and `pub_semver`; generated applications do not.

[Unreleased]: https://github.com/Fettah010/DevFlutt/compare/v0.7.0...HEAD
[0.7.0]: https://github.com/Fettah010/DevFlutt/releases/tag/v0.7.0
[0.6.0]: https://github.com/Fettah010/DevFlutt/releases/tag/v0.6.0
[0.5.0]: https://github.com/Fettah010/DevFlutt/releases/tag/v0.5.0
[0.4.0]: https://github.com/Fettah010/DevFlutt/releases/tag/v0.4.0
[0.3.0]: https://github.com/Fettah010/DevFlutt/releases/tag/v0.3.0
