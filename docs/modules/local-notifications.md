# Local notifications

The `local-notifications` module adds Android local notification channels, explicit
permission requests, and validated notification-tap routing. It is not a push-messaging
integration. The module requires `navigation`; the generator rejects it for unsupported
target platforms.

## Permission and initialization

Bootstrap initializes the notification plugin, creates the `devflutt_general` channel,
and handles a notification that launched the app. It does not show a permission prompt.
Request permission only after a user action:

```dart
final status = await LocalNotificationService().requestPermission();
if (status == NotificationPermissionStatus.granted) {
  await LocalNotificationService().show(
    id: 1,
    title: 'Update ready',
    body: 'Open the app to review it.',
    route: AppRoutes.home,
  );
}
```

`show` returns `false` when Android reports notifications are disabled and does not post
in that case. Permission denial does not block the rest of the app. Platform/plugin errors
are surfaced to the caller rather than converted into a successful result.

## Tap routing

Notification taps are delivered to the existing router for foreground, background, and
cold-start launches. The payload must be an exact path in `AppRoutes.all`; schemes,
authorities, query strings, fragments, and unknown paths are rejected. A route payload is
untrusted navigation input, not authorization.

## Android changes and verification

Selecting the module adds `POST_NOTIFICATIONS` and enables Android core-library
desugaring for the plugin. Both changes are absent when the module is not selected.
The application should explain why notifications are useful before calling
`requestPermission`; it should not retry a denied request in a prompt loop.

Generated unit/widget tests cover permission outcomes, disabled notification behavior,
and route validation. The release manifest is checked for the conditional permission.
API 33+ emulator and physical-device permission/tap lifecycle checks are separate
verification gates.
