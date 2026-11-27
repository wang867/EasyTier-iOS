import Foundation

// Global state for C signal handlers (cannot capture context).
private var easyTierLogURL: URL?
private var easyTierInSignalHandler = false

private func writeCrashLine(_ text: String) {
    guard let url = easyTierLogURL,
          let handle = try? FileHandle(forWritingTo: url) else { return }
    handle.seekToEndOfFile()
    handle.write(Data(text.utf8))
    try? handle.close()
}

private let easyTierSignalHandler: @convention(c) (Int32) -> Void = { s in
    // Prevent the infinite signal loop that blew up the previous log.
    guard !easyTierInSignalHandler else { return }
    easyTierInSignalHandler = true
    let ts = ISO8601DateFormatter().string(from: Date())
    let stack = Thread.callStackSymbols.prefix(30).joined(separator: "\n")
    writeCrashLine("[\(ts)] SIGNAL \(s)\n\(stack)\n")
}

private let easyTierExceptionHandler: @convention(c) (NSException) -> Void = { exception in
    let ts = ISO8601DateFormatter().string(from: Date())
    let stack = exception.callStackSymbols.prefix(30).joined(separator: "\n")
    writeCrashLine("[\(ts)] EXCEPTION \(exception.name.rawValue): \(exception.reason ?? "?")\n\(stack)\n")
}

// Captures crashes into a timestamped file in Documents so each launch gets a
// fresh file (never overwrites the previous one) and Files.app can export it.
enum CrashCapture {
    static func install() {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyyMMdd-HHmmss"
        let name = "crashlog-\(fmt.string(from: Date())).txt"
        easyTierLogURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(name)
        log("app launched build \(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") ?? "?") file=\(name)")
        NSSetUncaughtExceptionHandler(easyTierExceptionHandler)
        for sig in [SIGABRT, SIGILL, SIGSEGV, SIGFPE, SIGBUS, SIGTRAP] {
            signal(sig, easyTierSignalHandler)
        }
    }

    static func log(_ message: String) {
        let line = "[\(ISO8601DateFormatter().string(from: Date()))] \(message)\n"
        writeCrashLine(line)
    }
}
