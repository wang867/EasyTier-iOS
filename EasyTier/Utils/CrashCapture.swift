import Foundation

// C function pointer used by signal(). Must be a global (not stored in an enum)
// and must not capture context.
private let easyTierSignalHandler: @convention(c) (Int32) -> Void = { s in
    let line = "[\(ISO8601DateFormatter().string(from: Date()))] SIGNAL \(s)\n"
    if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
        .appendingPathComponent("crashlog.txt"),
       let handle = try? FileHandle(forWritingTo: url) {
        handle.seekToEndOfFile()
        handle.write(Data(line.utf8))
        try? handle.close()
    }
    _ = sigaction(s, nil, nil)
}

// Captures fatal signals/exceptions into Documents/crashlog.txt so crashes can
// be inspected even when iOS produces no analytics entry (TrollStore apps).
enum CrashCapture {
    private static let logURL: URL? = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("crashlog.txt")
    }()

    static func install() {
        log("app launched build \(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") ?? "?")")
        NSSetUncaughtExceptionHandler { exception in
            let reason = exception.reason ?? "unknown"
            let stack = exception.callStackSymbols.prefix(20).joined(separator: "\n")
            log("EXCEPTION \(exception.name.rawValue): \(reason)\n\(stack)")
        }
        for sig in [SIGABRT, SIGILL, SIGSEGV, SIGFPE, SIGBUS, SIGTRAP] {
            signal(sig, easyTierSignalHandler)
        }
    }

    static func log(_ message: String) {
        guard let url = logURL else { return }
        let line = "[\(ISO8601DateFormatter().string(from: Date()))] \(message)\n"
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(Data(line.utf8))
            try? handle.close()
        } else {
            try? line.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
