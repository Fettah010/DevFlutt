# ADR-007: logging, crash-reporting, and analytics adapters and their privacy defaults

- Status: Accepted
- Date: 2026-10-22
- Deciders: DevFlutt maintainers

## Context

v0.4.0 introduces the template's observability baseline: structured logging with redaction, and an
app-owned error-reporting interface. The roadmap requires:

- a `logging` module delivering "structured logs, severity, category/request context, debug-only
  verbosity, redaction helpers" with "secrets, tokens, passwords, auth headers, and sensitive
  payloads redacted by default" (§6.1);
- a `diagnostics` module delivering an "error capture interface, user-consented diagnostic sharing
  where relevant, crash-reporting adapter hooks", with "no provider SDK or outbound telemetry in
  blank preset" and a tested disabled/consent state (§6.1);
- clear separation of debug logs and production telemetry, and no printing of raw objects that may
  contain secrets (§8.1);
- minimization of collected and retained analytics and crash data, with analytics disabled unless
  explicitly configured (§8.1);
- redaction of authorization headers, refresh/access tokens, passwords, personally identifying
  payloads, and payment-related fields in logs (§8.1);
- logs and bug-report exports that are redacted and user-initiated when they contain diagnostic
  details (§8.4);
- the `logging` module to be part of the `core` preset, as "baseline logging interface" (§4.2),
  while `backend` and persistence remain selectable.

## Options considered

### For logging

1. **A bespoke app-owned logger** — a small `AppLogger` interface, a `LogRecord` value type, a
   `Redactor`, and a `ConsoleLogger` sink. No dependency.
2. **The `logging` package** — a widely used level-and-sink framework.
3. **`talker`** — a richer Dart logging library with observers, history, and pretty console output.

### For error reporting

1. **An app-owned `ErrorReporter` interface with a local adapter** — no provider SDK.
2. **A crash-reporting SDK (Sentry, Firebase Crashlytics)** — real crash visibility, but a native
   dependency, a data-egress path, and provider setup.
3. **An analytics SDK** — out of scope for this milestone entirely.

## Decision

Ship a **bespoke, dependency-free app-owned logger** and an **app-owned error-reporting interface
with a local adapter**. No crash-reporting or analytics provider SDK ships in v0.4.0.

**Logger.** `AppLogger` is the interface every module and feature uses. `LogLevel` orders
`debug`, `info`, `warning`, and `error`. A `LogRecord` carries the message, the level, a category
string, a timestamp, and a map of structured fields. `ConsoleLogger` is the default sink and
enforces the debug/release policy: in a development build the verbosity floor is `debug`; in a
staging or production build it is `info`, and `debug` records are dropped before they reach the
sink. `MemoryLogger` is a test sink that captures records for assertions.

**Redaction.** A `Redactor` is applied to every record *before* it reaches any sink, so a sink
cannot leak by omission. It replaces a value with `<redacted>` when the field key is a known
sensitive name (case-insensitive — `authorization`, `proxy-authorization`, `cookie`, `set-cookie`,
`password`, `secret`, `token`, `access_token`, `refresh_token`, `id_token`, `api_key`,
`client_secret`, `private_key`, `session`, `credit_card`, `card_number`, `cvv`, `pin`), when the
key name contains `authorization` or `credential`, or when the value itself looks like a JWT, a
bearer value, or a `Basic` credential. The redaction corpus is a committed fixture, so a new
sensitive shape is added by adding a case, and a regression is a failing test.

**Error reporting.** `ErrorReporter` is a single-method interface taking an `AppError` (severity,
message, cause, and context). `LocalErrorReporter` records errors in memory and never touches the
network. The `diagnostics` manifest declares `privacy.telemetry: false`.

**Privacy defaults.** `logging` and `diagnostics` add no dependency, no permission, and no outbound
traffic. Neither is enabled in `blank`. `logging` joins the `core` preset as the "baseline logging
interface"; `diagnostics` does not, because an error reporter without a consumer is speculative —
it is selected explicitly.

**Provider adapters are deferred.** A crash-reporting or analytics adapter is a separate, opt-in
module with its own manifest, its own native setup, and an explicit statement of the data it
collects. It never ships by default, and its presence is what makes the corresponding permission
and disclosure appear in a generated project.

## Evidence

- Roadmap §6.1 (`logging` and `diagnostics` module rows) and §4.2 (`core` preset contents),
  §8.1, §8.4 (checked 2026-10-22).
- Protocol §8.2: "No `print` in app code (use the logging interface)" and "Do not add telemetry,
  authentication, remote calls, scheduled work, or background services without explicit module
  selection and documentation" (checked 2026-10-22).
- The redaction key list is drawn from the OWASP MASVS storage and logging guidance named by
  roadmap §8.2, restricted to the shapes that actually appear in a mobile client (checked
  2026-10-22).
- The v0.3.0 configuration contract already refuses to repeat an invalid value in an error
  message, because configuration values can carry deployment details — the same reasoning is
  applied here to log records.

## Trade-offs

- Writing a logger means the template owns the sink format, the level policy, and the redaction
  implementation. That is a small amount of code, and it is code the template would have to wrap
  and configure anyway.
- A bespoke logger offers no observers, no history, and no pretty output. A project that wants
  those can implement `AppLogger` against its own sink without forking the module.
- Deferring the crash-reporting SDK means a generated project has no crash visibility until the
  developer selects an adapter. That is the intended trade: the alternative ships a data-egress
  path and a native dependency by default, which the roadmap forbids.
- The redaction list is a heuristic. A key that is not on the list and a value that does not match
  a known shape will be logged. This is why redaction happens before the sink and why the corpus is
  reviewed whenever a new field is introduced.

## Consequences

- The `logging` module owns `AppLogger`, `LogLevel`, `LogRecord`, `Redactor`, `ConsoleLogger`, and
  `MemoryLogger`; the `diagnostics` module owns `ErrorReporter`, `LocalErrorReporter`, and
  `AppError`.
- No third-party logging or crash dependency exists in any preset.
- The `core` preset gains the `logging` module. This changes preset contents and is recorded in
  `CHANGELOG.md` and `docs/UPGRADING.md`.
- `AppLogger` is the only sink; `print` does not appear in generated application code.
- A project that wants a crash-reporting provider adds a separate adapter module in a later
  milestone, and the provider's data collection is documented at that point.

## Revisit triggers

- A logging need appears that the bespoke implementation cannot serve — for example structured
  export to a file, log shipping, or a third-party APM integration — at which point the
  `AppLogger` interface may be kept while the sink changes.
- A crash-reporting provider becomes mandatory for the template's target audience, which would
  make "no provider SDK by default" the wrong default.
- The redaction corpus is shown to miss a sensitive shape in practice.
- The Dart team's `logging` package gains a capability the template would otherwise reimplement.
