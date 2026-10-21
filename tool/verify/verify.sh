#!/usr/bin/env bash
# Local quality gate for the DevFlutt reference app.
#
# Prints every command, propagates every exit code, and writes per-command logs
# to build/verify-logs/. It never ends with an unconditional success message.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_DIR="$PROJECT_ROOT/build/verify-logs"
mkdir -p "$LOG_DIR"

cd "$PROJECT_ROOT"

FAILED=0

run_check() {
  local name="$1"
  shift
  local log="$LOG_DIR/$name.log"
  echo "==> $name: $*"
  if "$@" >"$log" 2>&1; then
    echo "    PASS"
  else
    echo "    FAIL (exit $?). See $log"
    cat "$log"
    FAILED=$((FAILED + 1))
  fi
}

run_check pub_get flutter pub get
run_check format dart format --output=none --set-exit-if-changed .
run_check analyze flutter analyze --fatal-infos
run_check test flutter test
run_check apk_debug flutter build apk --debug --flavor dev
run_check apk_release flutter build apk --release --flavor prod

echo "==> release_permissions"
RELEASE_APK="$PROJECT_ROOT/build/app/outputs/flutter-apk/app-prod-release.apk"
SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
AAPT2="$(ls -d "$SDK"/build-tools/*/ 2>/dev/null | sort -V | tail -1)aapt2"
if [ -z "$AAPT2" ] || [ ! -x "$AAPT2" ]; then
  echo "    SKIP (aapt2 not found; CI performs this check)"
elif "$AAPT2" dump permissions "$RELEASE_APK" >"$LOG_DIR/release-permissions.log" 2>&1 \
  && ! grep -q "android.permission.INTERNET" "$LOG_DIR/release-permissions.log"; then
  echo "    PASS"
else
  echo "    FAIL. See $LOG_DIR/release-permissions.log"
  cat "$LOG_DIR/release-permissions.log"
  FAILED=$((FAILED + 1))
fi

echo
if [ "$FAILED" -eq 0 ]; then
  echo "All checks passed."
  exit 0
else
  echo "$FAILED check(s) failed. See $LOG_DIR for details."
  exit 1
fi
