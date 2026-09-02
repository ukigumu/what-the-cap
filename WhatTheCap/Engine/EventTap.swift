#if os(macOS)
import CoreGraphics

/// Listen-only session tap for key-down. Never swallows, never reads
/// unicode, never looks at the clipboard. Secure input is checked again
/// inside the callback so a race with the poller cannot record a password
/// field.
final class EventTap {
    var onKeyDown: ((UInt16) -> Void)?
    var shouldRecord: () -> Bool = { false }

    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var lastFlags: CGEventFlags = []

    func start() -> Bool {
        if tap != nil { return true }
        let mask =
            (1 as CGEventMask) << CGEventType.keyDown.rawValue
            | (1 as CGEventMask) << CGEventType.flagsChanged.rawValue
        let info = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: eventTapCallback,
            userInfo: info
        ) else {
            return false
        }
        self.tap = tap
        source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let source {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        tap = nil
        source = nil
    }

    deinit {
        stop()
    }

    fileprivate func ingest(type: CGEventType, event: CGEvent) {
        receive(type: type, event: event)
    }

    private func receive(type: CGEventType, event: CGEvent) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return
        }
        guard shouldRecord() else { return }
        guard !SystemState.isSecureInput else { return }

        if type == .keyDown {
            if event.getIntegerValueField(.keyboardEventAutorepeat) != 0 { return }
            let code = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
            onKeyDown?(code)
            return
        }

        if type == .flagsChanged {
            let flags = event.flags
            let code = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
            let wentDown = modifierWentDown(code: code, from: lastFlags, to: flags)
            lastFlags = flags
            if wentDown { onKeyDown?(code) }
        }
    }

    private func modifierWentDown(code: UInt16, from old: CGEventFlags, to new: CGEventFlags) -> Bool {
        let flag: CGEventFlags
        switch code {
        case 56, 60: flag = .maskShift
        case 55, 54: flag = .maskCommand
        case 58, 61: flag = .maskAlternate
        case 59, 62: flag = .maskControl
        case 63: flag = .maskSecondaryFn
        case 57: flag = .maskAlphaShift
        default: return false
        }
        return !old.contains(flag) && new.contains(flag)
    }
}

private func eventTapCallback(
    _ proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon else { return Unmanaged.passUnretained(event) }
    Unmanaged<EventTap>.fromOpaque(refcon).takeUnretainedValue().ingest(type: type, event: event)
    return Unmanaged.passUnretained(event)
}
#endif
