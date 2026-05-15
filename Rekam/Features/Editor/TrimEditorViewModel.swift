import AppKit
import AVFoundation
import CoreMedia
import Foundation
import Observation

@MainActor
@Observable
final class TrimEditorViewModel {
    let item: RecordingItem
    let player: AVPlayer
    let durationSeconds: Double

    var startSeconds: Double
    var endSeconds: Double
    var currentSeconds: Double = 0
    var isPlaying: Bool = false
    var preset: ExportPreset = .passthrough
    var volume: Double = 1.0
    var isMuted: Bool = false
    var hasAudio: Bool = false
    var exportProgress: Double?
    var exportedURL: URL?
    var errorMessage: String?

    @ObservationIgnored private let trimmer = VideoTrimmer()
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var lastNonZeroVolume: Double = 1.0

    init(item: RecordingItem) {
        self.item = item
        let asset = AVURLAsset(url: item.url)
        let playerItem = AVPlayerItem(asset: asset)
        self.player = AVPlayer(playerItem: playerItem)

        let duration = CMTimeGetSeconds(item.duration)
        let safeDuration = duration.isFinite && duration > 0 ? duration : 0
        self.durationSeconds = safeDuration
        self.startSeconds = 0
        self.endSeconds = safeDuration

        attachTimeObserver()
        loadAudioAvailability(asset: asset)
    }

    deinit {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
    }

    func togglePlayback() {
        if isPlaying {
            player.pause()
        } else {
            // Loop back to start of selection if past end
            if currentSeconds >= endSeconds || currentSeconds < startSeconds {
                seek(to: startSeconds)
            }
            player.play()
        }
        isPlaying.toggle()
    }

    func seek(to seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        currentSeconds = seconds
    }

    func jumpToStart() { seek(to: startSeconds) }
    func jumpToEnd() { seek(to: endSeconds) }

    func setVolume(_ value: Double) {
        let clamped = max(0, min(1, value))
        volume = clamped
        if clamped > 0 {
            lastNonZeroVolume = clamped
            if isMuted { isMuted = false }
        }
        applyAudioToPlayer()
    }

    func toggleMute() {
        isMuted.toggle()
        if !isMuted, volume == 0 {
            volume = lastNonZeroVolume > 0 ? lastNonZeroVolume : 1.0
        }
        applyAudioToPlayer()
    }

    private func applyAudioToPlayer() {
        player.volume = Float(volume)
        player.isMuted = isMuted
    }

    private func loadAudioAvailability(asset: AVURLAsset) {
        Task { [weak self] in
            let tracks = (try? await asset.loadTracks(withMediaType: .audio)) ?? []
            let available = !tracks.isEmpty
            await MainActor.run { [weak self] in
                self?.hasAudio = available
            }
        }
    }

    var canExport: Bool {
        endSeconds - startSeconds >= 0.1 && exportProgress == nil
    }

    func export() async {
        guard canExport else { return }
        exportProgress = 0
        exportedURL = nil
        errorMessage = nil

        let range = CMTimeRange(
            start: CMTime(seconds: startSeconds, preferredTimescale: 600),
            end: CMTime(seconds: endSeconds, preferredTimescale: 600)
        )

        do {
            let suggestedName = item.url.deletingPathExtension().lastPathComponent + "-trim.mp4"
            let destination = try await ExportDestination.prompt(suggestedName: suggestedName)
            let url = try await trimmer.export(
                source: item.url,
                range: range,
                preset: preset,
                volume: Float(volume),
                isMuted: isMuted,
                to: destination,
                progress: { [weak self] p in
                    Task { @MainActor in self?.exportProgress = Double(p) }
                }
            )
            exportProgress = nil
            exportedURL = url
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } catch ExportDestinationError.cancelled {
            exportProgress = nil
        } catch {
            exportProgress = nil
            errorMessage = error.localizedDescription
        }
    }

    private func attachTimeObserver() {
        let interval = CMTime(seconds: 0.05, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            let seconds = CMTimeGetSeconds(time)
            Task { @MainActor [weak self] in
                guard let self else { return }
                if seconds.isFinite { self.currentSeconds = seconds }
                if self.isPlaying, seconds >= self.endSeconds {
                    self.player.pause()
                    self.isPlaying = false
                    self.seek(to: self.endSeconds)
                }
            }
        }
    }
}
