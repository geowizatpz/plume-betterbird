#!/usr/bin/env bash
# Downloads the two open-source fonts the theme uses into chrome/fonts/.
# Source: github.com/google/fonts (SIL Open Font License 1.1).
# Run once before committing, so people who install the theme get the fonts.

set -euo pipefail

DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/chrome/fonts"
BASE="https://raw.githubusercontent.com/google/fonts/main/ofl"
mkdir -p "$DEST"

fetch() { echo "↓ $2"; curl -fsSL "$1" -o "$DEST/$2"; }

fetch "$BASE/plusjakartasans/PlusJakartaSans%5Bwght%5D.ttf" "PlusJakartaSans-Variable.ttf"
fetch "$BASE/plusjakartasans/OFL.txt"                       "OFL-PlusJakartaSans.txt"
fetch "$BASE/jetbrainsmono/JetBrainsMono%5Bwght%5D.ttf"     "JetBrainsMono-Variable.ttf"
fetch "$BASE/jetbrainsmono/OFL.txt"                         "OFL-JetBrainsMono.txt"

echo "Fonts saved to $DEST"
