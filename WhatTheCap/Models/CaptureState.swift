import Foundation

/// The single source of truth for whether WTC is counting.
/// Every banner, empty state, and menu-bar glyph derives from this machine.
/// The real event tap will drive transitions later; the design build sets it
/// directly from the demo controls in Settings.
enum CaptureState: String, CaseIterable, Identifiable, Codable {
    case active
    case pausedByUser
    case secureInput
    case permissionDenied

    var id: String { rawValue }

    var isCounting: Bool { self == .active }

    /// The whole content area is replaced, not just decorated with a banner.
    var blocksContent: Bool { self == .permissionDenied }

    var menuBarSymbol: String {
        switch self {
        case .active: "keyboard"
        case .pausedByUser: "pause.circle"
        case .secureInput: "lock.shield"
        case .permissionDenied: "keyboard.slash"
        }
    }

    var label: String {
        switch self {
        case .active: "Counting"
        case .pausedByUser: "Paused"
        case .secureInput: "Secure input"
        case .permissionDenied: "No permission"
        }
    }

    var detail: String {
        switch self {
        case .active:
            "Key-down events are tallied per key code."
        case .pausedByUser:
            "You paused counting. Nothing is recorded until you resume."
        case .secureInput:
            "A password field has secure input enabled. WTC pauses itself and records nothing."
        case .permissionDenied:
            "WTC needs the Accessibility permission to count keystrokes."
        }
    }
}
