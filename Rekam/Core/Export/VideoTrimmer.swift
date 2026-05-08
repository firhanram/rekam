import AVFoundation
import CoreMedia
import Foundation

enum VideoTrimmerError: Error {
    case invalidRange
    case sessionCreationFailed
    case exportFailed(String)
    case cancelled
}

actor VideoTrimmer {
    typealias ProgressHandler = @Sendable (Float) -> Void

    func export(
        source: URL,
        range: CMTimeRange,
        preset: ExportPreset = .passthrough,
        to destination: URL,
        progress: ProgressHandler? = nil
    ) async throws -> URL {
        let asset = AVURLAsset(url: source)
        let assetDuration = try await asset.load(.duration)

        let clampedRange = clamp(range: range, within: assetDuration)
        guard clampedRange.duration > .zero else {
            throw VideoTrimmerError.invalidRange
        }

        let composition = AVMutableComposition()
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)

        for track in videoTracks {
            let dest = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
            )
            try dest?.insertTimeRange(clampedRange, of: track, at: .zero)
        }
        for track in audioTracks {
            let dest = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            )
            try dest?.insertTimeRange(clampedRange, of: track, at: .zero)
        }

        guard let session = AVAssetExportSession(
            asset: composition,
            presetName: preset.avPresetName
        ) else {
            throw VideoTrimmerError.sessionCreationFailed
        }

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }

        session.shouldOptimizeForNetworkUse = true

        let progressTask: Task<Void, Never>?
        if let progress {
            progressTask = Task {
                for await state in session.states(updateInterval: 0.2) {
                    if case .exporting(let p) = state {
                        progress(Float(p.fractionCompleted))
                    }
                }
            }
        } else {
            progressTask = nil
        }
        defer { progressTask?.cancel() }

        do {
            try await session.export(to: destination, as: .mp4)
            progress?(1.0)
            return destination
        } catch {
            throw VideoTrimmerError.exportFailed(error.localizedDescription)
        }
    }

    private func clamp(range: CMTimeRange, within duration: CMTime) -> CMTimeRange {
        let start = CMTimeMaximum(range.start, .zero)
        let end = CMTimeMinimum(range.end, duration)
        if start >= end { return .zero }
        return CMTimeRange(start: start, end: end)
    }
}
