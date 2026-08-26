#!/usr/bin/env bash
# Verifies the project as far as the host platform allows.
# macOS with Xcode: full app build, plus the domain checks.
# Linux or bare Swift toolchain: domain and SQLite checks only (SwiftUI and
# the CGEvent tap need macOS).
# Override the compiler with SWIFTC=/path/to/swiftc.
set -euo pipefail
cd "$(dirname "$0")"
swiftc="${SWIFTC:-swiftc}"

if [ "$(uname)" = "Darwin" ] && command -v xcodebuild >/dev/null; then
	echo "== xcodebuild =="
	xcodebuild -project WhatTheCap.xcodeproj -scheme WhatTheCap \
		-configuration Debug -derivedDataPath /tmp/wtc-derived build | tail -3
fi

echo "== domain and sqlite checks =="
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
if [ "$(uname)" != "Darwin" ]; then
	set -- -I verify/sqlite
else
	set --
fi
"$swiftc" "$@" -lsqlite3 -o "$tmp/checks" \
	WhatTheCap/Models/*.swift \
	WhatTheCap/Mock/*.swift \
	WhatTheCap/Store/*.swift \
	verify/main.swift
"$tmp/checks"

echo "== syntax (all files) =="
"$swiftc" -parse WhatTheCap/*.swift WhatTheCap/Models/*.swift WhatTheCap/Mock/*.swift \
	WhatTheCap/DesignSystem/*.swift WhatTheCap/Views/*.swift \
	WhatTheCap/Store/*.swift WhatTheCap/Engine/*.swift
echo "ok"
