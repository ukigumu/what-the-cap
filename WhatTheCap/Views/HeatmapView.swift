import SwiftUI

struct HeatmapView: View {
    @Environment(AppModel.self) private var model
    @State private var hoveredKey: KeyDef?

    var body: some View {
        @Bindable var model = model
        let counts = model.store.keyCounts(for: model.selectedRange)
        let peak = max(counts.values.max() ?? 1, 1)

        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Heatmap")
                            .font(Theme.displayTitle)
                            .foregroundStyle(Theme.ink)
                        Text("Per-key intensity · \(model.selectedRange.label.lowercased())")
                            .font(Theme.mono)
                            .foregroundStyle(Theme.inkFaint)
                    }
                    Spacer()
                    RangePicker(selection: $model.selectedRange)
                }
                .reveal(0)

                LayoutToggle(selection: $model.keyboardLayout)
                    .reveal(1)

                LedgerCard {
                    KeyboardMap(
                        layout: model.keyboardLayout,
                        counts: counts,
                        peak: peak,
                        hoveredKey: $hoveredKey
                    )
                    .padding(4)
                }
                .reveal(2)

                HStack(alignment: .center, spacing: 24) {
                    HeatLegend()
                    Spacer()
                    HoverReadout(key: hoveredKey, counts: counts, total: model.store.total(for: model.selectedRange))
                }
                .reveal(3)
            }
            .padding(Theme.pagePadding)
        }
    }
}

// MARK: - Layout toggle

struct LayoutToggle: View {
    @Binding var selection: KeyboardLayout

    var body: some View {
        HStack(spacing: 2) {
            ForEach(KeyboardLayout.all) { layout in
                let isSelected = layout == selection
                Text(layout.name)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular, design: .monospaced))
                    .foregroundStyle(isSelected ? Theme.ink : Theme.inkFaint)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Theme.bgRaised)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .strokeBorder(Theme.hairlineStrong, lineWidth: 1)
                                )
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(Theme.spring) { selection = layout }
                    }
            }
        }
    }
}

// MARK: - Keyboard map

struct KeyboardMap: View {
    let layout: KeyboardLayout
    let counts: [UInt16: Int]
    let peak: Int
    @Binding var hoveredKey: KeyDef?

    private let unitGap: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            let unitsPerRow: CGFloat = 15
            let unit = (geo.size.width - unitGap * (unitsPerRow - 1)) / unitsPerRow
            VStack(spacing: unitGap) {
                ForEach(Array(layout.rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: unitGap) {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, key in
                            keycap(for: key, unit: unit)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .aspectRatio(15 / 5.4, contentMode: .fit)
        .animation(Theme.spring, value: layout)
    }

    @ViewBuilder
    private func keycap(for key: KeyDef, unit: CGFloat) -> some View {
        let width = unit * key.width + unitGap * (key.width - 1)
        if let code = key.code {
            let intensity = pow(Double(counts[code] ?? 0) / Double(peak), 0.6)
            Keycap(
                legend: key.legend,
                sublegend: key.sublegend,
                heat: intensity,
                isControl: key.isControl,
                width: width,
                height: unit
            )
            .scaleEffect(hoveredKey == key ? 1.08 : 1)
            .animation(.easeOut(duration: 0.12), value: hoveredKey == key)
            .onHover { inside in
                hoveredKey = inside ? key : nil
            }
        } else {
            Color.clear.frame(width: width, height: unit)
        }
    }
}

// MARK: - Legend and readout

struct HeatLegend: View {
    var body: some View {
        HStack(spacing: 10) {
            Text("COLD")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .kerning(1.2)
                .foregroundStyle(Theme.inkFaint)
            LinearGradient(
                colors: [Theme.heat(0), Theme.heat(0.35), Theme.heat(0.7), Theme.heat(1)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 140, height: 6)
            .clipShape(Capsule())
            Text("HOT")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .kerning(1.2)
                .foregroundStyle(Theme.ember)
        }
    }
}

struct HoverReadout: View {
    let key: KeyDef?
    let counts: [UInt16: Int]
    let total: Int

    var body: some View {
        HStack(spacing: 12) {
            if let key, let code = key.code {
                let count = counts[code] ?? 0
                Text(key.legend.isEmpty ? "SPACE" : key.legend)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.ink)
                Text("key \(code)")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(Theme.inkFaint)
                Text(count.grouped)
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundStyle(Theme.ember)
                if total > 0 {
                    Text((Double(count) / Double(total)).formatted(.percent.precision(.fractionLength(1))))
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundStyle(Theme.inkDim)
                }
            } else {
                Text("Hover a key for its tally")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .frame(height: 20)
    }
}
