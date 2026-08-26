import Foundation
import SQLite3

enum CountDatabaseError: Error {
    case open(String)
    case exec(String)
}

/// SQLite file that stores only increments. There is no event log, so a
/// key sequence cannot be reconstructed from disk.
final class CountDatabase {
    struct Row: Equatable {
        let day: String
        let hour: Int
        let keyCode: UInt16
        let bundleID: String
        let count: Int
    }

    private var db: OpaquePointer?

    init(path: String) throws {
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        if sqlite3_open_v2(path, &db, flags, nil) != SQLITE_OK {
            let message = db.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "open failed"
            throw CountDatabaseError.open(message)
        }
        try exec("""
            CREATE TABLE IF NOT EXISTS counts (
                day TEXT NOT NULL,
                hour INTEGER NOT NULL,
                key_code INTEGER NOT NULL,
                bundle_id TEXT NOT NULL,
                count INTEGER NOT NULL,
                PRIMARY KEY (day, hour, key_code, bundle_id)
            )
            """)
        try exec("PRAGMA journal_mode=WAL")
        try exec("PRAGMA synchronous=NORMAL")
    }

    deinit {
        sqlite3_close(db)
    }

    func increment(day: String, hour: Int, keyCode: UInt16, bundleID: String, by count: Int = 1) throws {
        guard count > 0 else { return }
        let sql = """
            INSERT INTO counts (day, hour, key_code, bundle_id, count)
            VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(day, hour, key_code, bundle_id)
            DO UPDATE SET count = count + excluded.count
            """
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw CountDatabaseError.exec(errmsg())
        }
        sqlite3_bind_text(statement, 1, day, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 2, Int32(hour))
        sqlite3_bind_int(statement, 3, Int32(keyCode))
        sqlite3_bind_text(statement, 4, bundleID, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 5, Int32(count))
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw CountDatabaseError.exec(errmsg())
        }
    }

    func reset() throws {
        try exec("DELETE FROM counts")
    }

    func allRows() throws -> [Row] {
        let sql = "SELECT day, hour, key_code, bundle_id, count FROM counts"
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw CountDatabaseError.exec(errmsg())
        }
        var rows: [Row] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let day = String(cString: sqlite3_column_text(statement, 0))
            let hour = Int(sqlite3_column_int(statement, 1))
            let keyCode = UInt16(sqlite3_column_int(statement, 2))
            let bundleID = String(cString: sqlite3_column_text(statement, 3))
            let count = Int(sqlite3_column_int(statement, 4))
            rows.append(Row(day: day, hour: hour, keyCode: keyCode, bundleID: bundleID, count: count))
        }
        return rows
    }

    func columnNames() throws -> [String] {
        let sql = "PRAGMA table_info(counts)"
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw CountDatabaseError.exec(errmsg())
        }
        var names: [String] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            names.append(String(cString: sqlite3_column_text(statement, 1)))
        }
        return names
    }

    func tableNames() throws -> [String] {
        let sql = "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw CountDatabaseError.exec(errmsg())
        }
        var names: [String] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            names.append(String(cString: sqlite3_column_text(statement, 0)))
        }
        return names
    }

    private func exec(_ sql: String) throws {
        var error: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &error) != SQLITE_OK {
            let message = error.map { String(cString: $0) } ?? errmsg()
            sqlite3_free(error)
            throw CountDatabaseError.exec(message)
        }
    }

    private func errmsg() -> String {
        db.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown sqlite error"
    }
}

/// SQLite wants a pointer it does not free. The Swift overlay does not
/// export SQLITE_TRANSIENT, so we reconstruct the sentinel.
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
