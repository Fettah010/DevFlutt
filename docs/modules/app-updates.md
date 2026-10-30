# App updates

The `app-updates` module adds a typed Android adapter over Google Play in-app updates and
an app-specific HTTPS Play Store listing fallback. It is opt-in, Android-only, and does
not add a permission. In-app update availability and update flows require an installation
distributed through Google Play.

## Checking and handling outcomes

Construct `PlayAppUpdateClient` with the generated application's base application ID.
The client distinguishes available, unavailable, canceled, failed, unsupported, completed,
and store-opened outcomes. Offer the listing fallback when the Play API is unavailable or
unsupported:

```dart
final updates = PlayAppUpdateClient(applicationId: 'com.example.my_app');
final availability = await updates.checkForUpdate();

if (availability.status == AppUpdateStatus.available) {
  final result = await updates.performImmediateUpdate();
  // Present canceled/failed states in the application UI.
} else if (availability.status == AppUpdateStatus.unavailable ||
    availability.status == AppUpdateStatus.unsupported) {
  final fallback = await updates.openStoreFallback();
  // Handle a failed store launch rather than treating it as success.
}
```

The adapter exposes both immediate and flexible flows. A flexible update's
`startFlexibleUpdate()` returns `downloadStarted`; listen to `installStatus` for progress
and call `completeFlexibleUpdate()` when the status is `downloaded`. The stream includes
pending, downloading, installing, installed, failed, canceled, and unknown states.

## Testing limits

Fake-backed tests verify outcome mapping, update gating, progress exposure, the generated
application ID in the HTTPS fallback, and launch failures. They do not prove a live Play
flow. Test that flow with a signed build installed from a Google Play internal-testing
track; production rollout and Play Console setup are outside this module.
