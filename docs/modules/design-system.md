# design-system

Reusable core widgets built on the Material 3 theme and the shared design tokens.

## Capabilities

- `AppPrimaryButton` and `AppSecondaryButton` for actions.
- `AppTextField` for labelled text input.
- `AppCard` for grouped content.
- `AppMessage` for inline status messages with four severities.
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

## Removal

Not applicable (modules are generation-time selections).

## Tests

- `test/widget/app_widgets_test.dart` — buttons, text field, card, message, and state views.
