# ADR-003: go_router for declarative routing

- Status: Accepted
- Date: 2026-10-21
- Deciders: DevFlutt maintainers

## Context

v0.3.0 requires the template to provide a real routing layer: named route constants shared across
features, nested and parameterised routes, guarded redirects with an explicit extension point,
and a fall-back for unknown locations. Navigation must stay declarative so that a route can be
inspected in tests without pumping a widget tree, and deep links must work on Android without
extra platform code.

## Options considered

1. **go_router (`package:go_router`)** — declarative `GoRouter` configuration, named routes with
   path parameters and sub-routes, a `redirect` hook for guards, and Android deep-link support via
   the Flutter embedding. Version 18.1.1 published 2026-10-20, Flutter `>=3.44.0`, Dart `^3.12.0`.
2. **`Navigator` 1.0 / imperative `Navigator 2.0`** — built into Flutter with no dependency, but
   imperative push/pop calls make route state invisible to tests and make deep-link restoration
   a manual problem.
3. **`auto_route`** — code-generation based typed routing with strongly typed route arguments;
   adds a build step and generated-code churn to every route change.
4. **`beamer`** — declarative routing with nested navigation and a focus-based API, but a smaller
   ecosystem and fewer published releases.

## Decision

Use go_router. The template generates a single `buildAppRouter()` factory in the `navigation`
module, a `AppRoutes` constant class holding every named route path, and a `RouteRedirect`
typedef plus `routeGuard` extension point in `route_guard.dart` so that authentication or
feature-flag redirects can be added without editing the router construction. Unknown locations
resolve to the root route. The router is applied with `MaterialApp.router`.

Routes are owned by the feature that implements them; the `navigation` module contributes the
registry, the router factory, and the guard extension point, but never a feature's page widget.

## Evidence

- `go_router` 18.1.1 on pub.dev, published 2026-10-20, Flutter `>=3.44.0`, Dart `^3.12.0`
  (checked 2026-10-21).
- Flutter stable 3.47.7 (2026-10-09) ships Dart 3.13.5 and satisfies both constraints
  (checked 2026-10-21).
- The v0.2.0 `core` preset already generated a go_router-based project and passed
  `flutter pub get`, `flutter analyze`, and `flutter test` in CI run `39329418363`
  (verified 2026-10-21).
- go_router 18 documentation: `GoRoute`, `redirect`, `errorBuilder`, and Android deep-link
  configuration (pub.dev, checked 2026-10-21).

## Trade-offs

- Adds a runtime dependency to generated projects that enable the `navigation` module.
- go_router 18 moved some material/cupertino widgets behind separate packages internally; the
  public API used by the template (`GoRouter`, `GoRoute`, `StatefulShellRoute`) is unchanged, but
  the template pins the major version.
- Route parameters are typed only at the call site, so a typo in a path string is a runtime
  failure rather than a compile error; the shared `AppRoutes` constants mitigate this.

## Consequences

- The `navigation` module owns `AppRoutes`, `buildAppRouter()`, and `route_guard.dart`.
- New routes are added as constants in `AppRoutes` and registered in `buildAppRouter()`; the
  generator does not rewrite router files, so additions are explicit and reviewable.
- `RouteRedirect` is a single typedef, so the guard extension point stays replaceable by
  downstream projects without forking the module.
- The template pins the go_router major version in `manifests/modules/navigation.yaml` and
  re-verifies it at each release.

## Revisit triggers

- go_router is unmaintained, or a new major version changes `GoRouter` / `GoRoute` construction
  in a way that breaks the generated router.
- The pinned Flutter SDK moves below go_router's declared Flutter minimum.
- A future milestone requires a routing need (for example typed generated routes) that go_router
  cannot satisfy without a build step and that justifies `auto_route`.
