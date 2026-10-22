# auth-supabase

The authentication adapter for Supabase Auth.

## Capabilities

- `SupabaseConfig` - the project URL and the publishable key, and
  `defaultSupabaseConfig`, the placeholder a new project starts with.
- `SupabaseAuthPort` - the provider boundary. The adapter depends on it, never on the
  Supabase SDK.
- `SupabaseAuthAdapter` - the provider-neutral behaviour over the port.
- `SupabaseAuthPortImpl` - the real port. It is the only file in the module that imports
  `supabase_flutter`.
- `FakeSupabaseAuthPort` - a deterministic test double that never touches Supabase.
- `SecureStorageLocalStorage` - keeps the session in the secure store.
- `initializeSupabaseAuth` - prepares Supabase at start-up.

## Setup

1. Create a Supabase project.
2. In the generated project, replace the values in
   `lib/core/auth/supabase/supabase_config.dart` with the project URL and the publishable
   key from the project's API settings.

The publishable key is a **public** identifier, not a secret: it is the key every Supabase
client ships with. The service-role key is a secret and must never appear in an
application. The shipped placeholder is inert, and the application refuses to start with a
message that names the file to edit.

The module adds no permission and no configuration key.

## Session persistence

The `supabase_flutter` package persists the session in `shared_preferences` by default. The
session carries the access token **and** the refresh token, so writing it to an
unencrypted preferences file would leave a long-lived credential on the device in the
clear, and Android's Auto Backup would include that file.

This module therefore supplies its own `LocalStorage`, backed by the template's secure
store, through the package's documented `FlutterAuthClientOptions(localStorage:)` hook. The
package's `shared_preferences` default is not used, and the Android backup rules that the
`secure-storage` module generates keep the session out of backups.

`supabase_flutter` still brings `shared_preferences` as a transitive dependency. That is a
consequence of the package's structure, not a choice, and it is recorded here rather than
hidden.

## Session handling

Supabase keeps the session itself, so the adapter does not persist one. `restoreSession`
asks the provider whether a session exists and reads the current access token. Supabase
refreshes the token inside its SDK, so the adapter asks for a fresh one when the
application needs it.

## One-time-password sign-in

The adapter supports Supabase's one-time password flow, which covers the magic link and
the password-reset link. The token is the whole link, and the adapter reads the
`token_hash` and the `type` from its query string. A link without a token hash is rejected
with a `provider-failure` error.

The link must reach the application as a deep link, and the redirect must be allowed in the
Supabase dashboard. The template does not add a deep link: the scheme is the application's
choice, and the module documents what to configure.

## Requires

- `auth-core` - which brings `architecture-core`, `logging`, and `secure-storage`

## Setup

Fill in `defaultSupabaseConfig`, then build the adapter in `buildAppServices` in
`lib/app/app_services.dart`.

Supabase owns the password policy, multi-factor authentication, account recovery, and
session revocation. The client does not implement them and must not imply them.

## Limits

- Social sign-in is not implemented in this release. Every social provider needs
  provider-console setup and platform configuration that the template cannot exercise or
  verify.
- The live flow is not verified by the template's tests: no Supabase project is available
  here. The tests are contract tests against a fake, which prove the contract, not the
  provider. See owner action OA-7 in the release report.
- iOS is unverified: no macOS host or runner is available.

## Removal behaviour

Remove the module. The `supabase_flutter` dependency goes with it. The `secure-storage`
module stays, because other modules select it too.

## Test plan

`test/unit/auth/supabase_auth_contract_test.dart` runs the shared contract suite against
the adapter and adds the adapter-specific cases: restoring a session the provider already
has, restoring no session, a forced refresh asking the provider for a new token, a one-time
link signing the user in, a one-time link without a token hash being rejected, and a
password reset reaching the provider.
