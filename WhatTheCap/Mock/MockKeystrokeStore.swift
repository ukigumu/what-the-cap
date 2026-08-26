import Foundation
import Observation

/// The boundary Grok wires the real, CGEvent-tap-backed store into later.
/// Every view reads counts through this protocol and nothing else.
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

    func recordLiveTick()
    func reset()
}

/// One bar in the dashboard chart. Hours for Today, days for 7 and 30 days.
struct BarSample: Identifiable, Hashable {
    let label: String
    let value: Int
    let isCurrent: Bool

    var id: String { label }
}

/// Deterministic mock data: a fixed seed drives day totals with a weekday
/// rhythm, per-key counts with Spanish letter frequencies, and per-app counts
/// over realistic bundle identifiers. Counts only. No typed text exists
/// anywhere in this type.
@Observable
final class MockKeystrokeStore: KeystrokeStore {
    private struct MockDay {
        let date: Date
        var total: Int
        var keys: [UInt16: Int]
        var apps: [String: Int]
    }

    private var days: [MockDay] = []
    private var todayHourly: [Int] = []
    private var liveExtra = 0
    private var wasReset = false

    private let calendar = Calendar.current

    init() {
        regenerate()
    }

    var todayTotal: Int {
        (days.last?.total ?? 0) + liveExtra
    }

    var hasData: Bool { !wasReset }

    func total(for range: StatsRange) -> Int {
        days.suffix(range.dayCount).reduce(0) { $0 + $1.total } + liveExtra
    }

    /// The equivalent span immediately before the selected one, for deltas.
    func previousTotal(for range: StatsRange) -> Int {
        days.dropLast(range.dayCount).suffix(range.dayCount).reduce(0) { $0 + $1.total }
    }

    func bars(for range: StatsRange) -> [BarSample] {
        if range == .today {
            let hour = calendar.component(.hour, from: .now)
            return todayHourly.enumerated().map { index, value in
                BarSample(label: String(format: "%02d", index), value: index <= hour ? value : 0, isCurrent: index == hour)
            }
        }
        let formatter = DateFormatter()
        formatter.dateFormat = range == .week ? "EEE" : "d"
        return days.suffix(range.dayCount).enumerated().map { index, day in
            BarSample(
                label: formatter.string(from: day.date),
                value: day.total,
                isCurrent: index == range.dayCount - 1
            )
        }
    }

    func keyCounts(for range: StatsRange) -> [UInt16: Int] {
        days.suffix(range.dayCount).reduce(into: [:]) { acc, day in
            acc.merge(day.keys, uniquingKeysWith: +)
        }
    }

