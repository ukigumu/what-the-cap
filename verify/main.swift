import Foundation

assert(CaptureState.resolved(trusted: false, paused: true, secure: true) == .permissionDenied, "trust outranks pause")
assert(CaptureState.resolved(trusted: true, paused: true, secure: true) == .pausedByUser, "pause outranks secure")
assert(CaptureState.resolved(trusted: true, paused: false, secure: true) == .secureInput, "secure when trusted and not paused")
assert(CaptureState.resolved(trusted: true, paused: false, secure: false) == .active, "active when all clear")

let mock = MockKeystrokeStore()
assert(mock.todayTotal > 0, "seeded store must have data")
assert(mock.total(for: .month) >= mock.total(for: .week), "30d contains 7d")
assert(mock.total(for: .week) >= mock.total(for: .today), "7d contains today")
assert(mock.bars(for: .today).count == 24, "today renders 24 hour bars")
assert(mock.bars(for: .week).count == 7, "week renders 7 day bars")
assert(mock.bars(for: .month).count == 30, "month renders 30 day bars")
assert(mock.topKeys(for: .month, limit: 8).first?.keyCode == 49, "space must be the most pressed key")
assert(mock.csv(for: .month).hasPrefix("key_code,legend,count\n"), "csv header")
assert(!mock.csv(for: .month).contains("password"), "csv holds counts only")

for layout in KeyboardLayout.all {
    for (index, row) in layout.rows.enumerated() {
        let width = row.reduce(0.0) { $0 + Double($1.width) }
        assert(abs(width - 15.0) < 0.001, "\(layout.id) row \(index) is \(width) units, expected 15")
    }
}
assert(KeyboardLayout.isoSpanish.legend(for: 41) == "Ñ", "key 41 is Ñ on ISO Spanish")
assert(KeyboardLayout.ansi.legend(for: 41) == ";", "key 41 is ; on ANSI")

mock.reset()
assert(!mock.hasData && mock.todayTotal == 0, "reset clears everything")
mock.restoreDemoData()
assert(mock.hasData && mock.total(for: .month) > 0, "restore reseeds")

let dir = FileManager.default.temporaryDirectory.appendingPathComponent("wtc-verify-\(UUID().uuidString)", isDirectory: true)
try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
let dbURL = dir.appendingPathComponent("counts.sqlite")
defer { try? FileManager.default.removeItem(at: dir) }

let store = PersistentStore(fileURL: dbURL)
assert(!store.hasData && store.todayTotal == 0, "fresh file is empty")

let now = Date()
store.record(KeyDown(keyCode: 14, bundleID: "com.apple.dt.Xcode", at: now))
store.record(KeyDown(keyCode: 14, bundleID: "com.apple.dt.Xcode", at: now))
store.record(KeyDown(keyCode: 0, bundleID: "com.googlecode.iterm2", at: now))

waitFor { store.todayTotal == 3 }

assert(store.hasData, "three key-downs are data")
assert(store.keyCounts(for: .today)[14] == 2, "E counted twice")
assert(store.appCounts(for: .today).first?.bundleID == "com.apple.dt.Xcode", "bundle id only")
assert(store.bars(for: .today).count == 24, "hourly bars exist on a real store")
assert(store.bars(for: .week).count == 7, "week bars exist on a real store")
assert(store.bars(for: .month).count == 30, "month bars exist on a real store")

let csv = store.csv(for: .today)
assert(csv.hasPrefix("key_code,legend,count\n"), "persistent csv header")
assert(csv.contains("14,\"E\",2"), "csv is counts")
assert(!csv.contains("password"), "csv has no secrets")
assert(!csv.contains("hello"), "csv has no typed words")

let columns = try! store.schemaColumnNames()
assert(columns == ["day", "hour", "key_code", "bundle_id", "count"], "schema is aggregates only")
assert(try! store.schemaTableNames() == ["counts"], "no event-log table")

let reopened = PersistentStore(fileURL: dbURL)
assert(reopened.todayTotal == 3, "counts survive reopen")
assert(reopened.keyCounts(for: .today)[14] == 2, "per-key counts survive reopen")

reopened.reset()
assert(!reopened.hasData && reopened.todayTotal == 0, "reset deletes the file contents")
let afterReset = PersistentStore(fileURL: dbURL)
assert(!afterReset.hasData, "reset persists")

afterReset.restoreDemoData()
waitFor { afterReset.hasData }
assert(afterReset.total(for: .month) > 0, "demo seed writes the sqlite file")
assert(afterReset.topKeys(for: .month, limit: 1).first?.keyCode == 49, "seeded space is still on top")

print("domain checks passed: capture resolve, mock, sqlite persist, schema, reopen, reset, seed")

func waitFor(_ predicate: () -> Bool) {
    let deadline = Date().addingTimeInterval(2)
    while !predicate() && Date() < deadline {
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))
    }
    assert(predicate(), "timed out waiting for store publish")
}
