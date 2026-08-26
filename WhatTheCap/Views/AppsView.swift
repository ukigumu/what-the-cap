import SwiftUI

struct AppsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        let apps = model.store.appCounts(for: model.selectedRange)
        let peak = max(apps.first?.count ?? 1, 1)
        let total = apps.reduce(0) { $0 + $1.count }

        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Per app")
                            .font(Theme.displayTitle)
                            .foregroundStyle(Theme.ink)
                        Text("Where the keystrokes landed · \(model.selectedRange.label.lowercased())")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.inkFaint)
                    }
                    Spacer()
                    RangePicker(selection: $model.selectedRange)
                }
                .reveal(0)

                Panel {
                    VStack(spacing: 0) {
                        ForEach(Array(apps.enumerated()), id: \.element.id) { index, app in
                            AppRow(rank: index + 1, app: app, peak: peak, total: total)
                                .reveal(index)
                            if index < apps.count - 1 {
                                Hairline()
                            }
                        }
                    }
                }
                .reveal(1)

                HStack(spacing: 8) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.inkFaint)
                    Text("WTC stores the bundle identifier and a count. Never window titles, documents, or text.")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.inkFaint)
                }
                .reveal(2)
            }
            .padding(Theme.pagePadding)
        }
    }
}

struct AppRow: View {
    let rank: Int
    let app: AppCount
    let peak: Int
    let total: Int

    var body: some View {
        HStack(spacing: 18) {
            Text("\(rank)")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(rank == 1 ? Theme.amber : Theme.inkFaint)
                .frame(width: 30, alignment: .trailing)

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text(app.bundleID)
                        .font(Theme.mono)
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text(app.count.grouped)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(share)
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.inkFaint)
                        .frame(width: 48, alignment: .trailing)
                }
                GeometryReader { geo in
                    Capsule()
                        .fill(rank == 1 ? Theme.amber : Theme.creamBar)
                        .frame(width: max(3, geo.size.width * CGFloat(app.count) / CGFloat(peak)), height: 4)
                }
                .frame(height: 4)
            }
        }
        .padding(.vertical, 13)
    }

    private var share: String {
        guard total > 0 else { return "" }
        return (Double(app.count) / Double(total)).formatted(.percent.precision(.fractionLength(1)))
    }
}
