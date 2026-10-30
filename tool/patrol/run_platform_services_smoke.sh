#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${MSYSTEM:-}" ]]; then
  export MSYS_NO_PATHCONV=1
fi

workspace="${GITHUB_WORKSPACE:?GITHUB_WORKSPACE must be set}"
runner_temp="${RUNNER_TEMP:?RUNNER_TEMP must be set}"
device="emulator-5554"
project="$runner_temp/devflutt-platform-services-smoke"
logs="$workspace/build/patrol-logs"
generation_log="$logs/platform-services-generator.txt"
tap_test_log="$logs/platform-services-notification-tap.txt"
apk="build/app/outputs/flutter-apk/app-dev-debug.apk"
driver_pid=""

if ! command -v node >/dev/null 2>&1; then
  echo "node is required to locate notification controls in the emulator UI." >&2
  exit 1
fi

mkdir -p "$logs"
cleanup() {
  if [[ -n "$driver_pid" ]] && kill -0 "$driver_pid" 2>/dev/null; then
    kill "$driver_pid"
    wait "$driver_pid" || echo "Notification tap integration driver exited during cleanup." >&2
  fi
  if ! adb -s "$device" logcat -d -v threadtime > "$logs/platform-services-logcat.txt"; then
    echo "Could not capture platform-service emulator logcat." >&2
  fi
}
trap cleanup EXIT

capture_device_diagnostics() {
  local label="$1"
  adb devices -l > "$logs/${label}-adb-devices.txt" 2>&1 || true
  adb -s "$device" get-state > "$logs/${label}-adb-state.txt" 2>&1 || true
  adb -s "$device" logcat -d -v threadtime > "$logs/${label}-logcat.txt" 2>&1 || true
  adb -s "$device" shell dumpsys notification --noredact > "$logs/${label}-notifications.txt" 2>&1 || true
  adb -s "$device" shell dumpsys activity activities > "$logs/${label}-activities.txt" 2>&1 || true
  adb -s "$device" shell dumpsys window windows > "$logs/${label}-windows.txt" 2>&1 || true
}

wait_for_device_ready() {
  local label="$1"
  local attempt

  for ((attempt = 1; attempt <= 60; attempt += 1)); do
    if [[ "$(adb -s "$device" get-state 2>/dev/null || true)" == "device" ]] &&
        [[ "$(adb -s "$device" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)" == "1" ]]; then
      echo "Android device $device is ready ($label)."
      return 0
    fi
    if ((attempt % 10 == 0)); then
      adb reconnect offline >/dev/null 2>&1 || true
    fi
    sleep 2
  done

  echo "Android device $device did not become ready ($label)." >&2
  capture_device_diagnostics "$label"
  adb devices -l >&2 || true
  return 1
}

run_flutter_drive() {
  local label="$1"
  shift
  local attempt=1
  local exit_code=0
  local output="$logs/${label}-attempt-${attempt}.txt"

  while ((attempt <= 2)); do
    wait_for_device_ready "$label-before-attempt-$attempt"
    if flutter drive "$@" > "$output" 2>&1; then
      cat "$output"
      return 0
    else
      exit_code=$?
    fi

    if ((attempt == 2)) || ! grep -Eiq 'Service connection disposed|adb: device offline|device offline' "$output"; then
      cat "$output" >&2
      capture_device_diagnostics "$label-failure-attempt-$attempt"
      return "$exit_code"
    fi

    echo "Flutter driver hit an ADB/VM-service transport failure; attempting one bounded device reconnect." >&2
    cat "$output" >&2
    capture_device_diagnostics "$label-transport-failure"
    adb reconnect offline >/dev/null 2>&1 || true
    adb start-server >/dev/null 2>&1 || true
    wait_for_device_ready "$label-reconnect" || return "$exit_code"
    attempt=$((attempt + 1))
    output="$logs/${label}-attempt-${attempt}.txt"
  done
}

tap_notification() {
  local title="$1"
  local bounds=""

  adb -s "$device" shell cmd statusbar expand-notifications
  for ((attempt = 0; attempt < 15; attempt += 1)); do
    adb -s "$device" shell rm -f /sdcard/devflutt-notification-window.xml
    if adb -s "$device" shell uiautomator dump /sdcard/devflutt-notification-window.xml > "$logs/notification-ui-dump.txt" 2>&1; then
      if bounds="$(adb -s "$device" exec-out cat /sdcard/devflutt-notification-window.xml | node "$workspace/tool/patrol/notification_bounds.js" "$title")" && [[ -n "$bounds" ]]; then
        read -r x y <<< "$bounds"
        echo "Tapping notification: $title at $x,$y"
        adb -s "$device" shell input tap "$x" "$y"
        return
      fi
    fi
    sleep 1
  done

  echo "Notification titled '$title' was not found in the Android UI." >&2
  capture_device_diagnostics "notification-not-found"
  cat "$logs/notification-ui-dump.txt" >&2
  adb -s "$device" exec-out cat /sdcard/devflutt-notification-window.xml >&2 || true
  return 1
}

