# showcase

Component showcase page that demonstrates the design system and the theme.

## Capabilities

- One screen that renders every shared widget: message, buttons, text field, and the
  loading, empty, and error states.
- Route registration at `/showcase` through `AppRoutes`.

## Requires

- `architecture-core`
- `state-riverpod`
- `navigation`
- `design-system`

## Setup

No setup is required. The page is reachable from the router at `/showcase`.

## Purpose

The showcase exists to review the look and feel of the design system in one place. It is
not part of the `core` preset; it ships with the `demo` preset. Remove the module and the
route when the project no longer needs it.

## Removal

Not applicable (modules are generation-time selections).

## Tests

- `test/widget/showcase_page_test.dart` — the shared components render and react.
