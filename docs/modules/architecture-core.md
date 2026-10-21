# architecture-core

App bootstrap, configuration contract, design tokens, theme, and test structure.

## Capabilities

- Single startup path (`main()` delegates to `bootstrap()`).
- Typed, validated configuration boundary (`AppConfig`) for `APP_NAME`, `APP_ENV`,
  `API_BASE_URL`, and `FEATURE_FLAGS`.
- Design tokens for spacing, radius, and motion (`AppSpacing`, `AppRadius`,
  `AppDurations`).
- Material 3 light/dark themes built from the tokens.
- Example home screen.
- Unit + widget test scaffolding.

## Setup

No provider setup is required. The module is the base scaffold of every generated project,
so it is always present.

## Configuration

```bash
flutter run --flavor dev --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=https://api.example.com
```

`APP_ENV` accepts `dev`, `staging`, or `prod`. The wire names match the Android product
flavors. Invalid values fail fast with an actionable message; the message never repeats the
offending value.

## Removal

Not applicable (modules are generation-time selections).

## Tests

- `test/unit/app_config_test.dart` — environment parsing and configuration validation.
- `test/widget/app_theme_test.dart` — theme brightness, semantic colours, and text scaling.
- `test/widget/home_page_test.dart` — home screen rendering and scaling.
- `test/widget/app_test.dart` — the application root renders the home screen.
