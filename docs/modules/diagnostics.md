# diagnostics

App-owned error reporting with a local adapter. Crash-reporting and analytics providers stay
optional and separately selectable.

## Capabilities

- `ErrorReporter` — a single-method interface the application owns.
- `AppError` — a message, a severity, structured context, and the underlying cause.
- `LocalErrorReporter` — keeps the reported errors in memory and logs a redacted copy. It
  never touches the network.

## Privacy defaults

- The module adds no dependency, no permission, and no outbound traffic.
- The manifest declares `privacy.telemetry: false`.
- The local adapter keeps at most 50 errors in memory; older ones are dropped.
- A future adapter — a crash reporter, or a user-initiated diagnostics export — is a
  separate module that is never selected by default. It must state the data it collects.

## Requires

- `architecture-core`
- `logging`

## Setup

None. `buildAppServices(config)` creates the reporter. A feature that wants to report an
error receives an `ErrorReporter` through its constructor.

## Limits

- The local adapter keeps the errors only for the lifetime of the process. It is a
  development and debugging aid, not a crash-reporting service.
- The stored `AppError` keeps the original message and cause. The copy that reaches a log
  sink is redacted; the in-memory copy is not. An export adapter must redact before it
  leaves the device.

## Removal

Not applicable (modules are generation-time selections). Removing the module removes the
reporter and the `AppServices.errorReporter` field.

## Tests

- A reported error is kept, with its severity and context.
- The oldest error is dropped when the limit is reached.
- The logger receives a redacted copy of the error.
- The recorded errors can be cleared.
