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
    let store = PersistentStore.applicationDefault()

    /// What the UI shows. Demo override wins so Settings can still preview
    /// banners without fighting the live poller.
    var captureState: CaptureState = .permissionDenied
    var demoOverride: CaptureState?
    var selectedScreen: Screen = .overview
    var selectedRange: StatsRange = .today
    var keyboardLayout: KeyboardLayout = .isoSpanish

    var launchAtLogin = false {
        didSet {
            #if os(macOS)
            LoginItem.setEnabled(launchAtLogin)
            #endif
        }
    }

    var hasCompletedOnboarding = false {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.onboarding) }
    }

    var isTrusted = false

    var hasData: Bool { store.hasData }

    private var pausedByUser = false {
        didSet { UserDefaults.standard.set(pausedByUser, forKey: Keys.paused) }
    }

    private var liveState: CaptureState = .permissionDenied

    #if os(macOS)
    @ObservationIgnored private var tap = EventTap()
    #endif
    @ObservationIgnored private var poller: Timer?

    private enum Keys {
        static let onboarding = "wtc.hasCompletedOnboarding"
        static let paused = "wtc.pausedByUser"
    }

    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Keys.onboarding)
        pausedByUser = UserDefaults.standard.bool(forKey: Keys.paused)
        #if os(macOS)
        launchAtLogin = LoginItem.isEnabled
        tap.onKeyDown = { [weak self] code in
            self?.record(code)
        }
        tap.shouldRecord = { [weak self] in
            self?.liveState.isCounting == true
        }
        #endif
        refreshLiveState()
        startPolling()
    }

    func togglePause() {
        switch displayedPauseSource {
        case .active, .pausedByUser:
            pausedByUser.toggle()
            refreshLiveState()
        case .secureInput, .permissionDenied:
            break
        }
    }

    func resetCounts() {
        store.reset()
    }

    func restoreDemoData() {
        store.restoreDemoData()
    }

    func setDemoOverride(_ state: CaptureState) {
        demoOverride = state == liveState ? nil : state
        applyDisplay()
    }

    func clearDemoOverride() {
        demoOverride = nil
        applyDisplay()
    }

    func requestAccessibility() {
        #if os(macOS)
        SystemState.promptTrust()
        #endif
        refreshLiveState()
    }

    func openAccessibilitySettings() {
        #if os(macOS)
        SystemState.openAccessibilitySettings()
        #endif
    }

    func finishOnboarding() {
        hasCompletedOnboarding = true
        requestAccessibility()
    }

    // MARK: - Live state

    private var displayedPauseSource: CaptureState { demoOverride ?? liveState }

    private func record(_ keyCode: UInt16) {
        guard liveState.isCounting else { return }
        #if os(macOS)
        let bundleID = SystemState.frontmostBundleID
        #else
        let bundleID = "unknown"
        #endif
        store.record(KeyDown(keyCode: keyCode, bundleID: bundleID, at: .now))
    }

    private func refreshLiveState() {
        #if os(macOS)
        isTrusted = SystemState.isTrusted
        let secure = SystemState.isSecureInput
        #else
        isTrusted = true
        let secure = false
        #endif
        liveState = CaptureState.resolved(trusted: isTrusted, paused: pausedByUser, secure: secure)
        applyDisplay()
        #if os(macOS)
        if liveState != .permissionDenied {
            if tap.start() == false {
                liveState = .permissionDenied
                isTrusted = false
                applyDisplay()
            }
        } else {
            tap.stop()
        }
        #endif
    }

    private func applyDisplay() {
        captureState = demoOverride ?? liveState
    }

    private func startPolling() {
        poller = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [weak self] _ in
            self?.refreshLiveState()
        }
        poller?.tolerance = 0.2
    }
}
