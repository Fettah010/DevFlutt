# ADR-006: Auth and backend adapters, capability descriptors, and token-refresh serialization

- Status: Accepted
- Date: 2026-10-22
- Deciders: DevFlutt maintainers

## Context

v0.5.0 introduces the template's identity layer. The milestone's outcome is that a developer can
choose a supported identity approach **without changing the app's feature-facing contracts**, so the
provider an app uses is a generation-time choice, not an architectural one.

The roadmap requires, explicitly:

- a provider-neutral auth contract and a tested auth state model (§6.2);
- a `auth-rest` adapter, plus Firebase Auth and Supabase Auth adapters as **independently
  selected modules**, added only after verifying current APIs, native setup, licences, and
  maintenance (§6.2, and the `v0.5.0` Implement list);
- session restoration, secure persistence, token refresh where applicable, logout, error mapping,
  and router integration (§6.2, `v0.5.0` Implement list);
- **capability descriptors** and explicit generator errors where providers differ (§6.2 and the
  `v0.5.0` Implement list);
- the rule that "backend selection is not always identical to auth selection … the generator must
  represent these decisions clearly instead of using one overloaded `backend` flag" (§6.3);
- concurrency-safe token refresh: concurrent expired-token requests must not start many refresh
  requests or retry in a loop, and logout behaviour on a failed refresh must be defined (§5.4);
- no provider SDK types in feature code, and no secrets outside secure storage (§8.1, §8.2);
- provider configuration guides and safe placeholder configuration files, with **no real keys or
  credentials** (§6.2, `v0.5.0` Implement list).

ADR-004 already fixed the transport and reserved the shape of the refresh seam: "refresh lives
behind a single `TokenRefresher` seam; concurrent callers that observe an expired token share **one**
in-flight refresh; a failed refresh signs the session out rather than retrying". This ADR decides
how that seam is realised and how the providers differ from one another.

## Options considered

### The contract shape

1. **One interface plus typed errors** — `AuthAdapter`, an immutable `AuthSession`, a sealed
   `AuthError`, an `AuthState` value, and an `AuthCapabilities` descriptor.
2. **A `Result`-style free-function API** — every operation returns a result pair instead of
   belonging to an object.
3. **Expose the provider SDK types directly** — the feature code calls `FirebaseAuth.instance` or
   `Supabase.instance.client` and the template wraps nothing.

### The provider set

1. **All three adapters in v0.5.0** — `auth-rest`, `auth-firebase`, `auth-supabase`.
2. **`auth-rest` only** — the custom backend first, the hosted providers later.
3. **`auth-rest` and `auth-firebase`** — one hosted provider, deferring Supabase.

### How the generator expresses the choice

1. **One overloaded `--backend` flag** — `none`, `rest`, `firebase`, `supabase`.
2. **A separate `--auth` flag**, with the `--backend` name reserved for the data-backend adapters.
3. **Module selection only** — no dedicated flag; `--module auth-firebase` is the only way in.

## Decision

### The contract

Use **option 1**: a single `AuthAdapter` interface with typed errors, mirroring the `ApiClient` /
`ApiError` / `ApiResult` trio that v0.4.0 established and tested. Option 3 is excluded by the
roadmap — a contract whose types come from the provider is not provider-neutral, and it is the
exact failure this milestone exists to prevent. Option 2 has nowhere to hang the session
lifecycle, the capability descriptor, or the auth-state stream, and it would not let an app hold
one object that owns the session.

`AuthAdapter` exposes the capabilities, the current state, the state stream, session
restoration, email/password sign-in, optional registration, password reset, sign-out, and refresh.
`AuthError` is sealed: `invalidCredentials`, `network`, `timeout`, `cancelled`, `sessionExpired`,
`sessionRevoked`, `notSignedIn`, `unsupportedCapability`, `providerFailure`, `unknown`. Provider
exception types never escape an adapter.

