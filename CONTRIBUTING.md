# Contributing

## Local setup

1. Install [Flutter](https://docs.flutter.dev/install) (pinned: `>=3.47.0 <3.48.0`).
2. Run `flutter pub get` in the project root.
3. Run `flutter test` to verify your environment.

## Code style

- Dart code is formatted with `dart format` (line length 100).
- Static analysis uses `flutter_lints` with warnings as errors.
- No `print` statements in app code — use the logging interface (when the logging module is selected).

## Branch conventions

- `main` — stable, release-ready code.
- `work/<version>` — development branches for milestone work.
- Feature branches: `work/<version>-<short-description>`.

## Pull requests

- One milestone or slice per PR.
- CI must be green before merge.
- Describe what changed, why, and how it was verified.

## Tests

- Unit tests for domain rules and configuration.
- Widget tests for UI components and theming.
- All tests must pass locally and in CI before merge.

## Commit messages

Conventional Commits: `type(scope): summary`. Examples:

- `feat(theme): add dark mode support`
- `fix(config): handle missing environment variable`
- `ci: pin Flutter version in workflow`
