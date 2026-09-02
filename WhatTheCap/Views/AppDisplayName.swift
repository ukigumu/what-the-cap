import Foundation
#if os(macOS)
import AppKit
#endif

/// Resolves a stored bundle identifier to the name the user sees.
/// The SQLite file still holds only the bundle id.
enum AppDisplayName {
    private static let lock = NSLock()
    private static var cache: [String: String] = [:]

    static func resolve(_ bundleID: String) -> String {
        lock.lock()
        defer { lock.unlock() }
        if let cached = cache[bundleID] { return cached }
        let name = lookup(bundleID)
        cache[bundleID] = name
        return name
    }

    private static func lookup(_ bundleID: String) -> String {
        if bundleID == "unknown" { return "Unknown" }
        #if os(macOS)
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            if let name = Bundle(url: url)?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
               !name.isEmpty {
                return name
            }
            let fromPath = url.deletingPathExtension().lastPathComponent
            if !fromPath.isEmpty { return fromPath }
            if let name = Bundle(url: url)?.object(forInfoDictionaryKey: "CFBundleName") as? String,
               !name.isEmpty {
                return name
            }
        }
        #endif
        return bundleID.split(separator: ".").last.map(String.init) ?? bundleID
    }
}
