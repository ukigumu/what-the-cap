# Local development for What the cap.
# `make` or `make init` checks the toolchain and verifies the project.

PROJECT        := WhatTheCap.xcodeproj
SCHEME         := WhatTheCap
CONFIGURATION  ?= Debug
DERIVED        := build
APP            := $(DERIVED)/Build/Products/$(CONFIGURATION)/WhatTheCap.app
ICONSET        := WhatTheCap/Assets.xcassets/AppIcon.appiconset
LSREGISTER     := /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

.DEFAULT_GOAL := init

.PHONY: init check build stamp-icon run install verify preview clean help

help:
	@printf '%s\n' \
		'make init     check tools and verify the project (default)' \
		'make build    build the macOS app with xcodebuild' \
		'make run      build and launch the app' \
		'make install  build Release and copy to /Applications' \
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
	$(MAKE) stamp-icon

stamp-icon:
	@test -d "$(APP)" || { echo "build the app first"; exit 1; }
	@tmp="$$(mktemp -d)" && \
		mkdir "$$tmp/AppIcon.iconset" && \
		cp "$(ICONSET)"/icon_16x16.png "$(ICONSET)"/icon_16x16@2x.png \
			"$(ICONSET)"/icon_32x32.png "$(ICONSET)"/icon_32x32@2x.png \
			"$(ICONSET)"/icon_128x128.png "$(ICONSET)"/icon_128x128@2x.png \
			"$(ICONSET)"/icon_256x256.png "$(ICONSET)"/icon_256x256@2x.png \
			"$(ICONSET)"/icon_512x512.png "$(ICONSET)"/icon_512x512@2x.png \
			"$$tmp/AppIcon.iconset/" && \
		iconutil -c icns "$$tmp/AppIcon.iconset" -o "$(APP)/Contents/Resources/AppIcon.icns" && \
		rm -rf "$$tmp" && \
		identity="$$(codesign -dv --verbose=4 "$(APP)" 2>&1 | sed -n 's/^Authority=\(Apple Development:.*\)/\1/p' | head -1)" && \
		codesign --force --sign "$$identity" --timestamp=none --options runtime "$(APP)" && \
		touch "$(APP)" && \
		"$(LSREGISTER)" -f -R -trusted "$(APP)" >/dev/null
	@echo "stamped AppIcon.icns"

run: build
	@-killall WhatTheCap 2>/dev/null || true
	@sleep 0.4
	open -n "$(APP)"

install:
	$(MAKE) CONFIGURATION=Release build
	@-killall WhatTheCap 2>/dev/null || true
	@sleep 0.4
	rm -rf /Applications/WhatTheCap.app
	ditto "$(DERIVED)/Build/Products/Release/WhatTheCap.app" /Applications/WhatTheCap.app
	"$(LSREGISTER)" -f -R -trusted /Applications/WhatTheCap.app >/dev/null
	@echo "Installed /Applications/WhatTheCap.app"

verify:
	./verify.sh

preview:
	./design/preview/generate.sh

clean:
	rm -rf $(DERIVED) /tmp/wtc-derived