install_generated_app() {
  local install_log="$logs/generated-app-install.txt"
  if adb -s "$device" install --user "$user_id" -r "$apk" > "$install_log" 2>&1; then
    cat "$install_log"
    return 0
  fi

  if ! grep -Fq 'INSTALL_FAILED_UPDATE_INCOMPATIBLE' "$install_log"; then
    cat "$install_log" >&2
    return 1
  fi

  echo "Replacing the stale generated smoke package after a signing-key mismatch."
  if ! adb -s "$device" uninstall "$package_id" >> "$install_log" 2>&1 ||
      ! adb -s "$device" install --user "$user_id" "$apk" >> "$install_log" 2>&1; then
    cat "$install_log" >&2
    return 1
  fi
  cat "$install_log"
}

cd "$workspace"
if ! dart run tool/ftemplate_cli/bin/ftemplate.dart create --name "Platform Services CI Smoke" --org com.example --preset blank --module feature-example --module background-work --module local-notifications --module app-updates --output "$project" --no-pub >"$generation_log" 2>&1; then
  cat "$generation_log" >&2
  exit 1
fi
cat "$generation_log"

application_id=$(sed -n 's/^Application ID: //p' "$generation_log" | tail -n 1)
dart_package=$(sed -n 's/^Package: //p' "$generation_log" | tail -n 1)
if [[ -z "$application_id" ]]; then
  echo "Generator output did not include an application ID." >&2
  exit 1
fi
if [[ -z "$dart_package" ]]; then
  echo "Generator output did not include a Dart package name." >&2
  exit 1
fi
package_id="${application_id}.dev"

cd "$project"
flutter pub get
flutter build apk --debug --flavor dev
if [[ ! -f "$apk" ]]; then
  echo "Generated debug APK was not found at $project/$apk." >&2
  exit 1
fi

wait_for_device_ready "before-install"
user_id=$(adb -s "$device" shell am get-current-user | tr -d '\r')
if [[ -z "$user_id" ]]; then
  echo "Could not determine the active Android user." >&2
  exit 1
fi

install_generated_app
wait_for_device_ready "after-install-denied"
if ! adb -s "$device" shell pm list packages --user "$user_id" | tr -d '\r' | grep -Fx "package:$package_id"; then
  echo "Generated app package $package_id is not installed for Android user $user_id." >&2
  adb -s "$device" shell pm list packages --user "$user_id" >&2
  exit 1
fi

adb -s "$device" shell pm revoke --user "$user_id" "$package_id" android.permission.POST_NOTIFICATIONS
run_flutter_drive permission-denied --no-dds --driver=test_driver/integration_test.dart --target=integration_test/platform_services_test.dart -d "$device" --flavor dev

