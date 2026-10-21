# feature-example

Counter feature that demonstrates the layer placement of a real feature.

## Capabilities

- `domain/counter.dart` — the `Counter` value object. Pure Dart.
- `data/counter_repository.dart` — the `CounterRepository` contract and an in-memory
  implementation. Pure Dart.
- `application/counter_controller.dart` — the `Notifier` that wires the domain to the
  repository, plus the repository provider.
- `presentation/counter_page.dart` — the screen.
- Route registration at `/counter` through `AppRoutes`.

## Requires

- `architecture-core`
- `state-riverpod`
- `navigation`

## Setup

No setup is required. The feature is reachable from the home screen and at `/counter`.

## Conventions

- `domain` and `data` never import Flutter or Riverpod.
- `application` owns the providers; `presentation` only reads state and calls methods.
- A feature owns its routes. The router maps the constants to the screens.

## Removal

Not applicable (modules are generation-time selections).

## Tests

- `test/unit/counter_test.dart` — the value object and the repository.
- `test/widget/counter_page_test.dart` — the screen increments and decrements.
