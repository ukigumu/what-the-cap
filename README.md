# What the cap (WTC)

Native macOS menu-bar app that counts keystrokes. Counts only. Never stores typed text.

Runnable SwiftUI Mac app. The UI from the design pass is unchanged. This pass wires the real engine behind `KeystrokeStore` and `CaptureState`.

## Requirements

- macOS 14+
- Xcode 16+ (for `xcodebuild` / Run)
- **Input Monitoring** permission (not Accessibility)

## Run it

`make` (or `make init`) checks the toolchain and verifies the project. `make run` builds and launches the app. `make help` lists the other targets.

| Target | What it does |
| --- | --- |
| `make` / `make init` | `check` + `verify` (default) |
| `make check` | Ensure `swiftc` / `xcodebuild` exist |
| `make build` | Debug build via `xcodebuild` into `build/` |
| `make run` | Build and launch the app |
| `make install` | Release build and copy to `/Applications/WhatTheCap.app` |
| `make verify` | Run `./verify.sh` |
| `make preview` | Regenerate design preview data and screenshots |
| `make clean` | Remove local build artifacts |
| `make help` | List targets |

Open `WhatTheCap.xcodeproj` in Xcode 16 or newer and press Run. The app opens the main window, puts today's count in the menu bar, and shows Input Monitoring onboarding on first launch. Grant Input Monitoring, then type. Counts land in `~/Library/Application Support/WhatTheCap/counts.sqlite`.

`./verify.sh` (also `make verify`) builds the app on macOS and runs the domain plus SQLite checks. On Linux it runs those checks alone. SwiftUI, the CGEvent tap, Input Monitoring, and login items need a Mac.

## Features

- **Overview** - today (hourly bars, top keys), 7-day, and 30-day ranges
- **Heatmap** - ISO Spanish and ANSI layouts (virtual key codes only)
- **Per app** - tallies by frontmost bundle identifier (no window titles)
- **Settings**
  - Launch at login via `SMAppService.mainApp`
  - Pause / resume counting
  - Export counts as CSV (key code, legend, count; no typed text)
  - Reset all counts
  - Restore mock / demo data into the same SQLite file
  - Design demo override for `CaptureState` banners (display only; live capture still follows trust, pause, and secure input)
- **Menu bar** - today's count plus a glyph driven by `CaptureState`
- **Onboarding** - Input Monitoring request on first launch

## Capture states

`CaptureState` is the single source of truth for banners, empty states, and the menu-bar glyph. Resolution order: no Input Monitoring, user pause, secure input, then active.

| State | Meaning |
| --- | --- |
| `active` | Counting key-down events |
| `pausedByUser` | You paused; nothing is recorded until resume |
| `secureInput` | Password / secure-input field focused; tap records nothing |
| `permissionDenied` | Input Monitoring missing; content blocked, permission UI shown |

## The privacy contract the UI is built around

- Counts are kept per key code. Key order is never stored, so words and passwords cannot be reconstructed.
- Per-app tallies carry the bundle identifier and a count. No window titles, no documents.
- Secure input (password fields) is a first-class paused state, not an edge case.
- Local only. No network path exists for key data.
- Visible app, menu bar presence, explicit Input Monitoring onboarding. No stealth.

## Screens

Images below are design renders: the HTML preview in `design/preview/` uses the app's own mock dataset (exported by `design/preview/generate.sh` from the Swift domain code) and the same design tokens as `Theme.swift`. They are not macOS screenshots; this repo's CI box is Linux. Fonts stand in for macOS: Inter for SF Pro, JetBrains Mono for SF Mono.

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

Linear-style product language, anchored on the app icon. Flat navy ground (RGB 22, 24, 36), cream ink and rounded cream bars, and one amber accent that marks only the hottest value in any chart. Geometric sans throughout (SF Pro, nothing bundled), mono reserved for key codes and bundle identifiers, hairline rules, no glow. The heatmap ramps from navy keycap through cream, and the single hottest key turns amber. The app icon repeats the system: three cream bars and one amber square on the same navy. Motion is numeric-text transitions on totals, spring bars, and staggered reveals.

## Engine

- `EventTap` is a listen-only `CGEvent` session tap for key-down and modifier-down. It never swallows events, never reads unicode, and never touches the clipboard. Key repeat is ignored.
- Secure input is checked in the callback. If a password field is focused, the tap records nothing and `CaptureState` becomes `secureInput`.
- Input Monitoring is polled with `CGPreflightListenEventAccess`. Untrusted means `permissionDenied`, the tap is down, and the permission screen is shown. Onboarding calls `CGRequestListenEventAccess`.
- `PersistentStore` implements `KeystrokeStore`. The SQLite file has one table, `counts (day, hour, key_code, bundle_id, count)`. Increments only. No event log, so a sequence cannot be replayed.
- Per-app rows store the frontmost bundle identifier from `NSWorkspace`. No window titles.
- Launch at login uses `SMAppService.mainApp`.
- Settings still has a Design demo card. It overrides the displayed state only. Live capture keeps following trust, pause, and secure input.

`MockKeystrokeStore` remains for `verify.sh` and for Restore mock data, which writes the seeded dataset into the same SQLite file.

## Repo layout

```text
WhatTheCap/           SwiftUI app
  Engine/             EventTap, system state
  Store/              SQLite persistent counts
  Models/             CaptureState, layouts, stats, store protocol
  Views/              Overview, heatmap, apps, settings, onboarding, menu bar
  Mock/               Seeded dataset for verify + restore
  DesignSystem/       Theme and shared components
design/
  preview/            HTML preview + generate.sh
  screenshots/        Design renders linked above
  appicon/            App icon source
verify/               Domain + SQLite checks used by verify.sh
Makefile              Local build / run / install / verify
```