    func topKeys(for range: StatsRange, limit: Int) -> [KeyCount] {
        keyCounts(for: range)
            .map { KeyCount(keyCode: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(limit)
            .map { $0 }
    }

    func appCounts(for range: StatsRange) -> [AppCount] {
        days.suffix(range.dayCount)
            .reduce(into: [:]) { acc, day in acc.merge(day.apps, uniquingKeysWith: +) }
            .map { AppCount(bundleID: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

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

    func recordLiveTick() {
        liveExtra += Int.random(in: 1...4)
    }

    func reset() {
        days = []
        todayHourly = []
        liveExtra = 0
        wasReset = true
    }

    func restoreDemoData() {
        wasReset = false
        liveExtra = 0
        regenerate()
    }

    // MARK: - Generation

    /// Spanish-text letter frequencies plus editing keys, keyed by macOS
    /// virtual key code. Weights are relative shares, not percentages.
    private static let keyWeights: [UInt16: Double] = [
        49: 16.0,  // space
        14: 11.7,  // e
        0: 10.5,   // a
        31: 7.4,   // o
        1: 6.8,    // s
        15: 5.9,   // r
        45: 5.7,   // n
        34: 5.3,   // i
        2: 5.0,    // d
        51: 4.6,   // delete, typo tax
        37: 4.2,   // l
        8: 4.0,    // c
        17: 3.9,   // t
        32: 3.3,   // u
        56: 3.0,   // left shift
        46: 2.7,   // m
        35: 2.1,   // p
        55: 1.6,   // command
        36: 1.4,   // return
        11: 1.2,   // b
        5: 0.9,    // g
        9: 0.8,    // v
        16: 0.8,   // y
        12: 0.8,   // q
        4: 0.6,    // h
        3: 0.6,    // f
        43: 0.6,   // comma
        47: 0.6,   // period
        6: 0.4,    // z
        38: 0.4,   // j
        48: 0.4,   // tab
        41: 0.3,   // ñ
        7: 0.2,    // x
        18: 0.2, 19: 0.2, 20: 0.2, 21: 0.15, 23: 0.15,
        22: 0.15, 26: 0.15, 28: 0.15, 25: 0.15, 29: 0.2,
        40: 0.1,   // k
        13: 0.1,   // w
        60: 0.9,   // right shift
        58: 0.7,   // option
        44: 0.3,   // minus
    ]

    private static let appWeights: [String: Double] = [
        "com.apple.dt.Xcode": 9.5,
        "com.googlecode.iterm2": 6.8,
        "com.tinyspeck.slackmacgap": 4.9,
        "com.apple.Safari": 3.6,
        "com.figma.Desktop": 2.2,
        "com.apple.mail": 1.9,
        "md.obsidian": 1.6,
        "com.apple.Notes": 0.9,
        "org.mozilla.firefox": 0.7,
        "com.spotify.client": 0.3,
    ]

    /// Work-hours curve: quiet mornings, two humps, a lunch dip.
    private static let hourWeights: [Double] = [
        0.1, 0, 0, 0, 0, 0, 0.2, 0.8, 2.4, 5.8, 8.2, 8.9,
        4.1, 3.0, 6.9, 8.6, 8.0, 6.4, 3.1, 1.4, 1.8, 2.2, 0.9, 0.3,
    ]

    private func regenerate() {
        var rng = SplitMix64(seed: 0xCA9)
        let today = calendar.startOfDay(for: .now)
        let hourNow = calendar.component(.hour, from: .now)

        days = (0..<30).reversed().compactMap { back in
            guard let date = calendar.date(byAdding: .day, value: -back, to: today) else { return nil }
            let weekday = calendar.component(.weekday, from: date)
            let isWeekend = weekday == 1 || weekday == 7
            var total = isWeekend
                ? Int.random(in: 3_800...11_200, using: &rng)
                : Int.random(in: 17_500...34_800, using: &rng)
            if back == 0 {
                let dayFraction = Self.hourWeights.prefix(hourNow + 1).reduce(0, +)
                    / Self.hourWeights.reduce(0, +)
                total = Int(Double(total) * dayFraction)
            }
            return MockDay(
                date: date,
                total: total,
                keys: Self.distribute(total, over: Self.keyWeights, using: &rng),
                apps: Self.distribute(total, over: Self.appWeights, using: &rng)
            )
        }

        let todayCount = days.last?.total ?? 0
        todayHourly = Self.hourWeights.prefix(hourNow + 1).map { $0 }
            .normalized(to: todayCount, using: &rng)
            + Array(repeating: 0, count: 23 - hourNow)
    }

    private static func distribute<Key>(
        _ total: Int,
        over weights: [Key: Double],
        using rng: inout SplitMix64
    ) -> [Key: Int] {
        let weightSum = weights.values.reduce(0, +)
        return weights.mapValues { weight in
            let jitter = Double.random(in: 0.82...1.18, using: &rng)
            return max(0, Int(Double(total) * weight / weightSum * jitter))
        }
    }
}

/// Deterministic 64-bit generator so every launch shows the same mock data.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

private extension Collection where Element == Double {
    /// Scales weights into integers that sum close to `total`, with jitter.
    func normalized(to total: Int, using rng: inout SplitMix64) -> [Int] {
        let sum = reduce(0, +)
        guard sum > 0 else { return map { _ in 0 } }
        return map { weight in
            let jitter = Double.random(in: 0.88...1.12, using: &rng)
            return Swift.max(0, Int(Double(total) * weight / sum * jitter))
        }
    }
}
