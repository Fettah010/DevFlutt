# Architecture

## Overview

The DevFlutt reference app uses a **feature-first structure with lightweight layers**. The blank
preset is deliberately minimal; later milestones add state management, routing, and data layers
without forcing every small feature through excessive interfaces.

## Directory structure

```text
lib/
  main.dart                     # entry point
  app.dart                      # MaterialApp root
  core/
    config/app_config.dart      # typed, validated configuration boundary
    theme/app_theme.dart        # minimal light/dark theme tokens
  features/
    home/home_page.dart         # example screen
test/
  unit/                         # domain + config tests
  widget/                       # UI + theme tests
android/                        # Android platform project
tool/verify/                    # local quality gate scripts
docs/                           # plans, reports, ADRs, testing
```

## Dependency direction

```text
UI (presentation)  ──▶  application / state  ──▶  domain contracts  ◀──  data + platform adapters
```

The blank app has no application/state or data layers yet. When they are added:

- UI never calls raw HTTP clients, secure storage, or database APIs.
- Provider-specific SDKs stay behind adapter implementations.
- Features use app-owned models, errors, and results rather than provider SDK types.

## Layer responsibilities

| Layer | Responsibility | Introduced |
|-------|----------------|------------|
| `core/config` | Typed, validated startup configuration | v0.1.0 |
| `core/theme` | Design tokens and light/dark themes | v0.1.0 |
| `features/<feature>` | One self-contained feature (presentation/state/domain/data as needed) | v0.1.0 |
| `core/*` (future) | Errors, logging, result types, platform guards | v0.4.0+ |
| `core/widgets` | Reusable shared components | v0.8.0 |

## Conventions

- One feature folder per feature; no feature imports another feature's internals.
- Prefer `const` constructors and small files.
- No `print` in app code; use the logging interface once the logging module is selected.
- No ad-hoc global state; registrations flow through generated registries or documented
  integration points.

## Open decisions

These are resolved by ADRs in the milestone that needs them:

- `ADR-001` State management (Riverpod) — v0.3.0
- `ADR-003` Routing package and route-registration model — v0.3.0
- `ADR-004` HTTP client and error/retry model — v0.4.0

See [ADR-000-template.md](adr/ADR-000-template.md) for the ADR format.
