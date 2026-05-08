import CoreMedia
import Foundation

struct RecordingItem: Identifiable, Hashable, Sendable {
    let id: URL
    let url: URL
    let createdAt: Date
    let duration: CMTime
    let sizeBytes: Int64

    var name: String { url.lastPathComponent }
}
