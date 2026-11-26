import Foundation

// iOS 14 build: OSLogStore (iOS 15+) is unavailable.
// Provide a stub that writes an explanatory placeholder so callers keep working.
enum OSLogExporter {
    enum ExportError: Error {
        case containerUnavailable
        case emptyLogs
    }

    static func exportToAppGroup(appGroupID: String) throws -> URL {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            throw ExportError.containerUnavailable
        }
        let filename = "EasyTier-NE-oslog-\(Int(Date().timeIntervalSince1970)).log"
        let url = containerURL.appendingPathComponent(filename)
        let text = "OS Log export requires iOS 15 or newer."
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
