import SwiftUI

struct DashboardView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        let range = model.selectedRange
        let total = model.store.total(for: range)

        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Overview")
                            .font(Theme.displayTitle)
                            .foregroundStyle(Theme.ink)
                        Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "en_US"))))
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.inkFaint)
                    }
                    Spacer()
                    RangePicker(selection: $model.selectedRange)
                }
                .reveal(0)

                heroTotal(total, range: range)
                    .reveal(1)

                Panel {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionLabel(range == .today ? "By hour" : "By day")
                        BarChart(samples: model.store.bars(for: range))
                            .frame(height: 148)
                            .animation(Theme.spring, value: range)
                    }
                }
                .reveal(2)

                Panel {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionLabel("Top keys")
                        TopKeysRow(
                            keys: model.store.topKeys(for: range, limit: 8),
                            layout: model.keyboardLayout,
                            rangeTotal: total
                        )
                    }
                }
                .reveal(3)
            }
            .padding(Theme.pagePadding)
        }
    }

    private func heroTotal(_ total: Int, range: StatsRange) -> some View {
        let previous = model.store.previousTotal(for: range)
        let delta = previous > 0 ? Double(total - previous) / Double(previous) : 0

        return VStack(alignment: .leading, spacing: 6) {
            Text(total.grouped)
                .font(Theme.displayNumber(76))
                .foregroundStyle(Theme.ink)
                .contentTransition(.numericText(value: Double(total)))
                .animation(.easeOut(duration: 0.12), value: total)
            HStack(spacing: 12) {
                Text("keystrokes · \(range.label.lowercased())")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkDim)
                if previous > 0 {
                    Text("\(delta >= 0 ? "▲" : "▼") \(abs(delta).formatted(.percent.precision(.fractionLength(0))))  vs previous \(range.dayCount == 1 ? "day" : "\(range.dayCount) days")")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(delta >= 0 ? Theme.ink : Theme.inkFaint)
                }
            }
        }
    }
}

// MARK: - Bar chart

struct BarChart: View {
    let samples: [BarSample]

    private var peak: Int { max(samples.map(\.value).max() ?? 1, 1) }

    var body: some View {
        GeometryReader { geo in
            let labelEvery = samples.count > 12 ? 5 : 1
            HStack(alignment: .bottom, spacing: samples.count > 12 ? 4 : 10) {
                ForEach(Array(samples.enumerated()), id: \.offset) { index, sample in
                    let isHot = sample.value == peak
                    VStack(spacing: 6) {
                        Spacer(minLength: 0)
                        Capsule(style: .continuous)
                            .fill(isHot ? Theme.amber : Theme.creamBar)
                            .frame(height: max(3, (geo.size.height - 24) * CGFloat(sample.value) / CGFloat(peak)))
                        Text(index % labelEvery == 0 ? sample.label : " ")
                            .font(.system(size: 9))
                            .foregroundStyle(sample.isCurrent ? Theme.ink : Theme.inkFaint)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .help("\(sample.value.grouped) keystrokes")
                }
            }
        }
    }
}

// MARK: - Top keys

struct TopKeysRow: View {
    let keys: [KeyCount]
    let layout: KeyboardLayout
    let rangeTotal: Int

    var body: some View {
        HStack(spacing: 14) {
            ForEach(Array(keys.enumerated()), id: \.element.id) { index, key in
                VStack(spacing: 8) {
                    Keycap(
                        legend: displayLegend(for: key.keyCode),
                        heat: 1 - Double(index) * 0.11,
                        width: 46,
                        height: 46
                    )
                    Text(key.count.compact)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.inkDim)
                    Text(share(of: key))
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.inkFaint)
                }
            }
            Spacer()
        }
    }

    private func displayLegend(for code: UInt16) -> String {
        code == 49 ? "␣" : layout.legend(for: code)
    }

    private func share(of key: KeyCount) -> String {
        guard rangeTotal > 0 else { return "" }
        return (Double(key.count) / Double(rangeTotal)).formatted(.percent.precision(.fractionLength(1)))
    }
}
