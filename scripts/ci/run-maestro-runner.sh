#!/bin/bash
# CI: run the Maestro flows with maestro-runner (https://github.com/devicelab-dev/maestro-runner).
#
# The same flows as scripts/run-maestro-tests.sh (.maestro/tests, .maestro/issues
# and .maestro/<platform>-only) against the installed Release app, with the same
# APP_ID, but all in one maestro-runner process; flows that fail run again, up
# to 3 attempts each, as `run-maestro-tests.sh --retry` does.
#
# Usage: scripts/ci/run-maestro-runner.sh <ios|android> [device-id]
set -uo pipefail

PLATFORM=${1:-}
DEVICE_ID=${2:-${MAESTRO_DEVICE:-}}
APPID="com.pagerviewexample"
MAX_ATTEMPTS=${MAX_ATTEMPTS:-3}
RUNNER="${MAESTRO_RUNNER:-$HOME/.maestro-runner/bin/maestro-runner}"

case $PLATFORM in
  ios | android) ;;
  *) echo "Usage: $0 <ios|android> [device-id]" >&2; exit 1 ;;
esac

shopt -s nullglob
flows=(
  .maestro/tests/*.yaml
  .maestro/issues/*.yaml
  .maestro/"$PLATFORM"-only/*.yaml
)
if [ ${#flows[@]} -eq 0 ]; then
  echo "No Maestro test files found for platform '$PLATFORM'." >&2
  exit 1
fi

"$RUNNER" --version

command=("$RUNNER" --platform "$PLATFORM")
[ -n "$DEVICE_ID" ] && command+=(--device "$DEVICE_ID")
command+=(
  test
  -e APP_ID="$APPID"
  --retries "$((MAX_ATTEMPTS - 1))"
  --output "reports/$PLATFORM"
  --flatten
  "${flows[@]}"
)

echo "Running ${#flows[@]} flow(s): ${command[*]}"
"${command[@]}"
