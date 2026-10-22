# auth-core

The provider-neutral authentication contract: the adapter interface, the session and state
models, the capability descriptor, the secure session store, the serialized token refresh,
and the router redirect helper.

## Capabilities

- `AuthAdapter` - the application's authentication contract. Features depend on it, never on
  the provider.
- `AuthSession` - the access token, the refresh token, the expiry, and the user.
- `AuthUser` - the provider-neutral user model.
- `AuthState` - `unknown`, `authenticated`, or `unauthenticated`, with the session and the
  reason.
- `AuthError` - a sealed `invalid-credentials`, `network`, `timeout`, `cancelled`,
  `session-expired`, `session-revoked`, `not-signed-in`, `unsupported-capability`,
  `provider-failure`, or `unknown` failure.
- `AuthCapability` - the capability identifiers, and `AuthCapabilities`, the immutable set
  an adapter reports.
- `SessionStore` - where a session is persisted, and `SecureSessionStore`, the
  implementation backed by the secure store.
- `TokenRefreshCoordinator` - the single-flight refresh.
- `authRouteRedirect` - the router redirect helper.
- `FakeAuthAdapter` - a deterministic test double, so an application can test its own
  features without a provider.

## The contract

`AuthAdapter` exposes the capabilities, the current state, the state stream, session
restoration, email and password sign-in, registration, password reset, one-time-password
sign-in, sign-out, and refresh.

An operation that fails throws a typed `AuthError`. The error type is sealed, so a caller
can handle every failure case exhaustively. A failure whose `isRetryable` is false - a
rejected credential in particular - must not be retried by the caller.

No provider SDK type appears in a signature. Changing the provider never changes a feature.

## Token refresh

`TokenRefreshCoordinator` holds at most one in-flight refresh. The first caller starts the
refresh and every later caller awaits the same future, so a burst of requests with an
expired token produces exactly one refresh request rather than one per request.

A refresh that fails calls `onFailure` exactly once - the adapter signs the user out - and
rejects every waiting caller. The coordinator never re-arms itself and holds no timer, so
it cannot loop.

The Firebase and Supabase adapters do not use the coordinator: those providers refresh
inside their own SDK. The `auth-rest` adapter does, because it talks to an arbitrary
backend and owns its refresh.

## Router integration

`authRouteRedirect` is a pure function. Given the current state, the requested location,
and the login location, it returns the location to navigate to, or `null` to allow the
navigation.

- An unauthenticated user is sent to the login location with the intended destination
  preserved in the `redirect` query parameter, so a protected deep link returns the user
  to where they were going after they sign in.
- A navigation that is already the login location is left alone, so the redirect cannot
  loop.
- The `unknown` state is allowed through. The session has not been established yet, and
  redirecting would bounce the user to the login screen before the template has had a
  chance to restore the session. The application must not show protected content in that
  state, which is why the template restores the session before the first frame.

The template ships no login screen: the login route belongs to the application. The
`authRouteGuard` helper in the navigation module turns the adapter and the login location
into a `RouteRedirect`. See `docs/modules/navigation.md`.

## Requires

- `architecture-core`
- `logging`
- `secure-storage`

## Setup

The module adds no configuration key and no permission. The session is stored through the
secure store of the `secure-storage` module, so the Android backup rules that exclude it
are generated with that module.

Select one adapter - `auth-rest`, `auth-firebase`, or `auth-supabase` - to add a provider.
The module alone gives an application the contract but no provider.

## Limits

- The module provides no login screen and no authentication form. The form and its states
  belong to the polished-UI milestone; see `docs/DEFERRED.md`.
- Social sign-in is not implemented by any adapter in this release. The capability
  descriptor reports it unsupported, and calling it raises
  `AuthError.unsupportedCapability`.
- Multi-factor authentication, phone sign-in, and anonymous sign-in are not in the
  contract.

## Removal behaviour

Remove the adapter module. The contract files are only referenced by the adapter and by
the application, so removing the adapter leaves the contract in place for the application's
own use.

## Test plan

`test/unit/auth/auth_core_test.dart` covers the capability set, the error taxonomy, the
session expiry rules, the session store, the refresh coordinator's single-flight and
failure behaviour, and the router redirect including the loop guard.
