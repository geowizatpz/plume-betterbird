#!/usr/bin/env bash
# Plume for Betterbird: uninstaller for macOS and Linux.
#
#   ./uninstall.sh                   remove from the default profile
#   ./uninstall.sh --profile <path>  remove from a specific profile folder
#
# Moves the theme's chrome folder aside (nothing is deleted) and restores
# the newest chrome.backup-* folder if the installer made one.
# The pref in user.js is left alone; with no userChrome.css it does nothing.

set -euo pipefail

PROFILE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$PROFILE" ]]; then
  for root in "$HOME/Library/Thunderbird" "$HOME/.thunderbird"; do
    ini="$root/profiles.ini"
    [[ -f "$ini" ]] || continue
    rel="$(awk -F= '/^\[Install/{inst=1;next} /^\[/{inst=0} inst&&$1=="Default"{print $2; exit}' "$ini")"
    [[ -n "$rel" ]] && { [[ "$rel" = /* ]] && PROFILE="$rel" || PROFILE="$root/$rel"; break; }
  done
fi
[[ -d "${PROFILE:-}" ]] || { echo "Profile not found. Pass --profile <path>." >&2; exit 1; }

TARGET="$PROFILE/chrome"
if [[ ! -f "$TARGET/.plume" ]]; then
  echo "No Plume install found in $TARGET. Nothing changed."
  exit 0
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
mv "$TARGET" "$PROFILE/chrome.plume-removed-$STAMP"
echo "Moved theme to: $PROFILE/chrome.plume-removed-$STAMP"

LATEST="$(ls -1d "$PROFILE"/chrome.backup-* 2>/dev/null | sort | tail -n 1 || true)"
if [[ -n "$LATEST" ]]; then
  mv "$LATEST" "$TARGET"
  echo "Restored your previous chrome folder from: $LATEST"
fi

echo "Done. Restart Betterbird."
