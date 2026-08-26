# What the cap (WTC)

Native macOS menu-bar app that counts keystrokes. Counts only. Never stores typed text.

This branch is the design build: a runnable SwiftUI app in which every screen renders deterministic mock data. The capture engine (CGEvent tap, Accessibility integration, persistence) is not implemented yet; the UI is designed so it can be wired in behind one protocol.

## Run it

Open `WhatTheCap.xcodeproj` in Xcode 16 or newer and press Run. The app opens the main window, puts a live count in the menu bar, and shows onboarding on first launch. Requires macOS 14.

`./verify.sh` builds the app on macOS and runs the domain checks (layout widths, seeded-data determinism, CSV shape, reset behavior). On Linux it runs the domain checks alone, since SwiftUI needs macOS.

## The privacy contract the UI is built around

- Counts are kept per key code. Key order is never stored, so words and passwords cannot be reconstructed.
- Per-app tallies carry the bundle identifier and a count. No window titles, no documents.
- Secure input (password fields) is a first-class paused state, not an edge case.
- Local only. No network path exists for key data.
- Visible app, menu bar presence, explicit Accessibility onboarding. No stealth.

## Screens

Images below are design renders: the HTML preview in `design/preview/` uses the app's own mock dataset (exported by `design/preview/generate.sh` from the Swift domain code) and the same design tokens as `Theme.swift`. They are not macOS screenshots; this repo's CI box is Linux. Fonts stand in for macOS: Lora for New York, Inter for SF Pro, JetBrains Mono for SF Mono.

| Screen | Render |
| --- | --- |
| Overview, today (hourly bars, top keys) | ![Overview today](design/screenshots/overview-today.png) |
| Overview, 30 days (weekday rhythm) | ![Overview 30 days](design/screenshots/overview-30days.png) |
| Heatmap, ISO Spanish | ![Heatmap ISO Spanish](design/screenshots/heatmap-iso-spanish.png) |
| Heatmap, ANSI | ![Heatmap ANSI](design/screenshots/heatmap-ansi.png) |
| Per app (bundle ids only) | ![Per app](design/screenshots/per-app.png) |
| Settings | ![Settings](design/screenshots/settings.png) |
| Onboarding, permission step | ![Onboarding permission](design/screenshots/onboarding-permission.png) |
| Menu bar extra | ![Menu bar](design/screenshots/menubar.png) |
| Paused | ![Paused](design/screenshots/state-paused.png) |
| Permission denied | ![Permission denied](design/screenshots/state-permission-denied.png) |

More in `design/screenshots/`: 7-day range, both remaining onboarding steps, empty, and secure-input.

## Design language

A counting app drawn like a counting-house ledger. Warm obsidian ground, bone ink, one ember accent, oversized serif numerals (New York via `fontDesign(.serif)`, so nothing is bundled), SF Mono key legends, hairline rules. The heatmap ramps from cold keycap through ember to near-white. Motion is numeric-text transitions on totals, spring bars, and staggered reveals.

## Where the real engine plugs in

- `KeystrokeStore` (in `WhatTheCap/Mock/MockKeystrokeStore.swift`) is the whole read surface the UI uses. Implement it against the event tap and persistence, then swap it in `AppModel`.
- `CaptureState` is the state machine the tap drives: `active`, `pausedByUser`, `secureInput`, `permissionDenied`. Every banner, blocked screen, and menu bar glyph derives from it.
- The ticker in `AppModel` fakes the live menu-bar count and gets deleted with the swap.
- Settings has a "Design demo" card for flipping states and restoring mock data; it goes away with the real engine.
