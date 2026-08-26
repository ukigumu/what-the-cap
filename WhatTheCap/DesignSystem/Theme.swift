import SwiftUI

/// The "ledger" design language: warm obsidian ground, bone ink, one ember
/// accent, serif display numerals, mono key legends, hairline rules.
enum Theme {
    // MARK: Ground

    static let bg = Color(hex: 0x0C0A07)
    static let bgRaised = Color(hex: 0x14110D)
    static let bgInset = Color(hex: 0x090705)
    static let keycap = Color(hex: 0x1A1712)
    static let hairline = Color.white.opacity(0.07)
    static let hairlineStrong = Color.white.opacity(0.14)

    // MARK: Ink

    static let ink = Color(hex: 0xEBE3D3)
    static let inkDim = Color(hex: 0x9C9382)
    static let inkFaint = Color(hex: 0x655E52)

    // MARK: Accent

    static let ember = Color(hex: 0xF2A33C)
    static let emberDeep = Color(hex: 0xB4651B)
    static let emberGlow = Color(hex: 0xF2A33C).opacity(0.16)
    static let danger = Color(hex: 0xE5484D)
    static let calm = Color(hex: 0x6FA8DC)

    // MARK: Type

    static func displayNumber(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .serif)
    }

    static let displayTitle = Font.system(size: 26, weight: .semibold, design: .serif)
    static let sectionLabel = Font.system(size: 11, weight: .medium, design: .monospaced)
    static let body = Font.system(size: 13, weight: .regular)
    static let caption = Font.system(size: 11, weight: .regular)
    static let mono = Font.system(size: 12, weight: .regular, design: .monospaced)
    static let keycapLegend = Font.system(size: 12, weight: .medium, design: .monospaced)

    // MARK: Metrics

    static let cornerLarge: CGFloat = 14
    static let cornerSmall: CGFloat = 6
    static let pagePadding: CGFloat = 32

    // MARK: Motion

    static let spring = Animation.spring(response: 0.45, dampingFraction: 0.82)
    static let slowSpring = Animation.spring(response: 0.7, dampingFraction: 0.85)

    /// Heat ramp for the keyboard map: cold keycap through ember to near-white.
    static func heat(_ intensity: Double) -> Color {
        let t = min(max(intensity, 0), 1)
        switch t {
        case 0:
            return keycap
        case ..<0.5:
            return Color.blend(keycap, emberDeep, t / 0.5)
        case ..<0.85:
            return Color.blend(emberDeep, ember, (t - 0.5) / 0.35)
        default:
            return Color.blend(ember, Color(hex: 0xFFE3B8), (t - 0.85) / 0.15)
        }
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
