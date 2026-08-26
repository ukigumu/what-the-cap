#if os(macOS)
import AppKit
import Carbon
import CoreGraphics
import ServiceManagement

/// macOS facts the engine reads. Bundle id only. Never a window title.
enum SystemState {
    /// Listen-only `CGEvent` taps need Input Monitoring, not Accessibility.
    static var isTrusted: Bool {
        CGPreflightListenEventAccess()
    }

    static var isSecureInput: Bool {
        IsSecureEventInputEnabled()
    }

    static var frontmostBundleID: String {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "unknown"
    }

    @discardableResult
    static func promptTrust() -> Bool {
        CGRequestListenEventAccess()
    }

    static func openInputMonitoringSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ListenEvent",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent",
        ]
        for candidate in candidates {
            if let url = URL(string: candidate), NSWorkspace.shared.open(url) {
                return
            }
        }
    }
}

enum LoginItem {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
        }
    }
}
#endif
