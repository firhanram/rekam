import AppKit
import Foundation
import UniformTypeIdentifiers

enum ExportDestinationError: Error {
    case cancelled
}

enum ExportDestination {
    static func defaultName(now: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return "Rekam-\(formatter.string(from: now)).mp4"
    }

    /// Attempts to resolve a writable URL in ~/Downloads. On sandbox or write
    /// failure, falls back to an NSSavePanel.
    @MainActor
    static func resolve(suggestedName: String = defaultName()) async throws -> URL {
        let candidate = Paths.downloadsDirectory.appendingPathComponent(suggestedName)
        if canWrite(to: candidate) {
            return candidate
        }
        return try await promptSavePanel(suggestedName: suggestedName)
    }

    private static func canWrite(to url: URL) -> Bool {
        let dir = url.deletingLastPathComponent()
        let probe = dir.appendingPathComponent(".rekam-probe-\(UUID().uuidString)")
        do {
            try Data().write(to: probe)
            try? FileManager.default.removeItem(at: probe)
            return true
        } catch {
            return false
        }
    }

    @MainActor
    private static func promptSavePanel(suggestedName: String) async throws -> URL {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.mpeg4Movie]
        panel.nameFieldStringValue = suggestedName
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false

        let response = await panel.beginAsync()
        guard response == .OK, let url = panel.url else {
            throw ExportDestinationError.cancelled
        }
        return url
    }
}

private extension NSSavePanel {
    func beginAsync() async -> NSApplication.ModalResponse {
        await withCheckedContinuation { cont in
            DispatchQueue.main.async {
                cont.resume(returning: self.runModal())
            }
        }
    }
}
