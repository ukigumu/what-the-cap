import SwiftUI

/// The menu bar dropdown: today's live tally, capture state, and the two
/// actions worth one click. Everything else lives in the main window.
struct MenuBarView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Wordmark(compact: true)
                    Spacer()
                    CaptureStateBadge(state: model.captureState)
                }
                if model.hasData && !model.captureState.blocksContent {
                    Text(model.store.todayTotal.grouped)
                        .font(Theme.displayNumber(40))
                        .foregroundStyle(Theme.ink)
                        .contentTransition(.numericText(value: Double(model.store.todayTotal)))
                        .animation(Theme.spring, value: model.store.todayTotal)
                    Text("keystrokes today")
                        .font(Theme.mono)
                        .foregroundStyle(Theme.inkDim)
                } else {
                    Text(model.captureState.blocksContent ? "—" : "0")
                        .font(Theme.displayNumber(40))
                        .foregroundStyle(Theme.inkFaint)
                    Text(model.captureState.blocksContent ? "permission needed" : "nothing counted yet")
                        .font(Theme.mono)
                        .foregroundStyle(Theme.inkFaint)
                }
            }
            .padding(16)

            Hairline()

            VStack(spacing: 2) {
                if model.captureState == .active || model.captureState == .pausedByUser {
                    MenuAction(
                        symbol: model.captureState.isCounting ? "pause.circle" : "play.circle",
                        title: model.captureState.isCounting ? "Pause counting" : "Resume counting"
                    ) {
                        withAnimation(Theme.spring) { model.togglePause() }
                    }
                }
                MenuAction(symbol: "rectangle.expand.vertical", title: "Open What the cap") {
                    openWindow(id: "main")
                    NSApp.activate(ignoringOtherApps: true)
                }
                MenuAction(symbol: "power", title: "Quit") {
                    NSApp.terminate(nil)
                }
            }
            .padding(8)
        }
        .frame(width: 260)
        .background(Theme.bg)
    }
}

private struct MenuAction: View {
    let symbol: String
    let title: String
    let action: () -> Void

    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 12))
                    .frame(width: 16)
                Text(title)
                    .font(.system(size: 13))
                Spacer()
            }
            .foregroundStyle(hovered ? Theme.ink : Theme.inkDim)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(hovered ? Theme.bgRaised : Color.clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }
}
