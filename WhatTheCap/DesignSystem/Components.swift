import SwiftUI

// MARK: - Wordmark

struct Wordmark: View {
    var compact = false

    var body: some View {
        if compact {
            HStack(spacing: 6) {
                Text("WTC")
                    .font(.system(size: 17, weight: .bold))
                    .kerning(2)
                    .foregroundStyle(Theme.ink)
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Theme.amber)
                    .frame(width: 7, height: 7)
            }
        } else {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("WTC")
                        .font(.system(size: 28, weight: .bold))
                        .kerning(3)
                        .foregroundStyle(Theme.ink)
                    RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                        .fill(Theme.amber)
                        .frame(width: 9, height: 9)
                }
                Text("WHAT THE CAP")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Theme.inkDim)
                    .kerning(3.2)
            }
        }
    }
}

// MARK: - Text primitives

struct SectionLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text.uppercased())
            .font(Theme.sectionLabel)
            .kerning(1.4)
            .foregroundStyle(Theme.inkDim)
    }
}

struct Hairline: View {
    var body: some View {
        Rectangle()
            .fill(Theme.hairline)
            .frame(height: 1)
    }
}

// MARK: - Cards

struct Panel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous)
                    .fill(Theme.bgRaised)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous)
                            .strokeBorder(Theme.hairline, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Keycap

struct Keycap: View {
    let legend: String
    var sublegend: String?
    var heat: Double = 0
    var isControl = false
    var width: CGFloat = 44
    var height: CGFloat = 44

    var body: some View {
        let fill = Theme.heat(heat)
        let bright = heat > 0.55
        return ZStack {
            RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                .fill(fill)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                        .strokeBorder(heat > 0.05 ? Color.clear : Theme.hairlineStrong, lineWidth: 1)
                )

            VStack(spacing: 0) {
                if let sublegend {
                    Text(sublegend)
                        .font(.system(size: 8, weight: .regular))
                        .foregroundStyle(bright ? Theme.bg.opacity(0.6) : Theme.inkFaint)
                }
                Text(legend)
                    .font(Theme.keycapLegend)
                    .foregroundStyle(
                        bright ? Theme.bg : (isControl ? Theme.inkFaint : Theme.inkDim)
                    )
            }
        }
        .frame(width: width, height: height)
    }
}

// MARK: - Range picker

struct RangePicker: View {
    @Binding var selection: StatsRange
    @Namespace private var pill

    var body: some View {
        HStack(spacing: 2) {
            ForEach(StatsRange.allCases) { range in
                let isSelected = range == selection
                Text(range.label)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Theme.bg : Theme.inkDim)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background {
                        if isSelected {
                            Capsule().fill(Theme.amber)
                                .matchedGeometryEffect(id: "pill", in: pill)
                        }
                    }
                    .contentShape(Capsule())
                    .onTapGesture {
                        withAnimation(Theme.spring) { selection = range }
                    }
            }
        }
        .padding(3)
        .background(
            Capsule().fill(Theme.bgInset)
                .overlay(Capsule().strokeBorder(Theme.hairline, lineWidth: 1))
        )
    }
}

// MARK: - Buttons

struct AccentButtonStyle: ButtonStyle {
    var prominent = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(prominent ? Theme.bg : Theme.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(prominent ? Theme.amber : Theme.bgRaised)
                    .overlay(Capsule().strokeBorder(prominent ? Color.clear : Theme.hairlineStrong, lineWidth: 1))
            )
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Capture state badge

struct CaptureStateBadge: View {
    let state: CaptureState

    private var color: Color {
        switch state {
        case .active: Theme.amber
        case .pausedByUser: Theme.inkDim
        case .secureInput: Theme.calm
        case .permissionDenied: Theme.danger
        }
    }

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(state.label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .kerning(1.2)
                .foregroundStyle(Theme.inkDim)
        }
    }
}

// MARK: - Staggered reveal

struct Reveal: ViewModifier {
    let index: Int
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
            .onAppear {
                withAnimation(Theme.slowSpring.delay(Double(index) * 0.06)) {
                    shown = true
                }
            }
    }
}

extension View {
    func reveal(_ index: Int) -> some View {
        modifier(Reveal(index: index))
    }
}
