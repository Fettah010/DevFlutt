# navigation

Declarative routing with go_router and deep-link support.

## Capabilities

- `buildAppRouter()` returns a configured `GoRouter`.
- `AppRoutes` holds every route path constant; navigation never uses a raw string literal.
- `RouteRedirect` typedef plus a `routeGuard` extension point for authentication and
  feature-flag redirects.
- Initial location `/` rendering the home screen.
- Cold-start deep-link and unknown-route handling: the unknown route renders
  `NotFoundPage`.

## Requires

- `architecture-core`
- `state-riverpod`

## Setup

No provider setup is required. Add a route constant in `AppRoutes` and register the
screen in `buildAppRouter`.

## Removal

Not applicable (modules are generation-time selections).

## Tests

- The router is generated and applied via `MaterialApp.router`.
- Unknown routes fall back to the not-found screen.
- The redirect hook is applied to a location.
- Every declared route is an absolute path.
