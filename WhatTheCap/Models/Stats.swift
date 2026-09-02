import Foundation

enum StatsRange: String, CaseIterable, Identifiable {
    case today
    case week
    case month

    var id: String { rawValue }

    var label: String {
        switch self {
        case .today: "Today"
        case .week: "7 days"
        case .month: "30 days"
        }
    }

    var dayCount: Int {
        switch self {
        case .today: 1
        case .week: 7
        case .month: 30
        }
    }
}

struct DayCount: Identifiable, Hashable {
    let date: Date
    let total: Int

    var id: Date { date }
}

struct KeyCount: Identifiable, Hashable {
    let keyCode: UInt16
    let count: Int

    var id: UInt16 { keyCode }
}

/// Per-app tallies carry the bundle identifier and nothing else.
/// No window titles, no document names, no text.
struct AppCount: Identifiable, Hashable {
    let bundleID: String
    let count: Int

    var id: String { bundleID }
}
