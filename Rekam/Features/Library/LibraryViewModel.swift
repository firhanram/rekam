import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class LibraryViewModel {
    var items: [RecordingItem] = []
    var isLoading = false
    var errorMessage: String?

    @ObservationIgnored private let store = RecordingStore()

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
}
