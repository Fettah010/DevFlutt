# backend-firestore

A provider-specific document client for Firebase Cloud Firestore. It does not expose a
universal database API or select Firebase Authentication.

## Capabilities

- `FirestoreDocumentClient` - reads, replaces, and deletes documents by collection and ID.
- `FirestoreDocument` - a document ID and decoded `Map<String, Object?>` fields.
- `FirestoreResult<T>` - a typed success/failure outcome; provider error text is not retained.
- `FirestoreDocumentPort` - the provider boundary used by the client.
- `FirebaseFirestoreDocumentPort` - the real `cloud_firestore` implementation.
- `FakeFirestoreDocumentPort` - a deterministic test double that never contacts Firebase.

`setDocument` replaces the document fields. It is not a partial update. Callers must choose
their document IDs and data model deliberately; this module does not add schema validation,
queries, transactions, batch writes, or conflict resolution.

## Setup

1. Create a Firebase project and register the Android app.
2. Run `flutterfire configure` in the generated project. The shared `firebase-core` module
   owns `lib/firebase_options.dart` and initializes Firebase once, even when Firebase Auth
   and Firestore are both selected.
3. Configure and test Firestore security rules for every collection. Backend selection does
   not select Firebase Auth or authorize a request.
4. Inject `AppServices.firestoreClient` into the feature that needs it.

The client maps Firestore permission, authentication, availability, timeout, invalid-input,
and missing-resource codes to provider-independent error codes. Unknown provider errors map
to `unknown`; raw SDK messages and document contents are never included in the error.
Malformed document payloads return `malformedData`.

## Android compatibility

`cloud_firestore` 7.1.0 omits an Android library namespace under AGP 9.1.0. The generated
root Gradle script supplies `io.flutter.plugins.firebase.firestore` through a typed,
module-scoped Android library hook only when this module is selected and the plugin does
not declare a namespace. Do not patch the Pub cache or copy the workaround into unrelated
projects. Keep the selected debug and release builds as regression checks until an upstream
package version supplies its own namespace.

This module currently targets Android only. iOS generation, build, and runtime behavior have
not been verified.

## Security and limits

Firestore security rules and server-side authorization are the security boundary. A client
check is not authorization. Firebase configuration identifiers are public client
configuration, not secrets; never include a service-account key in the application.
Configure Firestore rules and validate them against the deployed project before release.

The module leaves the Firebase SDK's cache/offline defaults unchanged. It does not promise
offline synchronization, conflict resolution, provider uptime, or live-service behavior.
Unit tests use the fake port and make no network requests.

## Tests

Generated tests cover document reads, absent documents, replacement writes, deletes,
malformed payloads, invalid identifiers, and safe typed error mapping. The Android build
checks the selected-only namespace workaround and package integration.
