# Modules

Modules are the selectable building blocks of a generated project. Each module has a
manifest under `manifests/modules/`, a set of brick templates, and a README under
`docs/modules/`.

## Available modules

| Module | Category | Requires | Conflicts with | Adds |
|---|---|---|---|---|
| `architecture-core` | core | — | — | Bootstrap, config boundary, design tokens, theme, test structure |
| `state-riverpod` | state | `architecture-core` | — | `flutter_riverpod`, provider scope, shared app state |
| `navigation` | routing | `architecture-core`, `state-riverpod` | — | `go_router`, route registry, redirect hook, unknown-route screen |
| `design-system` | ui | `architecture-core` | — | Reusable buttons, text field, card, message, and state views |
| `feature-example` | feature | `architecture-core`, `state-riverpod`, `navigation` | — | Counter feature across domain, data, application, and presentation |
| `showcase` | feature | `architecture-core`, `state-riverpod`, `navigation`, `design-system` | — | Component showcase page |
| `logging` | diagnostics | `architecture-core` | — | `AppLogger`, `LogRecord`, `Redactor`, console and memory sinks |
| `networking` | networking | `architecture-core`, `logging` | — | `dio`, typed `ApiClient`, error mapping, bounded retry, a fake adapter |
| `secure-storage` | persistence | `architecture-core` | — | `flutter_secure_storage`, `SecureStore`, the Android backup exclusion |
| `diagnostics` | diagnostics | `architecture-core`, `logging` | - | `ErrorReporter` interface and a local, in-memory adapter |
| `auth-core` | auth | `architecture-core`, `logging`, `secure-storage` | - | `AuthAdapter`, `AuthSession`, `AuthState`, `AuthError`, the capability descriptor, the session store, the token-refresh coordinator, the router redirect |
| `auth-rest` | auth | `auth-core`, `networking` | `auth-firebase`, `auth-supabase` | A custom REST/JWT adapter with configurable endpoints and payload shapes |
| `auth-firebase` | auth | `auth-core` | `auth-rest`, `auth-supabase` | `firebase_auth`, `firebase_core`, an inert `firebase_options.dart` |
| `auth-supabase` | auth | `auth-core` | `auth-rest`, `auth-firebase` | `supabase_flutter`, a secure-storage-backed session |

## Presets

| Preset | Modules |
|---|---|
| `blank` | `architecture-core` |
| `core` | `architecture-core`, `state-riverpod`, `navigation`, `design-system`, `feature-example`, `logging` |
| `demo` | `core` plus `showcase` |
| `recommended` | `core` plus `diagnostics`, `networking`, `secure-storage` |

`architecture-core` is the base scaffold of every generated project, so `blank` is the
architecture without any optional module. `core` is the recommended starting point for a
product. `demo` adds a showcase page that renders every shared widget; it exists to review
the design system and is not part of `core`. `recommended` is a typical networked
foundation: the core architecture plus the HTTP, diagnostic, and secure-storage plumbing.

`recommended` is narrower than the road map's v1.0.0 description of it: the localisation
scaffold and the application-lifecycle hooks join that preset in their own milestones
(v0.9.0 and v0.8.0). The preset file is the explicit, versioned module list, so what the
preset contains is never a hidden bundle.

No preset selects an authentication provider. The road map says the provider "is chosen
explicitly rather than guessed", so a project asks for one with `--auth`:

```bash
ftemplate create --name MyApp --org com.example --preset recommended --auth firebase
```

The three adapters are mutually exclusive. The generator refuses a selection of two with an
actionable message, before anything is written.

## Authentication capabilities

Every adapter declares the capabilities it implements, in its manifest and at runtime. The
generator refuses a selection whose provider cannot satisfy a capability the project
declared:

```bash
ftemplate create --name MyApp --org com.example --preset core --auth rest \
  --auth-capability one-time-password-sign-in
```

That selection fails, and the message names the providers that do support the capability.
See `docs/adr/ADR-006-auth-and-backend-adapters.md`.

## Adding modules

```bash
ftemplate create --name MyApp --org com.example --preset blank --module state-riverpod
```

Modules that depend on other modules pull them in automatically: asking for
`--module feature-example` also installs `architecture-core`, `state-riverpod`, and
`navigation`.

## Module manifest

See `manifests/schema/module.schema.json` for the contract. Every manifest is
validated by `ftemplate validate --manifest <file>` before any files are written.

The `outputs` list is the contract between a module and the generator: it names every file
the module contributes to a generated project.

## Removal

Modules are generation-time selections. Removing a module from the command line
means its files, dependencies, and registrations are never written. There is no
runtime removal path for already-generated projects.
