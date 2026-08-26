import Foundation
import Observation

@Observable
final class PersistentStore: KeystrokeStore {
    private struct DayBucket {
        var date: Date
        var hourly: [Int]
        var keys: [UInt16: Int]
        var apps: [String: Int]
        var total: Int

        init(date: Date) {
            self.date = date
            hourly = Array(repeating: 0, count: 24)
            keys = [:]
            apps = [:]
            total = 0
        }
    }

    private let database: CountDatabase
    private let calendar = Calendar.current
    private let queue = DispatchQueue(label: "software.grumpy.whatthecap.store")
    private var buckets: [String: DayBucket] = [:]
    private let dayFormatter: DateFormatter

    private(set) var todayTotal = 0
    private(set) var hasData = false
    private(set) var revision = 0

    init(fileURL: URL) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = Calendar.current.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        dayFormatter = formatter
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            database = try CountDatabase(path: fileURL.path)
        } catch {
            fatalError("WTC could not open \(fileURL.path): \(error)")
        }
        loadCache()
    }

    static func applicationDefault() -> PersistentStore {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let dir = root.appendingPathComponent("WhatTheCap", isDirectory: true)
        return PersistentStore(fileURL: dir.appendingPathComponent("counts.sqlite"))
    }

    func total(for range: StatsRange) -> Int {
        _ = revision
        return queue.sync {
            dayKeys(for: range, offset: 0).reduce(0) { $0 + (buckets[$1]?.total ?? 0) }
        }
    }

    func previousTotal(for range: StatsRange) -> Int {
        _ = revision
        return queue.sync {
            dayKeys(for: range, offset: range.dayCount).reduce(0) { $0 + (buckets[$1]?.total ?? 0) }
        }
    }

    func bars(for range: StatsRange) -> [BarSample] {
        _ = revision
        return queue.sync {
            if range == .today {
                let key = dayKey(for: 0)
                let hourly = buckets[key]?.hourly ?? Array(repeating: 0, count: 24)
                let hourNow = calendar.component(.hour, from: .now)
                return hourly.enumerated().map { index, value in
                    BarSample(label: String(format: "%02d", index), value: value, isCurrent: index == hourNow)
                }
            }
            let formatter = DateFormatter()
            formatter.dateFormat = range == .week ? "EEE" : "d"
            let keys = dayKeys(for: range, offset: 0)
            return keys.enumerated().map { index, key in
                let date = buckets[key]?.date ?? dateForDayKey(key)
                return BarSample(
                    label: formatter.string(from: date),
                    value: buckets[key]?.total ?? 0,
                    isCurrent: index == keys.count - 1
                )
            }
        }
    }

    func keyCounts(for range: StatsRange) -> [UInt16: Int] {
        _ = revision
        return queue.sync {
            dayKeys(for: range, offset: 0).reduce(into: [:]) { acc, key in
                acc.merge(buckets[key]?.keys ?? [:], uniquingKeysWith: +)
            }
        }
    }

    func appCounts(for range: StatsRange) -> [AppCount] {
        _ = revision
        return queue.sync {
            dayKeys(for: range, offset: 0)
                .reduce(into: [:]) { acc, key in
                    acc.merge(buckets[key]?.apps ?? [:], uniquingKeysWith: +)
                }
                .map { AppCount(bundleID: $0.key, count: $0.value) }
                .sorted { $0.count > $1.count }
        }
    }

    func record(_ event: KeyDown) {
        queue.async { [weak self] in
            self?.increment(event, by: 1)
        }
    }

    func reset() {
        queue.sync {
            try? database.reset()
            buckets = [:]
        }
        publish()
    }

    func restoreDemoData() {
        let seeds = MockKeystrokeStore().seedRows()
        queue.sync {
            try? database.reset()
            buckets = [:]
            for seed in seeds {
                let event = KeyDown(keyCode: seed.keyCode, bundleID: seed.bundleID, at: seedDate(seed))
                increment(event, by: seed.count, publishAfter: false)
            }
        }
        publish()
    }

    func schemaColumnNames() throws -> [String] {
        try queue.sync { try database.columnNames() }
    }

    func schemaTableNames() throws -> [String] {
        try queue.sync { try database.tableNames() }
    }

    // MARK: - Internals

    private func loadCache() {
        queue.sync {
            guard let rows = try? database.allRows() else { return }
            for row in rows {
                apply(day: row.day, hour: row.hour, keyCode: row.keyCode, bundleID: row.bundleID, count: row.count)
            }
        }
        publish()
    }

    private func increment(_ event: KeyDown, by count: Int, publishAfter: Bool = true) {
        let day = dayFormatter.string(from: calendar.startOfDay(for: event.at))
        let hour = calendar.component(.hour, from: event.at)
        try? database.increment(day: day, hour: hour, keyCode: event.keyCode, bundleID: event.bundleID, by: count)
        apply(day: day, hour: hour, keyCode: event.keyCode, bundleID: event.bundleID, count: count)
        if publishAfter { publish() }
    }

    private func apply(day: String, hour: Int, keyCode: UInt16, bundleID: String, count: Int) {
        var bucket = buckets[day] ?? DayBucket(date: dateForDayKey(day))
        if hour >= 0 && hour < 24 {
            bucket.hourly[hour] += count
        }
        bucket.keys[keyCode, default: 0] += count
        bucket.apps[bundleID, default: 0] += count
        bucket.total += count
        buckets[day] = bucket
    }

    private func publish() {
        let total = buckets[dayKey(for: 0)]?.total ?? 0
        let any = buckets.contains { $0.value.total > 0 }
        let apply = {
            self.todayTotal = total
            self.hasData = any
            self.revision += 1
        }
        if Thread.isMainThread {
            apply()
        } else {
            DispatchQueue.main.async(execute: apply)
        }
    }

    private func dayKey(for offsetBack: Int) -> String {
        let today = calendar.startOfDay(for: .now)
        let date = calendar.date(byAdding: .day, value: -offsetBack, to: today) ?? today
        return dayFormatter.string(from: date)
    }

    private func dayKeys(for range: StatsRange, offset: Int) -> [String] {
        let start = offset + range.dayCount - 1
        return (offset...start).reversed().map { dayKey(for: $0) }
    }

    private func dateForDayKey(_ key: String) -> Date {
        dayFormatter.date(from: key) ?? calendar.startOfDay(for: .now)
    }

    private func seedDate(_ seed: CountSeed) -> Date {
        let start = calendar.startOfDay(for: seed.day)
        return calendar.date(byAdding: .hour, value: seed.hour, to: start) ?? seed.day
    }
}
