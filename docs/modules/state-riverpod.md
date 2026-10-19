# state-riverpod

Riverpod provider scope and shared application state.

## Capabilities

- `ProviderScope` above the app root.
- `appStateProvider` and immutable `AppState` for shared feature state.
- Test overrides via `ProviderScope`.

## Requires

- `architecture-core`

## Setup

No provider setup is required. Add feature providers in feature folders; do not
register them in this module.

## Removal

Not applicable at v0.2.0.

## Tests

- Provider scope wraps the app root.
- `AppState` is immutable via `copyWith`.
