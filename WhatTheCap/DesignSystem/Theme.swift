import SwiftUI

/// The Linear-style design language: flat navy ground anchored on the app
/// icon's RGB(22, 24, 36), cream ink and bars, one amber accent reserved
/// for the hottest value, geometric sans throughout, hairline rules.
enum Theme {
    // MARK: Ground

    static let bg = Color(hex: 0x161824)
    static let bgRaised = Color(hex: 0x1C1F2E)
    static let bgInset = Color(hex: 0x111320)
    static let keycap = Color(hex: 0x212436)
    static let hairline = Color.white.opacity(0.06)
    static let hairlineStrong = Color.white.opacity(0.12)

    // MARK: Ink

    static let ink = Color(hex: 0xF7F3EA)
    static let inkDim = Color(hex: 0xA3A8BA)
    static let inkFaint = Color(hex: 0x646A80)

    // MARK: Accent

    static let amber = Color(hex: 0xECA626)
    static let amberSoft = Color(hex: 0xECA626).opacity(0.14)
    static let creamBar = Color(hex: 0xF7F3EA).opacity(0.88)
    static let creamBarDim = Color(hex: 0xF7F3EA).opacity(0.32)
    static let danger = Color(hex: 0xE5484D)
    static let calm = Color(hex: 0x6E9BD8)

    // MARK: Type

    static func displayNumber(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold)
    }

    static let displayTitle = Font.system(size: 24, weight: .semibold)
    static let sectionLabel = Font.system(size: 11, weight: .semibold)
    static let body = Font.system(size: 13, weight: .regular)
    static let caption = Font.system(size: 11, weight: .regular)
    static let mono = Font.system(size: 12, weight: .regular, design: .monospaced)
    static let keycapLegend = Font.system(size: 12, weight: .medium)

    // MARK: Metrics

    static let cornerLarge: CGFloat = 12
    static let cornerSmall: CGFloat = 6
    static let pagePadding: CGFloat = 32

    // MARK: Motion

    static let spring = Animation.spring(response: 0.45, dampingFraction: 0.82)
    static let slowSpring = Animation.spring(response: 0.7, dampingFraction: 0.85)

    /// Heat ramp for the keyboard map: navy keycap through cream. Amber is
    /// returned only at the very top of the ramp, so the single hottest
    /// value carries the accent and everything else stays cream.
    static func heat(_ intensity: Double) -> Color {
        let t = min(max(intensity, 0), 1)
        if t >= 1 { return amber }
        return Color.blend(keycap, ink, t)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    static func blend(_ a: Color, _ b: Color, _ t: Double) -> Color {
        let ca = NSColor(a).usingColorSpace(.sRGB) ?? .black
        let cb = NSColor(b).usingColorSpace(.sRGB) ?? .black
        let k = min(max(t, 0), 1)
        return Color(
            .sRGB,
            red: ca.redComponent + (cb.redComponent - ca.redComponent) * k,
            green: ca.greenComponent + (cb.greenComponent - ca.greenComponent) * k,
            blue: ca.blueComponent + (cb.blueComponent - ca.blueComponent) * k
        )
    }
}

extension Int {
    /// 12,408 style grouping, English UI.
    var grouped: String {
        formatted(.number.grouping(.automatic).locale(Locale(identifier: "en_US")))
    }

    /// 12.4k style for tight spots like the menu bar.
    var compact: String {
        formatted(.number.notation(.compactName).precision(.fractionLength(0...1)).locale(Locale(identifier: "en_US")))
    }
}
