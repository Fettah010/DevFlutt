# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/Fettah010/DevFlutt/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/Fettah010/DevFlutt/releases/tag/v0.3.0