install_generated_app
wait_for_device_ready "after-install-granted"
adb -s "$device" shell pm grant --user "$user_id" "$package_id" android.permission.POST_NOTIFICATIONS
tap_attempt=1
tap_test_log="$logs/platform-services-notification-tap-attempt-${tap_attempt}.txt"
while ((tap_attempt <= 2)); do
  wait_for_device_ready "before-notification-tap-attempt-${tap_attempt}"
  flutter drive --keep-app-running --no-dds --driver=test_driver/integration_test.dart --target=integration_test/platform_services_test.dart -d "$device" --flavor dev --dart-define=DEVFLUTT_EXPECT_NOTIFICATIONS_GRANTED=true --dart-define=DEVFLUTT_EXPECT_NOTIFICATION_TAP=true >"$tap_test_log" 2>&1 &
  driver_pid=$!
  warm_marker_seen=false

  for ((attempt = 0; attempt < 90; attempt += 1)); do
    if grep -Fq "WARM_NOTIFICATION_TAP_READY" "$tap_test_log"; then
      warm_marker_seen=true
      break
    fi
    if ! kill -0 "$driver_pid" 2>/dev/null; then
      if wait "$driver_pid"; then
        driver_pid=""
        break
      else
        driver_exit=$?
      fi
      driver_pid=""
      if ((tap_attempt == 1)) && grep -Eiq 'Service connection disposed|adb: device offline|device offline' "$tap_test_log"; then
        echo "Notification-tap driver lost its ADB/VM-service transport; reconnecting once before retry." >&2
        capture_device_diagnostics "notification-tap-transport-failure"
        adb reconnect offline >/dev/null 2>&1 || true
        adb start-server >/dev/null 2>&1 || true
        if wait_for_device_ready "notification-tap-reconnect"; then
          install_generated_app
          adb -s "$device" shell pm grant --user "$user_id" "$package_id" android.permission.POST_NOTIFICATIONS
          tap_attempt=2
          tap_test_log="$logs/platform-services-notification-tap-attempt-${tap_attempt}.txt"
          break
        fi
        exit "$driver_exit"
      fi
      cat "$tap_test_log" >&2
      capture_device_diagnostics "notification-tap-failure"
      exit "$driver_exit"
    fi
    sleep 1
  done

  if [[ "$warm_marker_seen" == true ]]; then
    break
  fi
  if [[ -z "$driver_pid" && "$tap_attempt" -eq 1 ]]; then
    echo "Notification-tap driver exited before posting the warm notification." >&2
    cat "$tap_test_log" >&2
    capture_device_diagnostics "notification-tap-failure"
    exit 1
  fi
  if [[ -n "$driver_pid" ]] && kill -0 "$driver_pid" 2>/dev/null; then
    echo "Timed out waiting for the warm-start notification tap." >&2
    cat "$tap_test_log" >&2
    capture_device_diagnostics "notification-tap-timeout"
    exit 1
  fi
done
if [[ "$warm_marker_seen" != true ]]; then
  echo "Notification-tap driver did not become ready after the bounded retry." >&2
  cat "$tap_test_log" >&2
  exit 1
fi

tap_notification "Warm notification tap test"
if ! wait "$driver_pid"; then
  driver_pid=""
  cat "$tap_test_log" >&2
  capture_device_diagnostics "notification-tap-failure"
  exit 1
fi
driver_pid=""
cat "$tap_test_log"
if ! grep -Fq "Warm notification tap routed to the counter." "$tap_test_log"; then
  echo "The warm-start notification did not reach the counter route." >&2
  exit 1
fi
if ! grep -Fq "COLD_NOTIFICATION_TAP_READY" "$tap_test_log"; then
  echo "The integration app did not post its cold-start notification." >&2
  exit 1
fi

# flutter drive installs its integration-test entrypoint, which cannot serve as
# a normal cold-start app after the driver exits. Build a regular Flutter entrypoint
# that posts a notification, then test its actual application bootstrap on relaunch.
cat > "$project/lib/main_patrol_notification_smoke.dart" <<DART
import 'package:flutter/foundation.dart';
import 'package:${dart_package}/bootstrap/bootstrap.dart';
import 'package:${dart_package}/core/notifications/local_notification_service.dart';
import 'package:${dart_package}/app/app_routes.dart';

Future<void> main() async {
  await bootstrap();
  final shown = await LocalNotificationService().show(
    id: 740803,
    title: 'Cold notification tap test',
    body: 'Tap this notification to verify cold-start routing.',
    route: AppRoutes.counter,
  );
  if (!shown) throw StateError('The cold-start smoke notification was not shown.');
  debugPrint('COLD_NOTIFICATION_TAP_READY');
}
DART
if ! flutter build apk --debug --flavor dev --target=lib/main_patrol_notification_smoke.dart > "$logs/cold-start-smoke-build.txt" 2>&1; then
  echo "Could not build the normal Flutter cold-start smoke entrypoint." >&2
  cat "$logs/cold-start-smoke-build.txt" >&2
  exit 1
fi
cat "$logs/cold-start-smoke-build.txt"
install_generated_app
adb -s "$device" shell pm grant --user "$user_id" "$package_id" android.permission.POST_NOTIFICATIONS
adb -s "$device" logcat -c
if ! adb -s "$device" shell monkey -p "$package_id" -c android.intent.category.LAUNCHER 1 > "$logs/cold-start-smoke-launch.txt" 2>&1; then
  echo "Could not launch the normal Flutter cold-start smoke app." >&2
  cat "$logs/cold-start-smoke-launch.txt" >&2
  capture_device_diagnostics "cold-start-smoke-launch-failure"
  exit 1
fi
smoke_notification_ready=false
for ((attempt = 0; attempt < 60; attempt += 1)); do
  adb -s "$device" logcat -d -s flutter:I > "$logs/cold-start-setup-flutter-log.txt" 2>&1
  if grep -Fq 'COLD_NOTIFICATION_TAP_READY' "$logs/cold-start-setup-flutter-log.txt"; then
    smoke_notification_ready=true
    break
  fi
  sleep 1
