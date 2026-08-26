import Foundation

// Domain checks for the mock store and layout tables. Compiled and run by
// verify.sh on any platform with a Swift toolchain, including Linux.

let store = MockKeystrokeStore()

assert(store.todayTotal > 0, "seeded store must have data")
assert(store.total(for: .month) >= store.total(for: .week), "30d contains 7d")
assert(store.total(for: .week) >= store.total(for: .today), "7d contains today")

let hourly = store.bars(for: .today)
assert(hourly.count == 24, "today renders 24 hour bars")
assert(store.bars(for: .week).count == 7, "week renders 7 day bars")
assert(store.bars(for: .month).count == 30, "month renders 30 day bars")

let top = store.topKeys(for: .month, limit: 8)
assert(top.first?.keyCode == 49, "space must be the most pressed key")
assert(top.map(\.count) == top.map(\.count).sorted(by: >), "top keys sorted")

for layout in KeyboardLayout.all {
    for (index, row) in layout.rows.enumerated() {
        let width = row.reduce(0.0) { $0 + Double($1.width) }
        assert(abs(width - 15.0) < 0.001, "\(layout.id) row \(index) is \(width) units, expected 15")
    }
}
assert(KeyboardLayout.isoSpanish.legend(for: 41) == "Ñ", "key 41 is Ñ on ISO Spanish")
assert(KeyboardLayout.ansi.legend(for: 41) == ";", "key 41 is ; on ANSI")

let csv = store.csv(for: .month)
assert(csv.hasPrefix("key_code,legend,count\n"), "csv header")
assert(!csv.contains("password"), "csv holds counts only")

let second = MockKeystrokeStore()
assert(second.total(for: .month) == store.total(for: .month), "seed is deterministic")

store.reset()
assert(!store.hasData && store.todayTotal == 0, "reset clears everything")
store.restoreDemoData()
assert(store.hasData && store.total(for: .month) > 0, "restore reseeds")

print("domain checks passed: totals, bars, top keys, layout widths, csv, determinism, reset")
