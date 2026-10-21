# Architecture

## Overview

The DevFlutt reference app uses a **feature-first structure with lightweight layers**. The blank
preset is deliberately minimal; optional modules add state management, routing, shared widgets, and
examples without forcing every small feature through excessive interfaces.

Every generated project shares one startup path, one naming convention, and one set of design
tokens. Modules add files and registrations; they never introduce a second theme, a second router,
or a second global state container.

## Directory structure

```text
lib/
  main.dart                        # entry point
  bootstrap/bootstrap.dart         # single startup path; optional ProviderScope
  app.dart                         # MaterialApp / MaterialApp.router root
  app/
    app_routes.dart                # AppRoutes path constants
    app_router.dart                # GoRouter + guarded redirect extension point
    route_guard.dart               # RouteRedirect typedef
    not_found_page.dart            # unknown-route screen
  core/
    config/app_config.dart         # typed, validated configuration boundary
    theme/app_tokens.dart          # spacing/radius/motion tokens
    theme/app_theme.dart           # Material 3 light/dark themes
    state/provider_scope.dart      # Riverpod scope
    state/app_state.dart           # shared application state
    widgets/                       # reusable shared widgets
  features/
    home/home_page.dart            # example screen
    counter/                       # feature example
      domain/counter.dart
      data/counter_repository.dart
      application/counter_controller.dart
      presentation/counter_page.dart
    showcase/presentation/showcase_page.dart
test/
  unit/                            # domain + config tests
  widget/                          # UI + theme tests
android/                           # Android platform project
tool/verify/                       # local quality gate scripts
docs/                              # plans, reports, ADRs, testing
```

The exact file list depends on the selected modules. The `blank` preset ships the base scaffold
only; the `core` preset adds state, routing, the design system, and the counter example; the
`demo` preset adds the showcase.

## Startup path

`main()` delegates to `bootstrap()`, which is the only place that resolves configuration and runs
the app. When the `state-riverpod` module is installed, `bootstrap()` wraps the app in the single
`AppProviderScope`. No other code creates a root scope.

```text
main() ──▶ bootstrap() ──▶ AppConfig.fromEnvironment() ──▶ [AppProviderScope] ──▶ runApp()
```

## Dependency direction

```text
UI (presentation)  ──▶  application / state  ──▶  domain contracts  ◀──  data + platform adapters
```

- UI never calls raw HTTP clients, secure storage, or database APIs.
- Provider-specific SDKs stay behind adapter implementations.
- Features use app-owned models, errors, and results rather than provider SDK types.
- The `domain` and `data` layers of a feature never import Flutter or Riverpod. Only the
  `application` layer and the presentation wiring depend on the state package.

## Layer responsibilities

| Layer | Responsibility | Introduced |
|-------|----------------|------------|
| `bootstrap` | Single startup path and provider scope | v0.3.0 |
| `core/config` | Typed, validated startup configuration | v0.1.0 |
| `core/theme` | Design tokens and light/dark themes | v0.1.0 |
| `core/state` | Provider scope and shared application state | v0.2.0 |
| `core/widgets` | Reusable shared components | v0.3.0 |
| `app` | Route registry, router, redirect hook, unknown-route screen | v0.3.0 |
| `features/<feature>` | One self-contained feature (presentation/application/domain/data as needed) | v0.1.0 |
| `core/*` (future) | Errors, logging, result types, platform guards | v0.4.0+ |

## Routing model

Every route path is a constant in `AppRoutes`; navigation never uses a raw string literal.
`buildAppRouter()` maps the constants to screens and applies the `RouteRedirect` hook. The
template ships the hook as an extension point only; the host application supplies the
authentication rules.

| Concern | Owner |
|---------|-------|
| Route paths | `app/app_routes.dart` |
| Route to screen mapping | `app/app_router.dart` |
| Redirect decision | `app/route_guard.dart` |
| Unknown-route screen | `app/not_found_page.dart` |

## Environments and build identity

`AppConfig` reads `APP_NAME`, `APP_ENV`, `API_BASE_URL`, and `FEATURE_FLAGS` from compile-time
defines and validates them. The Android side adds `dev`, `staging`, and `prod` product flavors;
a flavor decides the application ID suffix and the launcher label. The `APP_ENV` wire names match
the flavor names.

Invalid configuration fails fast with an actionable message. The messages never repeat the
offending value, because configuration values can carry deployment details that must not reach
logs.

## Conventions

- One feature folder per feature; no feature imports another feature's internals.
- Prefer `const` constructors and small files.
- No `print` in app code; use the logging interface once the logging module is selected.
- No ad-hoc global state; registrations flow through generated registries or documented
  integration points.
- Shared state lives in `core/state`; feature state lives in the feature that owns it.

## Open decisions

These are resolved by ADRs in the milestone that needs them:

- `ADR-001` State management (Riverpod) — accepted, v0.3.0
- `ADR-003` Routing package and route-registration model — accepted, v0.3.0
- `ADR-004` HTTP client and error/retry model — v0.4.0

See [ADR-000-template.md](adr/ADR-000-template.md) for the ADR format.
