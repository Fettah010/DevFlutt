# design-system

Reusable core widgets built on the Material 3 theme and the shared design tokens.

## Capabilities

- `AppPrimaryButton` and `AppSecondaryButton` for actions.
- `AppPrimaryButton` supports an optional `FocusNode` for explicit focus handling.
- `AppTextField` for labelled text input.
- `AppCard` for grouped content.
- `AppMessage` for inline status messages with four severities; an offline banner,
  direction-aware list row, confirmation dialog, and keyboard-aware bottom sheet.
- `AppLoadingView`, `AppEmptyView`, and `AppErrorView` for the three asynchronous states.

## Requires

- `architecture-core`

## Setup

No setup is required. The widgets read the spacing, radius, and motion tokens from
`core/theme/app_tokens.dart` and the colours from the application theme. They never
introduce a second theme source.

## Conventions

- A widget in this module has one job. Compose rather than add options.
- Every widget exposes a `key` parameter and a `const` constructor.
- Colours come from `Theme.of(context)`, never from a hard-coded literal.
- Prefer semantic labels and framework focus traversal; test representative controls at
  Android tap-target size and with the Flutter label and contrast guidelines.

## Removal

Not applicable (modules are generation-time selections).

## Tests

- `test/widget/app_widgets_test.dart` — component behavior, semantics, Android tap targets,
  labels, text contrast, and keyboard focus order. These automated checks do not replace
  TalkBack and device review; see `docs/ACCESSIBILITY_CHECKLIST.md`.
