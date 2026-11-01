# navigation

Declarative routing with go_router and deep-link support.

## Capabilities

- `buildAppRouter()` returns a configured `GoRouter`.
- `AppRoutes` holds every route path constant; navigation never uses a raw string literal.
- `RouteRedirect` typedef plus a `routeGuard` extension point for authentication and
  feature-flag redirects.
- `authRouteGuard`, added when an authentication adapter is selected too: it sends an
  unauthenticated user to the login location and preserves the intended destination, so a
  protected deep link returns the user to where they were going after they sign in.
- Initial location `/` rendering the home screen.
- Cold-start deep-link and unknown-route handling: the unknown route renders
  `NotFoundPage`.
- A short fade route transition with shared duration/curve tokens; `MediaQuery.disableAnimations`
  selects an immediate `NoTransitionPage`.

## Requires

- `architecture-core`
- `state-riverpod`

## Setup

No provider setup is required. Add a route constant in `AppRoutes` and register the
screen in `buildAppRouter`.

When an authentication adapter is selected, wire the guard in `app.dart`:

```dart
late final _router = buildAppRouter(
  redirect: authRouteGuard(
    authAdapter: services!.authAdapter,
    loginLocation: AppRoutes.login,
  ),
);
```

The template ships no login screen, so the login location is the application's own route.

## Removal

Not applicable (modules are generation-time selections).

## Tests

- The router is generated and applied via `MaterialApp.router`.
- Unknown routes fall back to the not-found screen.
- The redirect hook is applied to a location.
- Every declared route is an absolute path.
- Route navigation is tested with animations enabled and disabled.
- When an authentication adapter is selected: an unauthenticated user is sent to the login
  location, the intended destination is preserved, the login location is not redirected
  again, and a signed-in user is let through.
