# auth-firebase

The authentication adapter for Firebase Authentication.

## Capabilities

- `FirebaseAuthPort` - the provider boundary. The adapter depends on it, never on the
  Firebase SDK.
- `FirebaseAuthAdapter` - the provider-neutral behaviour over the port.
- `FirebaseAuthPortImpl` - the real port. It is the only file in the module that imports
  `firebase_auth`.
- `FakeFirebaseAuthPort` - a deterministic test double that never touches Firebase.
- `initializeFirebaseAuth` - prepares Firebase at start-up.
- `lib/firebase_options.dart` - the configuration file, shipped as an inert placeholder.

## Setup

1. Create a Firebase project and register the Android app in it.
2. Install the Firebase CLI and the FlutterFire CLI:
   `dart pub global activate flutterfire_cli`.
3. In the generated project, run:

   ```text
   flutterfire configure
   ```

   The command writes the real `lib/firebase_options.dart` and registers the app.

Until that command has been run, the shipped placeholder is in place and the application
refuses to start with a message that names the command. The placeholder values are
deliberately not shaped like real credentials, so a secret scanner cannot mistake them
for one.

The Flutter path needs **no** `google-services.json` and **no**
`com.google.gms.google-services` Gradle plugin. Those belong to the native Android SDK.
`flutterfire configure` writes the configuration file the Flutter SDK reads.

## Platform requirements

- Firebase Authentication requires Android API 24 or newer. The template's minimum SDK is
  already 24, so there is no margin: a future increase of the template's floor is not
  needed for Firebase.
- `firebase_auth` 7.0.0 and `firebase_core` 5.0.0 still apply the Kotlin Gradle Plugin.
  Flutter 3.47 warns that future Flutter versions will refuse plugins that apply it. The
  build succeeds on the pinned toolchain. When the plugin migrates, the warning goes away.

## Session handling

Firebase keeps the session itself, so the adapter does not persist one. `restoreSession`
asks the provider whether a session exists and reads the current ID token.

The ID token is the access token. Firebase refreshes it inside its SDK, so the adapter asks
for a fresh token with `getIdToken(forceRefresh: true)` when the application needs one
rather than running its own refresh.

## One-time-password sign-in

The adapter supports Firebase's email-link sign-in. The token is the whole link, and the
adapter reads the address from the link's query string. A link without an address is
rejected with a `provider-failure` error, because the provider would reject it with a much
less useful message.

The link must reach the application as a deep link. The template does not add one: the
scheme is the application's choice, and the module documents what to configure.

## Requires

- `auth-core` - which brings `architecture-core`, `logging`, and `secure-storage`

## Setup

The module adds no permission and no configuration key. Run `flutterfire configure`, then
build the adapter in `buildAppServices` in `lib/app/app_services.dart`.

Firebase owns the password policy, multi-factor authentication, account recovery, and
session revocation. The client does not implement them and must not imply them.

## Limits

- Social sign-in is not implemented in this release. Every social provider needs
  provider-console setup and platform configuration that the template cannot exercise or
  verify.
- The live flow is not verified by the template's tests: no Firebase project is available
  here. The tests are contract tests against a fake, which prove the contract, not the
  provider. See owner action OA-6 in the release report.
- iOS is unverified: no macOS host or runner is available.

## Removal behaviour

Remove the module. The `firebase_auth` and `firebase_core` dependencies and the
configuration file go with it. The `secure-storage` module stays, because other modules
select it too.

## Test plan

`test/unit/auth/firebase_auth_contract_test.dart` runs the shared contract suite against
the adapter and adds the adapter-specific cases: restoring a session the provider already
has, restoring no session, a forced refresh asking the provider for a new token, a token
the provider refuses, an email link signing the user in, and an email link without an
address being rejected.
