# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-10-19

### Added

- Bundled generator `ftemplate` (Dart CLI) using Mason bricks.
- Commands: `create`, `list-modules`, `explain-module`, `validate`, `version`.
- `create` supports `--name`, `--org`, `--preset`, `--output`, `--platforms`,
  `--module`, `--brick-dir`, `--dry-run`, `--force`, `--no-pub`.
- Versioned module-manifest schema (`manifests/schema/module.schema.json`) with a
  validator.
- Module manifests for `architecture-core`, `state-riverpod`, `navigation`.
- `blank` and `core` presets.
- `project` Mason brick that scaffolds blank and core projects.
- Mason generation engine with temp-dir output, safe-overwrite protection, and a
  `.devflutt.yaml` origin marker.
- Generated-project CI matrix (blank, core) that resolves, analyzes, tests, and
  builds each generated project.
- `docs/MODULES.md`, `docs/COMPATIBILITY.md`, and per-module READMEs.

### Changed

- Root `analysis_options.yaml` now excludes `tool/**` and `bricks/**` (separate
  packages/templates).

[Unreleased]: https://github.com/Fettah010/DevFlutt/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/Fettah010/DevFlutt/releases/tag/v0.2.0
