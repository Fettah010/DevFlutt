# Modules

Modules are the selectable building blocks of a generated project. Each module has a
manifest under `manifests/modules/`, a set of brick templates, and a README under
`docs/modules/`.

## Available modules

| Module | Category | Requires | Conflicts with | Adds |
|---|---|---|---|---|
| `architecture-core` | core | — | — | App bootstrap, config boundary, theme tokens, test structure |
| `state-riverpod` | state | `architecture-core` | — | `flutter_riverpod`, provider scope, app state |
| `navigation` | routing | `architecture-core`, `state-riverpod` | — | `go_router`, declarative routes, deep links |

## Presets

| Preset | Modules |
|---|---|
| `blank` | none |
| `core` | `architecture-core`, `state-riverpod`, `navigation` |

## Adding modules

```bash
ftemplate create --name MyApp --org com.example --preset blank --module state-riverpod
```

## Module manifest

See `manifests/schema/module.schema.json` for the contract. Every manifest is
validated by `ftemplate validate --manifest <file>` before any files are written.

## Removal

Modules are generation-time selections. Removing a module from the command line
means its files, dependencies, and registrations are never written. There is no
runtime removal path for already-generated projects.
