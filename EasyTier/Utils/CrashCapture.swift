import Foundation

// Global state for C signal handlers (cannot capture context).
private var easyTierLogURL: URL?

// Append to the log file, CREATING it if it does not exist yet.
private func writeCrashLine(_ text: String) {
    guard let url = easyTierLogURL else { return }
    if let handle = try? FileHandle(forWritingTo: url) {
        handle.seekToEndOfFile()
        handle.write(Data(text.utf8))
        try? handle.close()
    } else {
        // File missing: create it (this branch was missing and caused no log).
        try? text.write(to: url, atomically: true, encoding: .utf8)
    }
}

private let easyTierSignalHandler: @convention(c) (Int32) -> Void = { s in
    let ts = ISO8601DateFormatter().string(from: Date())
    let stack = Thread.callStackSymbols.prefix(40).joined(separator: "\n")
    writeCrashLine("[\(ts)] === SIGNAL \(s) ===\n\(stack)\n")
    // Restore default handler and re-raise so the process terminates normally.
    signal(s, SIG_DFL)
}

private let easyTierExceptionHandler: @convention(c) (NSException) -> Void = { exception in
    let ts = ISO8601DateFormatter().string(from: Date())
    let stack = exception.callStackSymbols.prefix(40).joined(separator: "\n")
    writeCrashLine("[\(ts)] === EXCEPTION \(exception.name.rawValue): \(exception.reason ?? "?") ===\n\(stack)\n")
}

// Captures crashes + connection trace into Documents/crashlog.txt.
// Each launch appends a timestamped separator so old entries are never lost.
enum CrashCapture {
    static func install() {
        easyTierLogURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("crashlog.txt")
        let ts = ISO8601DateFormatter().string(from: Date())
        log("========== LAUNCH \(ts) build \(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") ?? "?") ==========")
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
