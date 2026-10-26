# Local database module

Select with `ftemplate create --name MyApp --org com.example --module local-database`.

The module provides a Drift/SQLite `AppDatabase`, a committed generated query source, schema
version 2, an upgrade from version 1, file-backed defaults, and an in-memory constructor.
Version 1's local document rows are preserved while version 2 adds the pending-operation
table. Database changes require updating the migration and running
`dart run build_runner build`; commit the generated source with the schema.

The database is unencrypted. Do not store credentials, tokens, or payment data in its rows.
The module adds `drift` and `drift_flutter` at runtime plus `drift_dev` and `build_runner` as
development dependencies. The migration suite verifies upgrade, reopen, retained data, and
in-memory use.
