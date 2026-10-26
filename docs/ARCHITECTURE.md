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
    app_services.dart              # generated composition root for the selected services
  core/
    config/app_config.dart         # typed, validated configuration boundary
    theme/app_tokens.dart          # spacing/radius/motion tokens
    theme/app_theme.dart           # Material 3 light/dark themes
    state/provider_scope.dart      # Riverpod scope
    state/app_state.dart           # shared application state
    widgets/                       # reusable shared widgets
    logging/                       # AppLogger, LogRecord, Redactor, sinks
    networking/                    # ApiClient, ApiResult, ApiError, retry policy
    secure_storage/                # SecureStore interface and its adapters
    diagnostics/                   # ErrorReporter interface and its local adapter
    preferences/                   # non-sensitive preference port and adapters
    database/                      # Drift schema, migrations, generated queries
    auth/                          # AuthAdapter contract, session, capabilities, refresh
      rest/                        # the custom REST/JWT adapter
      firebase/                    # the Firebase Authentication adapter
      supabase/                    # the Supabase Auth adapter
  features/
    home/home_page.dart            # example screen
    counter/                       # feature example
      domain/counter.dart
      data/counter_repository.dart
      application/counter_controller.dart
      presentation/counter_page.dart
    showcase/presentation/showcase_page.dart
    offline_notes/                 # explicit-refresh local-first sample (optional)
    commerce/                      # demo cart and checkout boundary (optional)
test/
  unit/                            # domain + config + service tests
  widget/                          # UI + theme tests
android/                           # Android platform project
tool/verify/                       # local quality gate scripts
docs/                              # plans, reports, ADRs, testing
```

The exact file list depends on the selected modules. The `blank` preset ships the base scaffold
only; the `core` preset adds state, routing, the design system, the counter example, and the
logger; the `demo` preset adds the showcase; the `recommended` preset adds the networking,
secure-storage, and diagnostics modules. No preset selects an authentication provider: a
project asks for one explicitly with `--auth`, which adds the `auth-core` contract and one
of the three adapters.

## Startup path

`main()` delegates to `bootstrap()`, which is the only place that resolves configuration and runs
the app. When the `state-riverpod` module is installed, `bootstrap()` wraps the app in the single
`AppProviderScope`. No other code creates a root scope.

```text
main() ──▶ bootstrap() ──▶ AppConfig.fromEnvironment() ──▶ [AppProviderScope] ──▶ runApp()
```

## Composition root

When at least one service module is selected, the generator writes
`app/app_services.dart`. It holds exactly the services the selected modules provide, and
`buildAppServices(config)` is the only place that chooses a concrete implementation. A feature
receives the service it needs through its constructor, so the choice stays in one reviewable
file and a test can substitute a fake.

The file is absent when no service module is selected, so a blank project has no service
container at all. The `DevFluttApp` root widget gains a nullable `services` field in the same
way, and the root widget's constructor stays `const` when no service module is installed.

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
| `core/logging` | Structured logging with redaction applied before the sink | v0.4.0 |
| `core/networking` | Typed HTTP client, error mapping, and bounded retry | v0.4.0 |
| `core/secure_storage` | Secure key-value storage behind a small interface | v0.4.0 |
| `core/diagnostics` | App-owned error reporting interface | v0.4.0 |
| `core/auth` | Provider-neutral authentication contract, session model, capability descriptor, serialized token refresh, router redirect | v0.5.0 |
| `app` | Route registry, router, redirect hook, unknown-route screen | v0.3.0 |
| `app/app_services` | Generated composition root for the selected services | v0.4.0 |
| `features/<feature>` | One self-contained feature (presentation/application/domain/data as needed) | v0.1.0 |
| `core/preferences` | Non-sensitive preferences behind an app-owned port | v0.7.0 |
| `core/database` | Drift schema, migrations, and in-memory test database | v0.7.0 |
| `features/offline_notes` | Explicit-refresh sample with durable pending edits | v0.7.0 |
| `features/commerce` | Demo cart and server-authoritative checkout contract | v0.7.0 |

## Authentication model

The authentication layer has one contract and one adapter behind it:

```text
feature ──▶ AuthAdapter (auth-core) ──▶ *AuthPort ──▶ provider SDK
```

- `auth-core` owns the contract, the session and state models, the capability descriptor, the
  secure session store, the single-flight token refresh, and the router redirect. It depends
  on no provider SDK.
- Each adapter owns a **provider port** — the boundary the adapter depends on — and two
  implementations of that port: the real one over the provider SDK, and a fake for tests.
  A provider SDK change therefore touches one thin file, not the contract and not a feature.
- The adapter reports the capabilities it implements. A feature asks
  `authAdapter.capabilities.supports(...)` before it calls an operation it may not have, and
  an unsupported call raises a typed `AuthError.unsupportedCapability`.
- The three adapters are mutually exclusive. A selection of two is refused by the
  generator before anything is written.

The `auth-rest` adapter owns its session and persists it in the secure store, and refreshes
its own token through the shared coordinator. The Firebase and Supabase adapters let the
provider own the session and the refresh, and ask the provider for a token when the
application needs one.

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

When an authentication adapter is selected together with the routing module, the guard
gains `authRouteGuard`: it sends an unauthenticated user to the login location and
preserves the intended destination, so a protected deep link returns the user to where
they were going after they sign in. The template ships no login screen, so the application
supplies the login location.

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
- No `print` in app code; use the logging interface.
- UI never touches a transport, a secure store, or an error-reporting SDK: it receives the
  app-owned interface through its constructor.
- UI never touches a provider SDK either. It receives the `AuthAdapter` and never sees a
  Firebase or Supabase type.
- No ad-hoc global state; registrations flow through generated registries or documented
  integration points.
- Shared state lives in `core/state`; feature state lives in the feature that owns it.

## Open decisions

These are resolved by ADRs in the milestone that needs them:

- `ADR-001` State management (Riverpod) — accepted, v0.3.0
- `ADR-003` Routing package and route-registration model — accepted, v0.3.0
- `ADR-004` HTTP client, error model, retry policy, cache policy, token refresh — accepted, v0.4.0
- `ADR-006` Auth and backend adapters, capability descriptors, token-refresh serialization — accepted, v0.5.0
- `ADR-007` Logging, crash-reporting, and analytics adapters — accepted, v0.4.0

See [ADR-000-template.md](adr/ADR-000-template.md) for the ADR format.
