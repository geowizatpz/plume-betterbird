#!/usr/bin/env bash
# Development helper (macOS): copy chrome/ into a profile and restart Betterbird.
#
#   scripts/dev-reload.sh <profile-path>
#
# Your user-overrides.css in the profile is left alone.

set -euo pipefail

PROFILE="${1:?Pass the profile folder}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

rsync -a --delete --exclude user-overrides.css --exclude .plume \
  "$REPO_DIR/chrome/" "$PROFILE/chrome/"

if pgrep -xi betterbird >/dev/null; then
  osascript -e 'tell application "Betterbird" to quit'
  for _ in $(seq 1 30); do
    pgrep -xi betterbird >/dev/null || break
    sleep 0.5
  done
fi

open -a Betterbird
echo "Synced and restarted."
