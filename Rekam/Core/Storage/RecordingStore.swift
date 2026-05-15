import AVFoundation
import Foundation

struct RecordingStore: Sendable {
    let directory: URL

    init(directory: URL = Paths.recordingsDirectory) {
        self.directory = directory
    }

    func list() async -> [RecordingItem] {
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .creationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        var items: [RecordingItem] = []
        for url in urls where url.pathExtension.lowercased() == "mp4" {
            if let item = await item(for: url) {
                items.append(item)
            }
        }

        return items.sorted { $0.createdAt > $1.createdAt }
    }

    func item(for url: URL) async -> RecordingItem? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }

        let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])
        let size = Int64(resourceValues?.fileSize ?? 0)
        let createdAt = resourceValues?.creationDate ?? Date()

        let asset = AVURLAsset(url: url)
        let duration = (try? await asset.load(.duration)) ?? .zero

        return RecordingItem(
            id: url,
            url: url,
            createdAt: createdAt,
            duration: duration,
            sizeBytes: size
        )
    }

    func delete(_ item: RecordingItem) throws {
        try FileManager.default.removeItem(at: item.url)
    }

    func move(from source: URL, to destination: URL) throws -> URL {
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: source, to: destination)
        return destination
    }
}
