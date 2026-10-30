# localization

Optional Flutter `gen-l10n` scaffolding with English and Arabic sample resources.

## Capabilities

- `flutter_localizations` from the Flutter SDK and hosted `intl` for locale-aware formatting.
- English and Arabic ARB files and an `l10n.yaml` configuration.
- Generated `AppLocalizations` delegates and supported locales.
- `AppFormatters` helpers for locale-aware number, currency, and date display.

## Setup

Select `--module localization`, then resolve packages and generate the localization API:

```sh
flutter pub get
flutter gen-l10n
flutter analyze --fatal-infos
flutter test
```

When the app uses localized formatting, `AppFormatters.initialize()` is called during
startup to initialize date symbols. Add translations to each shipped ARB locale and keep
the message keys aligned. Use Flutter's `Directionality` and directional layout APIs;
do not manually reverse rows for Arabic.

## Boundaries

- English and Arabic are examples, not a promise of a complete translation catalogue.
- The generated app has a fixed locale list; runtime locale switching is not provided.
- Formatting helpers require an explicit locale and currency code where relevant.
- Generated localization code is produced by `flutter gen-l10n` and is not committed as
  brick output.
- The blank preset has no localization files, dependency, or imports unless selected.

## Tests

Generated localization tests cover English LTR, Arabic RTL, mixed Arabic/Latin text,
small-screen and scaled-text layout, list-item direction, and deterministic number,
currency, and date formatting.
