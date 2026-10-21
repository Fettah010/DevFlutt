# state-riverpod

Riverpod provider scope and shared application state.

## Capabilities

- `AppProviderScope` wraps the application root; `bootstrap()` uses it as the only root scope.
- `appStateProvider` and immutable `AppState` for shared application state.
- Test overrides via `ProviderScope`.

## Requires

- `architecture-core`

## Setup

No provider setup is required. Add feature providers in feature folders; do not
register them in this module.

## Conventions

- The `domain` and `data` layers of a feature never import Riverpod. The `application`
  layer owns the providers that wire the domain to the data source.
- Riverpod 3 moved `StateProvider` and `StateNotifierProvider` to
  `package:flutter_riverpod/legacy.dart`. Use `Notifier` and `NotifierProvider`.

## Removal

Not applicable (modules are generation-time selections).

## Tests

- Provider scope wraps the app root.
- `AppState` is immutable via `copyWith`.
