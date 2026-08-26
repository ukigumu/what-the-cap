import Foundation

// Renders the app's real mock dataset to design/preview/mock-data.js so the
// HTML design previews show exactly what the SwiftUI app shows.
// Run via design/preview/generate.sh.

struct ExportBar: Codable {
    let label: String
    let value: Int
    let isCurrent: Bool
}

struct ExportKey: Codable {
    let code: UInt16
    let legend: String
    let count: Int
}

struct ExportApp: Codable {
    let bundleID: String
    let count: Int
}

struct ExportRange: Codable {
    let label: String
    let total: Int
    let previous: Int
    let bars: [ExportBar]
    let topKeys: [ExportKey]
    let apps: [ExportApp]
    let keyCounts: [String: Int]
}

struct ExportKeyDef: Codable {
    let code: UInt16?
    let legend: String
    let sub: String?
    let width: Double
    let control: Bool
}

struct ExportLayout: Codable {
    let id: String
    let name: String
    let rows: [[ExportKeyDef]]
}

struct ExportRoot: Codable {
    let dateLabel: String
    let ranges: [String: ExportRange]
    let layouts: [ExportLayout]
    let csvHead: String
}

let store = MockKeystrokeStore()

func exportRange(_ range: StatsRange) -> ExportRange {
    let total = store.total(for: range)
    return ExportRange(
        label: range.label,
        total: total,
        previous: store.previousTotal(for: range),
        bars: store.bars(for: range).map { ExportBar(label: $0.label, value: $0.value, isCurrent: $0.isCurrent) },
        topKeys: store.topKeys(for: range, limit: 8).map {
            ExportKey(code: $0.keyCode, legend: KeyboardLayout.isoSpanish.legend(for: $0.keyCode), count: $0.count)
        },
        apps: store.appCounts(for: range).map { ExportApp(bundleID: $0.bundleID, count: $0.count) },
        keyCounts: Dictionary(uniqueKeysWithValues: store.keyCounts(for: range).map { (String($0.key), $0.value) })
    )
}

func exportLayout(_ layout: KeyboardLayout) -> ExportLayout {
    ExportLayout(
        id: layout.id,
        name: layout.name,
        rows: layout.rows.map { row in
            row.map {
                ExportKeyDef(code: $0.code, legend: $0.legend, sub: $0.sublegend, width: Double($0.width), control: $0.isControl)
            }
        }
    )
}

let formatter = DateFormatter()
formatter.locale = Locale(identifier: "en_US")
formatter.dateFormat = "EEEE, MMMM d"

let root = ExportRoot(
    dateLabel: formatter.string(from: .now),
    ranges: [
        "today": exportRange(.today),
        "week": exportRange(.week),
        "month": exportRange(.month),
    ],
    layouts: [exportLayout(.isoSpanish), exportLayout(.ansi)],
    csvHead: store.csv(for: .month).split(separator: "\n").prefix(6).joined(separator: "\n")
)

let encoder = JSONEncoder()
encoder.outputFormatting = [.sortedKeys]
let json = String(decoding: try encoder.encode(root), as: UTF8.self)
print("window.WTC = " + json + ";")
