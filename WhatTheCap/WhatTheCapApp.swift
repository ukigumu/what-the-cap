import SwiftUI

@main
struct WhatTheCapApp: App {
    @State private var model = AppModel()

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
}

/// Lives in the scene, so it reads the model directly instead of through
/// the environment, which does not reach MenuBarExtra labels.
struct MenuBarLabel: View {
    let model: AppModel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: model.captureState.menuBarSymbol)
            if model.captureState.isCounting && model.hasData {
                Text(model.store.todayTotal.compact)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .contentTransition(.numericText())
            }
        }
    }
}
