import SwiftUI
import Observation

enum Screen: String, CaseIterable, Identifiable {
    case overview
    case heatmap
    case apps
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: "Overview"
        case .heatmap: "Heatmap"
        case .apps: "Per app"
        case .settings: "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .overview: "chart.bar.fill"
        case .heatmap: "keyboard.fill"
        case .apps: "app.badge.checkmark"
        case .settings: "slider.horizontal.3"
        }
    }
}

@Observable
final class AppModel {
    let store = MockKeystrokeStore()

    var captureState: CaptureState = .active
    var selectedScreen: Screen = .overview
    var selectedRange: StatsRange = .today
    var keyboardLayout: KeyboardLayout = .isoSpanish

    var launchAtLogin = true
    var hasCompletedOnboarding = false

    @ObservationIgnored private var ticker: Timer?

    init() {
        startTicker()
    }

    var hasData: Bool { store.hasData }

    /// The mock heartbeat behind the live menu-bar count. The real event tap
    /// replaces this wholesale.
    private func startTicker() {
        ticker = Timer.scheduledTimer(withTimeInterval: 1.6, repeats: true) { [weak self] _ in
            guard let self, captureState.isCounting, hasData else { return }
            store.recordLiveTick()
        }
    }

    func togglePause() {
        switch captureState {
        case .active: captureState = .pausedByUser
        case .pausedByUser: captureState = .active
        case .secureInput, .permissionDenied: break
        }
    }

    func resetCounts() {
        store.reset()
    }

    func restoreDemoData() {
        store.restoreDemoData()
    }
}
