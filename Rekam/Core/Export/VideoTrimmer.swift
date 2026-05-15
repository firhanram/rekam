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
        volume: Float = 1.0,
        isMuted: Bool = false,
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

        var compositionAudioTrackIDs: [CMPersistentTrackID] = []
        if !isMuted {
            for track in audioTracks {
                let dest = composition.addMutableTrack(
                    withMediaType: .audio,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                )
                try dest?.insertTimeRange(clampedRange, of: track, at: .zero)
                if let dest { compositionAudioTrackIDs.append(dest.trackID) }
            }
        }

        let clampedVolume = max(0, min(1, volume))
        let needsAudioMix = !isMuted && clampedVolume < 1.0 && !compositionAudioTrackIDs.isEmpty
        // AVAssetExportPresetPassthrough copies audio samples untouched and ignores audioMix.
        // For partial-volume exports, fall back to HighestQuality so the mix is honored.
        let resolvedPresetName: String = {
            if needsAudioMix, preset.avPresetName == AVAssetExportPresetPassthrough {
                return AVAssetExportPresetHighestQuality
            }
            return preset.avPresetName
        }()

        guard let session = AVAssetExportSession(
            asset: composition,
            presetName: resolvedPresetName
        ) else {
            throw VideoTrimmerError.sessionCreationFailed
        }

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }

        if needsAudioMix {
            let audioMix = AVMutableAudioMix()
            audioMix.inputParameters = compositionAudioTrackIDs.map { trackID in
                let params = AVMutableAudioMixInputParameters()
                params.trackID = trackID
                params.setVolume(clampedVolume, at: .zero)
                return params
            }
            session.audioMix = audioMix
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
