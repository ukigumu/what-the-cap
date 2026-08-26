#!/usr/bin/env bash
# Verifies the project as far as the host platform allows.
# macOS with Xcode: full app build, plus the domain checks.
# Linux or bare Swift toolchain: domain checks only (SwiftUI needs macOS).
# Override the compiler with SWIFTC=/path/to/swiftc.
set -euo pipefail
cd "$(dirname "$0")"
swiftc="${SWIFTC:-swiftc}"

if [ "$(uname)" = "Darwin" ] && command -v xcodebuild >/dev/null; then
	echo "== xcodebuild =="
	xcodebuild -project WhatTheCap.xcodeproj -scheme WhatTheCap \
		-configuration Debug -derivedDataPath /tmp/wtc-derived build | tail -3
fi

echo "== domain checks =="
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
"$swiftc" -o "$tmp/checks" WhatTheCap/Models/*.swift WhatTheCap/Mock/*.swift verify/main.swift
"$tmp/checks"

echo "== syntax (all files) =="
"$swiftc" -parse WhatTheCap/*.swift WhatTheCap/Models/*.swift WhatTheCap/Mock/*.swift \
	WhatTheCap/DesignSystem/*.swift WhatTheCap/Views/*.swift
echo "ok"
