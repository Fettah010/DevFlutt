# logging

Structured, redacted logging with severity, category context, and a debug/release
verbosity policy.

## Capabilities

- `AppLogger` — the application's logging interface. Generated code never calls `print`.
- `LogLevel` — `debug`, `info`, `warning`, `error`, ordered by severity.
- `LogRecord` — a message, a level, a category, a timestamp, structured fields, and the
  redacted error text and stack trace.
- `Redactor` — applied by the logger **before** a record is created, so a sink cannot leak
  a sensitive value by omission.
- `ConsoleLogger` — the default sink; writes through `dart:developer`, so the records reach
  the platform log and the DevTools console.
- `MemoryLogger` — a test sink that keeps the records it received.

## Redaction

A value is replaced with `<redacted>` when:

- the field key is a known sensitive name (`authorization`, `proxy-authorization`, `cookie`,
  `set-cookie`, `password`, `passwd`, `secret`, `token`, `access_token`, `refresh_token`,
  `id_token`, `api_key`, `apikey`, `client_secret`, `private_key`, `session`, `credit_card`,
  `card_number`, `cvv`, `cvc`, `pin`), matched case-insensitively;
- the field key contains `authorization` or `credential`;
- the value looks like a JWT, a `Bearer`/`Basic` credential, or an opaque token of 32
  characters or more that mixes letters and digits.

The list is a heuristic. A field that is neither on the list nor shaped like a credential is
logged, so a new sensitive shape must be added to the corpus in `logging_test.dart` and to
`Redactor.defaultSensitiveKeys`.

## Verbosity policy

The composition root picks the floor from the runtime environment:

| Environment | Lowest level logged |
| --- | --- |
| `dev` | `debug` |
| `staging` | `info` |
| `prod` | `warning` |

## Requires

- `architecture-core`

## Setup

None. `buildAppServices(config)` creates the logger with the environment's floor. Replace
`ConsoleLogger.writeLine` to route the records somewhere else.

## Limits

- The logger has no observers, no history, and no file output. A project that needs those
  implements the sink itself.
- The redaction is name- and shape-based, not content-based.

## Removal

Not applicable (modules are generation-time selections). Removing the module removes the
logger, the `AppServices.logger` field, and the logging calls.

## Tests

- Every sensitive field in the redaction corpus is redacted, and every safe field survives.
- A record is redacted before it reaches the sink.
- An error is recorded as redacted text, never as the original object.
- Records below the minimum level are dropped.
- The console sink writes a redacted line.
