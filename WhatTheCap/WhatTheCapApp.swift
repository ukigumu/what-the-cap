import SwiftUI
#if os(macOS)
import AppKit
#endif

@main
struct WhatTheCapApp: App {
    @State private var model: AppModel

    init() {
        _model = State(initialValue: AppModel())
        #if os(macOS)
        Self.applyAppIcon()
        #endif
    }

    var body: some Scene {
        Window("What the cap", id: "main") {
            RootView()
                .environment(model)
                .frame(minWidth: 1020, minHeight: 680)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1120, height: 740)

        MenuBarExtra {
            MenuBarView()
                .environment(model)
        } label: {
            MenuBarLabel(model: model)
        }
        .menuBarExtraStyle(.window)
    }

    #if os(macOS)
    private static func applyAppIcon() {
        let bundled = Bundle.main.url(forResource: "AppIcon", withExtension: "icns")
            .flatMap { NSImage(contentsOf: $0) }
        if let image = NSImage(named: "AppIcon") ?? bundled {
            NSApplication.shared.applicationIconImage = image
        }
    }
    #endif
}

/// Lives in the scene, so it reads the model directly instead of through
/// the environment, which does not reach MenuBarExtra labels.
struct MenuBarLabel: View {
    let model: AppModel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: model.captureState.menuBarSymbol)
            if model.captureState.isCounting && model.hasData {
                Text(model.menuTotal.compact)
                    .font(.system(size: 12, weight: .medium))
                    .monospacedDigit()
            }
        }
    }
}
