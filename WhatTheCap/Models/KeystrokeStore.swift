import Foundation
import Observation

/// The only write the engine is allowed to make. A key code, a bundle id,
/// and a timestamp. No characters, no order beyond the aggregate count.
struct KeyDown: Equatable {
    let keyCode: UInt16
    let bundleID: String
    let at: Date
}

/// One bar in the dashboard chart. Hours for Today, days for 7 and 30 days.
struct BarSample: Identifiable, Hashable {
    let label: String
    let value: Int
    let isCurrent: Bool

    var id: String { label }
}

/// Seed row used only by restore-demo. Same shape as a stored increment.
struct CountSeed: Equatable {
    let day: Date
    let hour: Int
    let keyCode: UInt16
    let bundleID: String
    let count: Int
}

/// Every view reads counts through this protocol. The mock and the SQLite
/// store both implement it. The CGEvent tap only ever calls `record`.
protocol KeystrokeStore: AnyObject, Observable {
    var todayTotal: Int { get }
    var hasData: Bool { get }

    func total(for range: StatsRange) -> Int
    func previousTotal(for range: StatsRange) -> Int
    func bars(for range: StatsRange) -> [BarSample]
    func keyCounts(for range: StatsRange) -> [UInt16: Int]
    func topKeys(for range: StatsRange, limit: Int) -> [KeyCount]
    func appCounts(for range: StatsRange) -> [AppCount]
    func csv(for range: StatsRange) -> String

    func record(_ event: KeyDown)
    func reset()
    func restoreDemoData()
}

extension KeystrokeStore {
    func csv(for range: StatsRange) -> String {
        var lines = ["key_code,legend,count"]
        let counts = keyCounts(for: range).sorted { $0.value > $1.value }
        for (code, count) in counts {
            let legend = (code == 49 ? "space" : KeyboardLayout.isoSpanish.legend(for: code))
                .replacingOccurrences(of: "\"", with: "\"\"")
            lines.append("\(code),\"\(legend)\",\(count)")
        }
        return lines.joined(separator: "\n") + "\n"
    }

    func topKeys(for range: StatsRange, limit: Int) -> [KeyCount] {
        keyCounts(for: range)
            .map { KeyCount(keyCode: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(limit)
            .map { $0 }
    }
}
