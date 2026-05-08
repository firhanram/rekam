import Foundation

enum Paths {
    static var recordingsDirectory: URL {
        let base = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = (base ?? FileManager.default.temporaryDirectory)
            .appendingPathComponent("Rekam", isDirectory: true)
            .appendingPathComponent("Recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var downloadsDirectory: URL {
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
    }

    static func newRecordingURL(now: Date = Date()) -> URL {
        recordingsDirectory.appendingPathComponent(timestampedName(now: now))
    }

    static func newExportURL(now: Date = Date()) -> URL {
        downloadsDirectory.appendingPathComponent(timestampedName(now: now))
    }

    private static func timestampedName(now: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return "\(formatter.string(from: now)).mp4"
    }
}
