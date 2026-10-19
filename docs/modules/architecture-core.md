# architecture-core

App bootstrap, configuration contract, theme tokens, and test structure.

## Capabilities

- Typed, validated configuration boundary (`AppConfig`).
- Minimal light/dark Material 3 theme.
- Example home screen.
- Unit + widget test scaffolding.

## Setup

No provider setup is required.

## Removal

Not applicable at v0.2.0 (modules are generation-time selections).

## Tests

- `test/unit/app_config_test.dart` — environment parsing and validation.
- `test/widget/app_theme_test.dart` — theme brightness and application.
- `test/widget/home_page_test.dart` — home screen rendering and scaling.
