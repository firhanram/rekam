import AppKit
import CoreMedia
import Foundation
import Observation

@MainActor
@Observable
final class LibraryViewModel {
    var items: [RecordingItem] = []
    var isLoading = false
    var errorMessage: String?
    var exportingItemID: RecordingItem.ID?

    @ObservationIgnored private let store = RecordingStore()
    @ObservationIgnored private let trimmer = VideoTrimmer()

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        items = await store.list()
    }

    func delete(_ item: RecordingItem) async {
        do {
            try store.delete(item)
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func revealInFinder(_ item: RecordingItem) {
        NSWorkspace.shared.activateFileViewerSelecting([item.url])
    }

    func exportToDownloads(_ item: RecordingItem) async {
        guard exportingItemID == nil else { return }
        exportingItemID = item.id
        defer { exportingItemID = nil }

        let range = CMTimeRange(start: .zero, duration: item.duration)
        do {
            let destination = try await ExportDestination.prompt(suggestedName: item.name)
            let url = try await trimmer.export(
                source: item.url,
                range: range,
                preset: .passthrough,
                to: destination
            )
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } catch ExportDestinationError.cancelled {
            // user dismissed save panel; quietly stop
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
