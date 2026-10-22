# secure-storage

Secure key-value storage behind a small interface, with the platform requirements generated
rather than left to the developer.

## Capabilities

- `SecureStore` — a five-method interface: read, write, delete, delete all, and contains.
- `FlutterSecureStore` — the platform implementation. It is the only file in the module that
  imports `flutter_secure_storage`.
- `InMemorySecureStore` — a test double. Its contents are lost when the process ends, so it
  must never hold a production credential.

## Platform requirements

- **Minimum Android API 23.** The plugin's floor. The generated template uses `minSdk 24`, so
  nothing has to change today, but the requirement travels with the module.
- **Android backup exclusion.** The plugin stores encrypted values in SharedPreferences.
  Restoring them without the Android Keystore key that wrapped them makes them unreadable
  and fails the app on start. The generated project therefore contains:
  - `android/app/src/main/res/xml/backup_rules.xml`;
  - `android/app/src/main/res/xml/data_extraction_rules.xml`;
  - `android:fullBackupContent` and `android:dataExtractionRules` on `<application>`.

  The plugin's `sharedpref` file is excluded rather than `android:allowBackup` being turned
  off, so the rest of the application data stays backed up.
- **No Android permission.** The module adds none. Biometric storage is opt-in and needs
  `android.permission.USE_BIOMETRIC` plus API 28 or newer; the module README and the
  `requiredSetup` note in the manifest record that.

## Encryption

Since version 10 of the plugin, the default ciphers are RSA-OAEP for the key and AES-GCM for
the stored value. The deprecated Jetpack Security `encryptedSharedPreferences` is no longer
used.

## Requires

- `architecture-core`

## Setup

None. `buildAppServices(config)` creates the store. A feature that needs to keep a session
secret receives a `SecureStore` through its constructor.

## Limits

- The store is key-value only. It has no query, no transaction, and no size limit beyond
  what the platform imposes.
- Biometric protection is a configuration of the plugin, not of this module, and it changes
  what a restored value can do.
- A value written by one application version may not be readable by another if the cipher
  configuration changes. The plugin migrates automatically between its own versions.

## Removal

Not applicable (modules are generation-time selections). Removing the module removes the
store, the `AppServices.secureStore` field, the Android backup resources, the manifest
attributes, and the `flutter_secure_storage` dependency.

## Tests

- A value that was written can be read back.
- A value is replaced, deleted, and cleared.
- A key that was never written reads as `null`.
- The generated project declares the backup resources and the manifest attributes, and adds
  no permission.
