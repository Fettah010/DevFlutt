# Background work

The `background-work` module adds an Android-only, typed adapter over WorkManager.
It schedules named one-off tasks with optional network, charging, battery, idle, and
storage constraints, plus linear or exponential retry backoff. WorkManager is
best-effort: Android controls when work runs, so this is not an exact-time scheduler.

```dart
const scheduler = WorkmanagerTaskScheduler();
await scheduler.scheduleOneOff(
  BackgroundTask(
    uniqueName: 'refresh-notes',
    taskName: sampleBackgroundTaskName,
    constraints: const BackgroundTaskConstraints(
      network: BackgroundNetworkRequirement.connected,
      requiresBatteryNotLow: true,
    ),
  ),
);
```

Replace `handleBackgroundTask` in the generated callback dispatcher with app-owned
task logic. Return `BackgroundTaskResult.success` when complete; return
`BackgroundTaskResult.retry` to request another attempt using the configured backoff.
Workmanager's callback contract does not expose a distinct terminal-failure result.
Unknown task names return `retry`, so keep the dispatcher and task registrations in
sync. Task input is persisted by the platform: provide only small, non-sensitive
serializable values, never credentials, tokens, or private user content. The module
does not perform network requests or sync automatically. The plugin contributes boot,
wake-lock, and network-state permissions; its foreground-service and notification
permissions are removed because this adapter does not expose foreground work.
