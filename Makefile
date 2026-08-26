# Local development for What the cap.
# `make` or `make init` checks the toolchain and verifies the project.

PROJECT        := WhatTheCap.xcodeproj
SCHEME         := WhatTheCap
CONFIGURATION  ?= Debug
DERIVED        := build
APP            := $(DERIVED)/Build/Products/$(CONFIGURATION)/WhatTheCap.app

.DEFAULT_GOAL := init

.PHONY: init check build run verify preview clean help

help:
	@printf '%s\n' \
		'make init     check tools and verify the project (default)' \
		'make build    build the macOS app with xcodebuild' \
		'make run      build and launch the app' \
		'make verify   run ./verify.sh' \
		'make preview  regenerate design preview data and screenshots' \
		'make clean    remove local build artifacts'

init: check verify
	@echo "Local setup is ready. Launch with: make run"

check:
	@command -v swiftc >/dev/null || { echo "swiftc not found. Install Xcode or the Swift toolchain."; exit 1; }
	@if [ "$$(uname)" = Darwin ]; then \
		command -v xcodebuild >/dev/null || { echo "xcodebuild not found. Install Xcode."; exit 1; }; \
	fi
	@echo "toolchain ok ($$(swiftc --version | head -1))"

build: check
	@test "$$(uname)" = Darwin || { echo "Building the app requires macOS."; exit 1; }
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-configuration $(CONFIGURATION) -derivedDataPath $(DERIVED) build

run: build
	@-killall WhatTheCap 2>/dev/null || true
	@sleep 0.4
	open -n "$(APP)"

verify:
	./verify.sh

preview:
	./design/preview/generate.sh

clean:
	rm -rf $(DERIVED) /tmp/wtc-derived
