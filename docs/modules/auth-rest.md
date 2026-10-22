# auth-rest

The authentication adapter for a custom REST backend. The endpoints and the payload shapes
are configuration, so the adapter works with any backend that speaks the contract.

## Capabilities

- `RestAuthConfig` - the endpoint paths and the payload field names.
- `defaultRestAuthConfig` - the placeholder configuration a new project starts with.
- `RestAuthPort` - the provider boundary. The adapter depends on it, never on the HTTP
  client.
- `RestAuthAdapter` - the provider-neutral behaviour over the port: the state machine, the
  persisted session, and the serialized token refresh.
- `DioRestAuthPort` - the real port. It talks through the `ApiClient` of the `networking`
  module.
- `FakeRestAuthPort` - a deterministic test double that never touches the network.
- `rest_session_codec.dart` - the encoding of a session for the store.

## Configuration

Everything about the backend is declared, so nothing is hard-coded to one backend:

| Setting | Meaning |
|---|---|
| `loginPath` | the sign-in request |
| `registerPath` | the registration request; `null` disables registration |
| `refreshPath` | the refresh request; `null` disables token refresh |
| `logoutPath` | the logout request; `null` means the logout is local only |
| `passwordResetPath` | the password-reset request; `null` disables password reset |
| `emailField`, `passwordField` | the request body field names |
| `accessTokenField`, `refreshTokenField`, `expiresInField` | the response body field names |
| `userField` | the name of the user object in the response body |
| `userIdField`, `userEmailField`, `userDisplayNameField` | the user object's field names |

The capabilities the adapter reports follow the configuration: without a `registerPath` the
adapter reports no registration capability, and without a `refreshPath` it reports no token
refresh capability. The module manifest declares what the adapter *can* do; the runtime
descriptor reports what this configuration *does*.

`lib/core/auth/rest/rest_auth_config.dart` is generated once, when the project is created,
and then belongs to the project. Replace the placeholder paths and field names with the
ones your backend uses.

## Session handling

The adapter owns the session and persists it through the `SecureSessionStore` of the
`auth-core` module, so the access token and the refresh token are kept in the platform's
secure storage and not in ordinary preferences.

- Restoring reads the stored session. A stored value that cannot be read is treated as no
  session and is discarded; it is never partially applied.
- An expired session with a refresh token is refreshed during the restore.
- An expired session without a refresh token is discarded.
- Signing out always clears the local session, even when the backend logout fails. A
  backend failure is reported afterwards.

## Token refresh

The refresh goes through the `TokenRefreshCoordinator` of the `auth-core` module, so
concurrent requests with an expired token cause exactly one refresh request. A refresh the
backend refuses signs the user out rather than being retried.

## Transport

The real port sends its requests through the `ApiClient` of the `networking` module, so the
existing timeouts, cancellation, request correlation, and log redaction apply to
authentication traffic too. A password is never sent in a query string, and a response body
is never logged.

## Requires

- `auth-core` - which brings `architecture-core`, `logging`, and `secure-storage`
- `networking`

## Setup

The module adds no dependency, no configuration key, and no permission. Fill in
`defaultRestAuthConfig` and build the adapter in `buildAppServices` in
`lib/app/app_services.dart`.

The backend owns authorization, account recovery, rate limiting, multi-factor
authentication, and session revocation. The client does not implement them and must not
imply them.

## Limits

- One-time-password sign-in is not supported: a custom backend would need an
  email-link or magic-link flow, and the template does not guess one.
- Social sign-in is not supported.
- The response body must carry the configured access token field. A body without one
  produces a `provider-failure` error rather than a half-built session.

## Removal behaviour

Remove the module. The `networking` and `secure-storage` modules are selected by other
modules as well and stay.

## Test plan

`test/unit/auth/rest_auth_contract_test.dart` runs the shared contract suite against the
adapter and adds the adapter-specific cases: restoring a stored session, discarding an
unreadable one, refreshing an expired one, a refresh the backend refuses, concurrent
refreshes causing one request, a failed refresh not being retried, the local logout
clearing the session, a backend logout failure still clearing it, and the capabilities
following the configuration.