done
if [[ "$smoke_notification_ready" != true ]]; then
  echo "The normal Flutter smoke app did not post its cold-start notification." >&2
  capture_device_diagnostics "cold-start-smoke-notification-failure"
  cat "$logs/cold-start-setup-flutter-log.txt" >&2
  exit 1
fi

adb -s "$device" shell input keyevent 3
wait_for_device_ready "before-cold-start"
sleep 2
capture_device_diagnostics "before-cold-start-kill"
if ! adb -s "$device" shell am kill "$package_id"; then
  echo "Could not terminate the generated app before the cold-start tap test." >&2
  exit 1
fi
for ((attempt = 0; attempt < 10; attempt += 1)); do
  if [[ -z "$(adb -s "$device" shell pidof "$package_id" | tr -d '\r')" ]]; then
    break
  fi
  sleep 1
done
if [[ -n "$(adb -s "$device" shell pidof "$package_id" | tr -d '\r')" ]]; then
  echo "Could not stop the generated app process before cold-start tap verification." >&2
  capture_device_diagnostics "cold-start-process-still-running"
  exit 1
fi
capture_device_diagnostics "after-cold-start-kill"
adb -s "$device" logcat -c
tap_notification "Cold notification tap test"
app_pid=""
for ((attempt = 0; attempt < 30; attempt += 1)); do
  app_pid="$(adb -s "$device" shell pidof "$package_id" | tr -d '\r' || true)"
  if [[ -n "$app_pid" ]]; then
    break
  fi
  sleep 1
done
if [[ -z "$app_pid" ]]; then
  echo "Tapping the cold notification did not start process $package_id." >&2
  capture_device_diagnostics "cold-start-process-not-launched"
  exit 1
fi
echo "Cold notification tap started $package_id (pid $app_pid)."

bootstrap_completed=false
route_applied=false
for ((attempt = 0; attempt < 30; attempt += 1)); do
  adb -s "$device" logcat -d -s flutter:I > "$logs/cold-start-flutter-log.txt" 2>&1
  if grep -Fq 'Generated app bootstrap completed.' "$logs/cold-start-flutter-log.txt"; then
    bootstrap_completed=true
  fi
  if grep -Fq 'Notification route hand-off applying the cold-start target.' "$logs/cold-start-flutter-log.txt"; then
    route_applied=true
  fi
  if [[ "$bootstrap_completed" == true && "$route_applied" == true ]]; then
    break
  fi
  sleep 1
done
if [[ "$bootstrap_completed" != true ]]; then
  echo "The cold-start process launched but generated app bootstrap did not complete." >&2
  capture_device_diagnostics "cold-start-bootstrap-failure"
  cat "$logs/cold-start-flutter-log.txt" >&2
  exit 1
fi
if ! grep -Fq 'Local notification service found a notification launch payload.' "$logs/cold-start-flutter-log.txt"; then
  echo "Cold-start bootstrap completed without receiving a notification launch payload." >&2
  capture_device_diagnostics "cold-start-route-handoff-failure"
  cat "$logs/cold-start-flutter-log.txt" >&2
  exit 1
fi
if [[ "$route_applied" != true ]]; then
  echo "Cold-start bootstrap received a notification payload but never applied the queued route." >&2
  capture_device_diagnostics "cold-start-route-handoff-failure"
  cat "$logs/cold-start-flutter-log.txt" >&2
  exit 1
fi

for ((attempt = 0; attempt < 12; attempt += 1)); do
  adb -s "$device" shell rm -f /sdcard/devflutt-notification-window.xml
  if adb -s "$device" shell uiautomator dump /sdcard/devflutt-notification-window.xml > "$logs/cold-start-ui-dump.txt" 2>&1 &&
      adb -s "$device" exec-out cat /sdcard/devflutt-notification-window.xml | grep -Fq 'content-desc="Counter"'; then
    echo "Cold-start notification tap opened the counter route."
    break
  fi
  sleep 1
done
if ! adb -s "$device" exec-out cat /sdcard/devflutt-notification-window.xml | grep -Fq 'content-desc="Counter"'; then
  echo "Cold-start notification tap did not open the counter route." >&2
  capture_device_diagnostics "cold-start-route-failure"
  cat "$logs/cold-start-ui-dump.txt" >&2
  adb -s "$device" exec-out cat /sdcard/devflutt-notification-window.xml >&2 || true
  exit 1
fi