`auth-core` does **not** depend on Riverpod. The contract is plain Dart, and the app wraps
`AuthController` in whatever provider it already uses. The template ships one recommended
architecture, and adding a second state-management surface inside a contract module would
contradict that.

### The provider set

Use **option 1**: all three adapters ship in v0.5.0, as three independently selected modules
that the existing compatibility graph makes mutually exclusive. The `v0.5.0` exit criteria say
"each adapter passes contract tests for implemented capabilities" — plural — so shipping one
would leave the milestone's own criteria unmet.

### Capability descriptors and the generator error

Each adapter declares its capabilities, at runtime on `AuthAdapter.capabilities` and in its
module manifest. The capabilities differ in ways that are real and not hypothetical:

| Capability | `auth-rest` | `auth-firebase` | `auth-supabase` |
|---|---|---|---|
| email/password sign-in | yes | yes | yes |
| email/password registration | yes | yes | yes |
| password reset | yes | yes | yes |
| session restoration | yes | yes | yes |
| token refresh | yes (the template's) | yes (the SDK's) | yes (the SDK's) |
| logout | yes | yes | yes |
| one-time-password sign-in | **no** | yes | yes |
| social sign-in | no | no | no |

Social sign-in is **not shipped for any adapter in this release**: every social provider needs
provider-console setup and platform configuration that cannot be exercised or verified here, and
the roadmap makes social sign-in an opt-in subfeature for exactly that reason. The descriptor
reports it unsupported, and the runtime raises `AuthError.unsupportedCapability` rather than
failing obscurely.

The generator expresses a requirement with a new `--auth-capability` option, repeatable, naming a
capability the app needs. When the selected adapter cannot provide it, the generator **fails**
before writing anything, and the message names the adapter, the capability, and the adapters
that do provide it. The generation summary lists the selected adapter and its capabilities.
This is the "generator should communicate missing capabilities, not pretend every adapter is
identical" rule of §6.2, made executable.

### Auth versus backend

Use **option 2**. The `--backend` flag has never shipped — the v0.4.0 command line has no such
flag — so `--auth` is new surface rather than a break, and the two decisions are recorded
separately. The `v0.5.0` Implement list contains no data-backend adapter: Firestore, Postgres,
Storage, Realtime, and Edge Functions are not in scope, so a `--backend` flag with nothing behind
it would be a hollow contract. ADR-006 **reserves the name** so that the milestone that adds
those adapters introduces `--backend` without overloading `--auth`.

Module selection remains available: `--auth firebase` is a convenient way to select the
`auth-firebase` module, and `--module auth-firebase` stays valid and composable with it.

### Token-refresh serialization

ADR-004 reserved the seam. This ADR realises it as a `TokenRefreshCoordinator` in `auth-core`:
at most one in-flight refresh future exists; the first caller starts the refresh and every later
caller awaits the same future; a successful refresh completes every waiter with the new session; a
failed refresh signs the user out exactly once and rejects every waiter. There is no timer, no
retry, and no re-arm, so the coordinator cannot loop.

`auth-rest` uses the coordinator, because it talks to an arbitrary backend and owns its refresh.
Firebase and Supabase refresh inside their own SDKs, so the coordinator is not wrapped around
them; the adapter documentation says so, and the contract suite asserts the observable
behaviour — a refreshed session and a single sign-out — rather than the mechanism.

### Provider configuration

The template ships **inert placeholders**, not provider configuration. `flutterfire configure`
writes `lib/firebase_options.dart`, and the official FlutterFire documentation states that the
configuration file "contains unique, but non-secret identifiers"; the Flutter path does not need
`google-services.json` or the `com.google.gms.google-services` Gradle plugin, which belong to the
native Android SDK. Supabase needs a project URL and a publishable key, and a redirect
allow-list that only the developer can set. Committing provider-shaped files that the provider's
own tooling immediately overwrites would be noise; committing real identifiers would be a secret
in Git.

The generated code therefore detects an unconfigured placeholder and **fails fast with an
actionable message** naming the exact command to run, rather than letting the app fail obscurely
later.

### Supabase session persistence

`supabase_flutter` persists the session with `SharedPreferencesLocalStorage` by default. The
session carries the access token **and** the refresh token, and it would land in an unencrypted
preferences file that Android Auto Backup includes by default — which contradicts §8.1
("secure storage for selected session credentials") and would defeat the Android backup rules
that the `secure-storage` module already generates.

The package documents a `LocalStorage` interface and a `FlutterAuthClientOptions(localStorage:)`
hook. The `auth-supabase` module therefore **requires** the `secure-storage` module and supplies
a `LocalStorage` backed by the template's `SecureStore`. The package's `shared_preferences`
default is not used.

## Evidence

- `firebase_auth` 7.0.0 on pub.dev, published 2026-10-16, BSD-3-Clause, publisher
  `firebase.google.com`, Dart `^3.6.0` / Flutter `>=3.16.0`, 1.93M downloads (checked
  2026-10-22).
- `firebase_core` 5.0.0 on pub.dev, published 2026-10-15, BSD-3-Clause, publisher
  `firebase.google.com`, Dart `^3.6.0` / Flutter `>=3.27.0`, 5.38M downloads (checked
  2026-10-22).
- `supabase_flutter` 2.18.3 on pub.dev, published 2026-10-12, MIT, publisher `supabase.io`,
  Dart `>=3.9.0 <4.0.0` / Flutter `>=3.35.0`, 1.32M downloads, latest pre-release
  `3.0.0-dev.12` (checked 2026-10-22).
- The `firebase_auth` 7.0.0 changelog: "build on Firebase BoM 35 and require minSdk 24" and
  "bump Firebase iOS SDK to 13.0.0" (checked 2026-10-22).
- The `supabase_flutter` 2.18.3 source: `LocalStorage` is an abstract class with
  `initialize`, `hasAccessToken`, `accessToken`, `removePersistedSession`, and
  `persistSession`; `SharedPreferencesLocalStorage` is the default; `EmptyLocalStorage` disables
  persistence; `FlutterAuthClientOptions` takes a `localStorage` (checked 2026-10-22).
- The `gotrue` 2.27.3 source: `signUp`, `signInWithPassword`, `signOut`, `resetPasswordForEmail`,
  `refreshSession`, `currentSession`, `currentUser`, and the `onAuthStateChange` stream with the
  `AuthChangeEvent` values `initialSession`, `passwordRecovery`, `signedIn`, `signedOut`,
  `tokenRefreshed`, `userUpdated`, `mfaChallengeVerified` (checked 2026-10-22).
- The `firebase_auth` 7.0.0 source: `FirebaseAuth.instance`, `currentUser`, `authStateChanges()`,
  `idTokenChanges()`, `userChanges()`, `signInWithEmailAndPassword`,
  `createUserWithEmailAndPassword`, `sendPasswordResetEmail`, `signOut`, and
  `User.getIdToken([bool forceRefresh])` (checked 2026-10-22).
- FlutterFire, "Get started with Firebase in your Flutter project" — Android requires API 24 or
  higher; `flutterfire configure` writes `lib/firebase_options.dart`; the configuration file
  "contains unique, but non-secret identifiers"; the Google services Gradle plugin is added for
  Crashlytics and Performance Monitoring, not for Authentication (page last updated 2026-10-22).
- The Flutter SDK's `FlutterExtension.kt`: `minSdkVersion = 24`, `compileSdkVersion = 36`,
  `targetSdkVersion = 36` (checked 2026-10-22).
- **Proof of concept**: a throwaway app with `firebase_core` + `firebase_auth` built a debug APK
  in 140.9 s on the template's toolchain, and a throwaway app with `supabase_flutter` built a
  debug APK in 102.5 s on the same toolchain (2026-10-22). The `firebase_auth` build printed
  Flutter's warning that the plugins apply the Kotlin Gradle Plugin and that "future versions of
  Flutter will fail to build if your app uses plugins that apply KGP".
- The roadmap §6.2, §6.3, §5.4, §8.1, and the `v0.5.0` section (read 2026-10-22).

## Trade-offs

- Three provider SDKs and their transitive sets are added to generated projects that select the
  corresponding module. `supabase_flutter` brings `app_links`, `shared_preferences`,
  `url_launcher`, `supabase`, `supabase_common`, and `logging`; `firebase_auth` brings
  `firebase_auth_platform_interface`, `firebase_auth_web`, and `firebase_core`. All are
  permissively licensed. `auth-rest` adds **no** dependency — it reuses the `networking`
  module's `dio`.
- The `shared_preferences` transitive dependency of `supabase_flutter` is still present even
  though the session is not stored there. That is a consequence of the package's structure, not
  a choice, and it is recorded rather than hidden.
- `firebase_auth` and `firebase_core` apply the Kotlin Gradle Plugin, which Flutter 3.47 warns
  will eventually be rejected. The build succeeds today. The risk is documented in the module
  document and in `docs/COMPATIBILITY.md` rather than left for a user to discover.
- A capability descriptor and a `--auth-capability` requirement are a small amount of generator
  surface. The alternative — adapters that silently lack an operation — is the failure the
  roadmap names explicitly.
- The provider SDKs are fresh majors. The structural mitigation is the port interface: an SDK
  change touches one thin implementation file rather than the contract or the features.

## Consequences

- The `auth-core` module owns `AuthAdapter`, `AuthSession`, `AuthUser`, `AuthState`,
  `AuthStatus`, `AuthError`, `AuthCapability`, `AuthCapabilities`, `SessionStore`,
  `SecureSessionStore`, `TokenRefreshCoordinator`, `AuthController`, and
  `authRouteRedirect`. It also owns the **shared contract-test suite**, so every adapter is
  verified against one definition of correct behaviour.
- The `auth-rest`, `auth-firebase`, and `auth-supabase` modules are mutually exclusive. The
  compatibility graph rejects a selection of two with an actionable message.
- The module manifest schema gains one **optional** field, `capabilities`. It is a
  backwards-compatible addition: an existing manifest without it still validates.
- The CLI gains `--auth` and `--auth-capability`. No released flag changes meaning.
- The `recommended` preset is **unchanged** and still selects no auth provider, because the
  roadmap says the provider "is chosen explicitly rather than guessed".
- Provider SDK types never appear in a feature. A feature depends on `AuthAdapter` and
  `AuthCapabilities`.
- The live Firebase and Supabase flows are **not** claimed as verified. They are owner actions
  OA-6 and OA-7, and every provider behaviour in this release is contract-tested against fakes.
- Auth UI, social sign-in, multi-factor authentication, phone sign-in, anonymous sign-in, and the
  data-backend adapters are **not** in this release. The capability descriptor reports each of
  them as unsupported rather than pretending it exists.

## Revisit triggers

- `firebase_auth` or `supabase_flutter` publishes a major version that changes the sign-in,
  session, or persistence API used here, or changes licence, publisher, or maintenance status.
- The Firebase or Supabase plugin migrates to Flutter's built-in Kotlin, or Flutter enforces the
  Kotlin Gradle Plugin check and the plugin has not migrated.
- A provider adds a capability the contract does not model, and more than one provider supports
  it, so the contract — not just the adapter — must change.
- The data-backend milestone adds `--backend`, which must not overload `--auth`.
- Real use of the `auth-rest` adapter shows that a configurable endpoint and payload shape is
  not enough, and a fixed backend shape would be better.
- A project's dependency budget cannot absorb the Firebase or Supabase transitive set, and the
  `auth-rest` adapter proves sufficient.
- The v0.8.0 UI milestone shows that the auth contract needs a state the current `AuthState`
  does not carry.
