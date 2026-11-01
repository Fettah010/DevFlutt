# firebase-core

Shared Firebase configuration and one-time SDK initialization for selected Firebase
modules. It is pulled in automatically by `auth-firebase` and `backend-firestore`; it does
not select either capability by itself.

## Capabilities

- Owns `lib/firebase_options.dart` and the shared Firebase initializer.
- Initializes `firebase_core` once for all selected Firebase modules.
- Fails fast with setup guidance while the inert options placeholder remains.

## Setup

1. Create a Firebase project and register the generated Android app.
2. Install the Firebase CLI and FlutterFire CLI, then run `flutterfire configure` from the
   generated project.
3. Review the generated `lib/firebase_options.dart`. Firebase configuration identifiers
   are public client configuration; never put a service-account key in the app.
4. Configure the selected Firebase services independently. For Firestore, configure and
   test Security Rules for the deployed data model.

The Flutter integration uses `firebase_options.dart`; this template does not require
`google-services.json` or the Google Services Gradle plugin.

## Platform and privacy limits

The manifest supports Android and iOS, but the v0.9.1 generated-project matrix verifies
Android only. The core does not select Auth, Firestore, Storage, Realtime Database,
Analytics, or Crashlytics. Firebase service permissions and behavior are contributed only
by the selected service modules and their SDKs. Live Firebase configuration and service
behavior require an owner-provided project and are not established by fake-backed tests.

## Removal behavior

Remove every selected Firebase auth/data module. The generator then omits this core,
`firebase_options.dart`, its initializer, and `firebase_core`; it remains only when another
selected Firebase module requires it.

## Test plan

Generator tests verify selected-only files and one shared initializer for Firebase Auth +
Firestore. Generated Firebase Auth and Firestore projects are tested and built separately;
the matching composition is included in the generated-project CI matrix.
