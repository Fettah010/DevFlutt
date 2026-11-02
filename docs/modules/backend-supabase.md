# backend-supabase

A provider-specific client for Supabase Postgres through PostgREST. It does not expose a
universal database API or select Supabase Auth.

## Capabilities

- `SupabaseDataClient` - selects filtered rows with an explicit positive limit, inserts one
  row, and deletes rows matching required equality filters.
- `SupabaseTableRow` - a decoded row represented by `Map<String, Object?>` fields.
- `SupabaseDataResult<T>` - a typed success/failure outcome; provider error text is not retained.
- `SupabaseDataPort` - the provider boundary used by the client.
- `SupabaseDataPortImpl` - the real `supabase_flutter` PostgREST implementation.
- `FakeSupabaseDataPort` - a deterministic in-memory test double that makes no network requests.

This deliberately narrow module does not provide updates, SQL queries, RPC, transactions,
pagination, realtime subscriptions, schema validation, or offline synchronization. Add those
capabilities only through a separately scoped provider-specific contract.

## Setup

1. Create a Supabase project and configure its URL and publishable key in
   `lib/core/supabase/supabase_config.dart`.
2. The shared `supabase-core` module initializes the SDK once. Its default local storage is
   non-persistent; selecting Supabase Auth separately supplies secure session storage.
3. Enable and test Postgres row-level security policies and grants for every exposed table.
   The data module neither enables policies nor selects an authentication provider.
4. Inject `AppServices.supabaseDataClient` into the feature that needs it.

The client maps known Postgres permission, authentication, and connection error codes to safe
typed categories. Unknown failures map to `unknown`; raw provider messages and table data are
not included in error values. Malformed row payloads return `malformedData`.

## Security and limits

The publishable key is public client configuration, not a secret. Never put a Supabase
service-role key in the application. Enable row-level security and define least-privilege
policies and grants on the server for every exposed table; a client-side filter is not
authorization. Review deployed policies and database behavior before release.

Supabase Auth remains optional and independent. This module does not bridge credentials from
another identity provider or persist sessions. It does not promise provider uptime, query
performance, live-service behavior, or offline data synchronization. Unit tests use the fake
port and make no network requests.

This milestone targets Android. iOS generation, build, and runtime behavior have not been
verified.

## Tests

Generated tests cover filtered and bounded reads, row insertion, filtered deletion, malformed
payloads, invalid requests, and safe typed error mapping.
