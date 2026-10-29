#!/usr/bin/env bash
set -euo pipefail

workspace="${GITHUB_WORKSPACE:?GITHUB_WORKSPACE must be set}"
runner_temp="${RUNNER_TEMP:?RUNNER_TEMP must be set}"
device="emulator-5554"
project="$runner_temp/devflutt-platform-services-smoke"
logs="$workspace/build/patrol-logs"
generation_log="$logs/platform-services-generator.txt"
tap_test_log="$logs/platform-services-notification-tap.txt"
apk="build/app/outputs/flutter-apk/app-dev-debug.apk"
driver_pid=""

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required to locate notification controls in the emulator UI." >&2
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

tap_notification() {
  local title="$1"
  local bounds=""

  adb -s "$device" shell cmd statusbar expand-notifications
  for ((attempt = 0; attempt < 15; attempt += 1)); do
    adb -s "$device" shell rm -f /sdcard/devflutt-notification-window.xml
    if adb -s "$device" shell uiautomator dump /sdcard/devflutt-notification-window.xml > "$logs/notification-ui-dump.txt" 2>&1; then
      if bounds="$(adb -s "$device" exec-out cat /sdcard/devflutt-notification-window.xml | python3 -c '
import re
import sys
import xml.etree.ElementTree as ET

root = ET.fromstring(sys.stdin.read())
parents = {child: parent for parent in root.iter() for child in parent}
for node in root.iter():
    if node.attrib.get("text") != sys.argv[1]:
        continue
    while node is not None and node.attrib.get("clickable") != "true":
        node = parents.get(node)
    if node is None:
        break
    coordinates = [int(value) for value in re.findall(r"\d+", node.attrib["bounds"])]
    print((coordinates[0] + coordinates[2]) // 2, (coordinates[1] + coordinates[3]) // 2)
    raise SystemExit(0)
raise SystemExit(1)
' "$title")" && [[ -n "$bounds" ]]; then
        read -r x y <<< "$bounds"
        echo "Tapping notification: $title at $x,$y"
        adb -s "$device" shell input tap "$x" "$y"
        return
      fi
    fi
    sleep 1
  done

  echo "Notification titled '$title' was not found in the Android UI." >&2
  cat "$logs/notification-ui-dump.txt" >&2
  adb -s "$device" exec-out cat /sdcard/devflutt-notification-window.xml >&2 || true
  return 1
}

cd "$workspace"
if ! dart run tool/ftemplate_cli/bin/ftemplate.dart create --name "Platform Services CI Smoke" --org com.example --preset blank --module feature-example --module background-work --module local-notifications --module app-updates --output "$project" --no-pub >"$generation_log" 2>&1; then
  cat "$generation_log" >&2
  exit 1
fi
cat "$generation_log"

application_id=$(sed -n 's/^Application ID: //p' "$generation_log" | tail -n 1)
if [[ -z "$application_id" ]]; then
  echo "Generator output did not include an application ID." >&2
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

user_id=$(adb -s "$device" shell am get-current-user | tr -d '\r')
if [[ -z "$user_id" ]]; then
  echo "Could not determine the active Android user." >&2
  exit 1
fi

adb -s "$device" install --user "$user_id" -r "$apk"
if ! adb -s "$device" shell pm list packages --user "$user_id" | tr -d '\r' | grep -Fx "package:$package_id"; then
  echo "Generated app package $package_id is not installed for Android user $user_id." >&2
  adb -s "$device" shell pm list packages --user "$user_id" >&2
  exit 1
fi

adb -s "$device" shell pm revoke --user "$user_id" "$package_id" android.permission.POST_NOTIFICATIONS
flutter drive --no-dds --driver=test_driver/integration_test.dart --target=integration_test/platform_services_test.dart -d "$device" --flavor dev

adb -s "$device" install --user "$user_id" -r "$apk"
adb -s "$device" shell pm grant --user "$user_id" "$package_id" android.permission.POST_NOTIFICATIONS
flutter drive --no-dds --driver=test_driver/integration_test.dart --target=integration_test/platform_services_test.dart -d "$device" --flavor dev --dart-define=DEVFLUTT_EXPECT_NOTIFICATIONS_GRANTED=true --dart-define=DEVFLUTT_EXPECT_NOTIFICATION_TAP=true >"$tap_test_log" 2>&1 &
driver_pid=$!
for ((attempt = 0; attempt < 90; attempt += 1)); do
  if grep -Fq "WARM_NOTIFICATION_TAP_READY" "$tap_test_log"; then
    break
  fi
  if ! kill -0 "$driver_pid" 2>/dev/null; then
    wait "$driver_pid" || true
    cat "$tap_test_log" >&2
    exit 1
  fi
  sleep 1
done
if ! grep -Fq "WARM_NOTIFICATION_TAP_READY" "$tap_test_log"; then
  echo "Timed out waiting for the warm-start notification tap." >&2
  cat "$tap_test_log" >&2
  exit 1
fi

tap_notification "Warm notification tap test"
if ! wait "$driver_pid"; then
  driver_pid=""
  cat "$tap_test_log" >&2
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

adb -s "$device" shell input keyevent 3
if ! adb -s "$device" shell am kill "$package_id"; then
  echo "Could not terminate the generated app before the cold-start tap test." >&2
  exit 1
fi
sleep 2
if [[ -n "$(adb -s "$device" shell pidof "$package_id" | tr -d '\r')" ]]; then
  echo "Could not stop the generated app process before cold-start tap verification." >&2
  exit 1
fi
tap_notification "Cold notification tap test"
for ((attempt = 0; attempt < 30; attempt += 1)); do
  adb -s "$device" shell rm -f /sdcard/devflutt-notification-window.xml
  if adb -s "$device" shell uiautomator dump /sdcard/devflutt-notification-window.xml > "$logs/cold-start-ui-dump.txt" 2>&1 &&
      adb -s "$device" exec-out cat /sdcard/devflutt-notification-window.xml | grep -Fq 'text="Counter"'; then
    echo "Cold-start notification tap opened the counter route."
    break
  fi
  sleep 1
done
if ! adb -s "$device" exec-out cat /sdcard/devflutt-notification-window.xml | grep -Fq 'text="Counter"'; then
  echo "Cold-start notification tap did not open the counter route." >&2
  cat "$logs/cold-start-ui-dump.txt" >&2
  adb -s "$device" exec-out cat /sdcard/devflutt-notification-window.xml >&2 || true
  exit 1
fi
