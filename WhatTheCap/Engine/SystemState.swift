#if os(macOS)
import AppKit
import ApplicationServices
import Carbon
import ServiceManagement

/// macOS facts the engine reads. Bundle id only. Never a window title.
enum SystemState {
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    static var isSecureInput: Bool {
        IsSecureEventInputEnabled()
    }

    static var frontmostBundleID: String {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "unknown"
    }

    static func promptTrust() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
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
