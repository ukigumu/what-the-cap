#!/usr/bin/env bash
# Regenerates mock-data.js from the app's real domain code, then screenshots
# every preview page with headless Chrome into design/screenshots/.
# Usage: design/preview/generate.sh [path-to-swiftc] [path-to-chrome]
set -euo pipefail

repo="$(cd "$(dirname "$0")/../.." && pwd)"
swiftc="${1:-swiftc}"
chrome="${2:-google-chrome}"
preview="$repo/design/preview"
shots="$repo/design/screenshots"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

"$swiftc" -O -o "$tmp/export" \
	"$repo"/WhatTheCap/Models/*.swift \
	"$repo"/WhatTheCap/Mock/*.swift \
	"$preview/export/main.swift"
"$tmp/export" > "$preview/mock-data.js"
echo "wrote $preview/mock-data.js"

command -v "$chrome" >/dev/null || { echo "chrome not found; skipping screenshots"; exit 0; }

# timeout guards against Chrome wrappers that keep the browser alive after
# the screenshot is written; the file check decides success.
shot() {
	local name="$1" query="$2" size="${3:-1120,740}"
	rm -f "$shots/$name.png"
	timeout 30 "$chrome" --headless=new --disable-gpu --hide-scrollbars \
		--no-sandbox --user-data-dir="$tmp/profile-$name" \
		--force-device-scale-factor=2 --window-size="$size" \
		--screenshot="$shots/$name.png" \
		"file://$preview/index.html?$query" >/dev/null 2>&1 || true
	[ -f "$shots/$name.png" ] && echo "shot $name" || { echo "FAILED $name"; exit 1; }
}

mkdir -p "$shots"
shot overview-today "screen=overview&range=today"
shot overview-7days "screen=overview&range=week"
shot overview-30days "screen=overview&range=month"
shot heatmap-iso-spanish "screen=heatmap&range=month&layout=iso-es"
shot heatmap-ansi "screen=heatmap&range=month&layout=ansi"
shot per-app "screen=apps&range=month"
shot settings "screen=settings"
shot onboarding-welcome "screen=onboarding&step=0"
shot onboarding-privacy "screen=onboarding&step=1"
shot onboarding-permission "screen=onboarding&step=2"
shot state-empty "screen=overview&state=empty"
shot state-paused "screen=overview&range=today&state=pausedByUser"
shot state-secure-input "screen=overview&range=today&state=secureInput"
shot state-permission-denied "screen=heatmap&state=permissionDenied"
shot menubar "screen=menubar" "520,420"
