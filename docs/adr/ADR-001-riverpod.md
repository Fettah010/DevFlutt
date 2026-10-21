# ADR-001: Riverpod for state management

- Status: Accepted
- Date: 2026-10-21
- Deciders: DevFlutt maintainers

## Context

v0.3.0 requires the generated projects to share one application state approach across features.
The template must pick a state management solution that works with a layered architecture
(`domain` / `data` / `application` / `presentation`), supports provider-level test overrides,
and keeps generated code free of framework-specific magic in the domain and data layers.

The choice must survive long-term maintenance, must compile against the Dart SDK shipped with the
pinned Flutter version, and must not force a bespoke state container onto downstream users.

## Options considered

1. **Riverpod (`package:flutter_riverpod`)** — compile-safe providers, `ProviderScope` overrides,
   no code generation required for the provider API, and first-class test support. Version 3.4.3
   published 2026-09-03, SDK constraint `^3.12.0`.
2. **`ChangeNotifier` + `provider` (built-in Flutter pattern)** — zero third-party dependency and
   excellent IDE integration, but provider scoping is runtime-only, the dependency graph is implicit,
   and overriding a dependency in a test requires replacing the widget subtree.
3. **`bloc` / `cubit`** — explicit event and state types with a strong testing story, but the
   ceremony per feature is high and events add a layer that the roadmap's architecture does not
   otherwise need.
4. **Hand-rolled service locator (`get_it`)** — simple registration and lookup, but it hides
   lifetimes, does not compose with widget-level scoping, and makes test overrides manual.

## Decision

Use Riverpod. The template generates `ProviderScope` above the application root, exposes shared
application state through `appStateProvider`, and keeps providers inside the feature that owns
them. The domain and data layers stay pure Dart and never import Riverpod; only the
`application` layer and the presentation wiring depend on it. Dependencies are resolved through
providers so that tests can override them with `ProviderScope(overrides: [...])` without
touching the widget tree.

## Evidence

- `flutter_riverpod` 3.4.3 and `riverpod` 3.4.3 on pub.dev, published 2026-09-03, SDK constraint
  `^3.12.0` (checked 2026-10-21).
- Flutter stable 3.47.7 (2026-10-09) ships Dart 3.13.5, which satisfies the `^3.12.0` constraint
  (checked 2026-10-21).
- The v0.2.0 `core` preset already generated a Riverpod-based project and passed
  `flutter pub get`, `flutter analyze`, and `flutter test` in CI run `39329418363`
  (verified 2026-10-21).
- Riverpod documentation: providers, `ProviderScope` overrides, and `ProviderContainer` test
  helpers (pub.dev, checked 2026-10-21).

## Trade-offs

- Adds a runtime dependency to generated projects that enable the `state-riverpod` module.
- Riverpod 3 renamed and restructured some 2.x APIs, so the pinned major version must be tracked
  when upgrading.
- Generated code uses `ConsumerWidget` / `ConsumerStatefulWidget` instead of plain `Widget`,
  which requires a mental model change for contributors new to the template.

## Consequences

- The `state-riverpod` module owns the `ProviderScope` wrapper and the shared `AppState`.
- Feature providers live in the feature folder that owns them; the module does not register
  feature providers centrally.
- Domain and data layers must not import `flutter_riverpod`; this is enforced by module review and
  by the generated-project `flutter analyze` gate.
- The template pins the Riverpod major version in `manifests/modules/state-riverpod.yaml` and
  re-verifies it at each release.

## Revisit triggers

- Riverpod is unmaintained, or a new major version requires breaking changes in generated code
  across the template.
- The pinned Flutter SDK moves to a Dart version outside Riverpod's declared SDK constraint.
- A future milestone requires a state approach with mandatory code generation that Riverpod
  cannot provide without adding a build step.
