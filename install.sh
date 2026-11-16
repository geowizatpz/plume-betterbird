#!/usr/bin/env bash
# Plume for Betterbird: installer for macOS and Linux.
#
#   ./install.sh                     install into the default profile
#   ./install.sh --profile <path>    install into a specific profile folder
#   ./install.sh --force             install even if Betterbird is running
#
# What it does:
#   1. Moves an existing <profile>/chrome folder to chrome.backup-<timestamp>
#      (your user-overrides.css is carried over).
#   2. Copies this theme's chrome/ folder into the profile.
#   3. Backs up user.js and adds the pref that lets Betterbird load
#      userChrome.css: toolkit.legacyUserProfileCustomizations.stylesheets

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREF='user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
MARKER=".plume"
PROFILE=""
FORCE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE="${2:-}"; shift 2 ;;
    --force) FORCE=1; shift ;;
    -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# ── Find the profile ────────────────────────────────────────────────
find_profiles_root() {
  local candidates=(
    "$HOME/Library/Thunderbird"   # macOS (Betterbird shares this folder)
    "$HOME/.thunderbird"          # Linux
  )
  for dir in "${candidates[@]}"; do
    [[ -f "$dir/profiles.ini" ]] && { echo "$dir"; return; }
  done
}

default_profile() {
  local root ini rel
  root="$(find_profiles_root)"
  [[ -z "$root" ]] && return 1
  ini="$root/profiles.ini"
  # Prefer the profile the install uses ([Install...] Default=), then Default=1.
  rel="$(awk -F= '/^\[Install/{inst=1;next} /^\[/{inst=0} inst&&$1=="Default"{print $2; exit}' "$ini")"
  if [[ -z "$rel" ]]; then
    rel="$(awk -F= '/^\[Profile/{p="";d=0} $1=="Path"{p=$2} $1=="Default"&&$2=="1"{d=1} d&&p{print p; exit}' "$ini")"
  fi
  [[ -z "$rel" ]] && return 1
  if [[ "$rel" = /* ]]; then echo "$rel"; else echo "$root/$rel"; fi
}

if [[ -z "$PROFILE" ]]; then
  PROFILE="$(default_profile || true)"
fi
if [[ -z "$PROFILE" || ! -d "$PROFILE" ]]; then
  echo "Could not find a Betterbird profile. Pass one with --profile <path>." >&2
  echo "You can find it in Betterbird under Help > Troubleshooting Information > Profile Folder." >&2
  exit 1
fi

echo "Profile: $PROFILE"

# ── Refuse to run while Betterbird is open ──────────────────────────
if [[ $FORCE -eq 0 ]] && pgrep -xi "betterbird" >/dev/null 2>&1; then
  echo "Betterbird is running. Quit it first, or pass --force." >&2
  exit 1
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
TARGET="$PROFILE/chrome"
OVERRIDES=""

# ── Back up the existing chrome folder ──────────────────────────────
if [[ -d "$TARGET" ]]; then
  BACKUP="$PROFILE/chrome.backup-$STAMP"
  mv "$TARGET" "$BACKUP"
  echo "Backed up existing chrome folder to: $BACKUP"
  [[ -f "$BACKUP/user-overrides.css" ]] && OVERRIDES="$BACKUP/user-overrides.css"
fi

# ── Copy the theme ──────────────────────────────────────────────────
cp -R "$REPO_DIR/chrome" "$TARGET"
if [[ -n "$OVERRIDES" ]]; then
  cp "$OVERRIDES" "$TARGET/user-overrides.css"
  echo "Kept your user-overrides.css"
fi
echo "installed $(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$TARGET/$MARKER"

if ! ls "$TARGET/fonts/"*.ttf >/dev/null 2>&1; then
  echo "Note: no font files in chrome/fonts. Run scripts/fetch-fonts.sh for Plus Jakarta Sans,"
  echo "      otherwise the theme uses your system font."
fi

# ── Enable userChrome.css ───────────────────────────────────────────
USERJS="$PROFILE/user.js"
if [[ -f "$USERJS" ]] && grep -qF 'toolkit.legacyUserProfileCustomizations.stylesheets' "$USERJS"; then
  if ! grep -qF "$PREF" "$USERJS"; then
    echo "user.js already sets toolkit.legacyUserProfileCustomizations.stylesheets."
    echo "Make sure it is set to true, or the theme will not load."
  fi
else
  [[ -f "$USERJS" ]] && cp "$USERJS" "$USERJS.backup-$STAMP"
  printf '\n// Added by Plume for Betterbird\n%s\n' "$PREF" >> "$USERJS"
  echo "Enabled userChrome.css in user.js"
fi

echo "Done. Start Betterbird to see the theme."
