# supabase-core

Shared Supabase project configuration and one-time client initialization for selected
Supabase modules. It is pulled in automatically by `auth-supabase` and
`backend-supabase`; it does not select either capability by itself.

## Capabilities

- Owns the project URL, publishable key, and shared Supabase initializer.
- Initializes one Supabase client for all selected Supabase modules.
- Uses `EmptyLocalStorage` when Supabase Auth is absent; the data-only client does not
  persist an unused session.
- Declares the `INTERNET` permission because it communicates with the configured project.

## Setup

1. Create a Supabase project.
2. Set its project URL and publishable key in
   `lib/core/supabase/supabase_config.dart` in the generated project.
3. Enable and test Postgres row-level security policies and least-privilege grants for every
   table the app accesses.
4. If `auth-supabase` is also selected, configure the provider's allowed redirect URLs.

The publishable key is public client configuration. Never include a service-role key in the
app. The inert placeholders are rejected during initialization with setup guidance.

## Platform and privacy limits

The manifest supports Android and iOS, but the v0.9.1 generated-project matrix verifies
Android only. This core does not add Auth, Storage, Realtime, Edge Functions, or Analytics.
It makes network requests when selected; it does not provide authorization or enable row
security. Those are server-side responsibilities. Live Supabase configuration and service
behavior require an owner-provided project and are not established by fake-backed tests.

When Supabase Auth is selected, startup supplies the template's secure-storage-backed
session persistence instead of the SDK's ordinary preferences default. Data-only projects
use non-persistent storage. `supabase_flutter` may still bring `shared_preferences`
transitively.

## Removal behavior

Remove every selected Supabase auth/data module. The generator then omits this core, its
configuration and initializer, `supabase_flutter`, and its network permission; it remains
only when another selected Supabase module requires it.

## Test plan

Generator tests verify selected-only files and one shared initializer for Supabase Auth +
Postgres/PostgREST. Generated data-only and Auth + data projects are tested and built, and
the matching composition is included in the generated-project CI matrix.
