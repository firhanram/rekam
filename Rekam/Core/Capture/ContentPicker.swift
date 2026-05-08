import ScreenCaptureKit

enum ContentPickerError: Error {
    case cancelled
    case underlying(Error)
}

@MainActor
final class ContentPicker: NSObject, SCContentSharingPickerObserver {
    private var continuation: CheckedContinuation<SCContentFilter, Error>?

    func pick() async throws -> SCContentFilter {
        if continuation != nil {
            throw ContentPickerError.underlying(NSError(
                domain: "Rekam.ContentPicker",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Picker is already active."]
            ))
        }

        let picker = SCContentSharingPicker.shared
        picker.add(self)
        picker.isActive = true

        return try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            picker.present()
        }
    }

    nonisolated func contentSharingPicker(
        _ picker: SCContentSharingPicker,
        didCancelFor stream: SCStream?
    ) {
        Task { @MainActor in self.finish(.failure(ContentPickerError.cancelled)) }
    }

    nonisolated func contentSharingPicker(
        _ picker: SCContentSharingPicker,
        didUpdateWith filter: SCContentFilter,
        for stream: SCStream?
    ) {
        Task { @MainActor in self.finish(.success(filter)) }
    }

    nonisolated func contentSharingPickerStartDidFailWithError(_ error: Error) {
        Task { @MainActor in self.finish(.failure(ContentPickerError.underlying(error))) }
    }

    private func finish(_ result: Result<SCContentFilter, Error>) {
        guard let cont = continuation else { return }
        continuation = nil
        let picker = SCContentSharingPicker.shared
        picker.remove(self)
        picker.isActive = false
        switch result {
        case .success(let filter): cont.resume(returning: filter)
        case .failure(let err): cont.resume(throwing: err)
        }
    }
}
