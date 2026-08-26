import Foundation

/// The single source of truth for whether WTC is counting.
/// Every banner, empty state, and menu-bar glyph derives from this machine.
/// Live inputs resolve in this order: no Accessibility trust, user pause,
/// secure input, then active.
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

    /// Trust outranks pause, pause outranks secure input. The event tap
    /// records only when the result is `active`.
    static func resolved(trusted: Bool, paused: Bool, secure: Bool) -> CaptureState {
        if !trusted { return .permissionDenied }
        if paused { return .pausedByUser }
        if secure { return .secureInput }
        return .active
    }
}
