#!/usr/bin/env bash
#
# install-local.sh - build this fork, install it to /Applications and keep a
# Finder alias on the Desktop, so the app starts from there.
#
# Signs with your Apple Development certificate when the keychain has one (the
# privileged helper then works), otherwise ad-hoc (app runs, helper does not).
# No notarisation, no network: the result is for this Mac only. Re-run after
# every change; the Desktop alias keeps pointing at the installed app.
#
# Flags:
#   --no-launch   install but do not start the app
#   --adhoc       force ad-hoc signing even if a certificate exists
set -euo pipefail
cd "$(dirname "$0")/.."

LAUNCH=1
RUN_ARGS=(--release --no-launch)
for arg in "$@"; do
  case "$arg" in
    --no-launch) LAUNCH=0 ;;
    --adhoc)     RUN_ARGS+=(--adhoc) ;;
    *) echo "install-local.sh: ignoring unknown argument '$arg'" >&2 ;;
  esac
done

APP_NAME="Mac Performance Monitor"
BUILT="build/$APP_NAME.app"
TARGET="/Applications/$APP_NAME.app"
ALIAS="$HOME/Desktop/$APP_NAME"

Scripts/run.sh "${RUN_ARGS[@]}"

echo "==> Quitting a running copy (if any)"
osascript -e 'tell application id "uk.co.bzwrd.macperfmonitor" to quit' >/dev/null 2>&1 || true
for _ in 1 2 3 4 5 6 7 8 9 10; do
  pgrep -xq "$APP_NAME" || break
  sleep 0.5
done

echo "==> Installing to $TARGET"
rm -rf "$TARGET"
ditto "$BUILT" "$TARGET"

if [[ ! -e "$ALIAS" ]]; then
  echo "==> Creating Desktop alias"
  osascript >/dev/null <<APPLESCRIPT
tell application "Finder"
  make new alias file at (path to desktop folder) to (POSIX file "$TARGET" as alias)
end tell
APPLESCRIPT
else
  echo "==> Desktop alias already present"
fi

if [[ "$LAUNCH" -eq 1 ]]; then
  echo "==> Launching"
  open "$TARGET"
fi
echo "Installed $TARGET"
