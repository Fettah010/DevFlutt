#!/usr/bin/env bash
set -euo pipefail

workspace="${GITHUB_WORKSPACE:?GITHUB_WORKSPACE must be set}"
runner_temp="${RUNNER_TEMP:?RUNNER_TEMP must be set}"
device="emulator-5554"
project="$runner_temp/devflutt-platform-services-smoke"
logs="$workspace/build/patrol-logs"
generation_log="$logs/platform-services-generator.txt"
apk="build/app/outputs/flutter-apk/app-dev-debug.apk"

mkdir -p "$logs"
trap 'if ! adb -s "$device" logcat -d -v threadtime > "$logs/platform-services-logcat.txt"; then echo "Could not capture platform-service emulator logcat." >&2; fi' EXIT

cd "$workspace"
if ! dart run tool/ftemplate_cli/bin/ftemplate.dart create --name "Platform Services CI Smoke" --org com.example --preset blank --module background-work --module local-notifications --module app-updates --output "$project" --no-pub >"$generation_log" 2>&1; then
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
flutter drive --no-dds --driver=test_driver/integration_test.dart --target=integration_test/platform_services_test.dart -d "$device" --flavor dev --dart-define=DEVFLUTT_EXPECT_NOTIFICATIONS_GRANTED=true
