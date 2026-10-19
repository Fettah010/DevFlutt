# navigation

Declarative routing with go_router and deep-link support.

## Capabilities

- `buildAppRouter()` returns a configured `GoRouter`.
- Initial location `/` rendering the home screen.
- Cold-start deep-link and unknown-route handling (extend `buildAppRouter`).

## Requires

- `architecture-core`
- `state-riverpod`

## Setup

No provider setup is required. Add routes in `buildAppRouter`.

## Removal

Not applicable at v0.2.0.

## Tests

- The router is generated and applied via `MaterialApp.router`.
- Unknown routes fall back to the root location by default.
