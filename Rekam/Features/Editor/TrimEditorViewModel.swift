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
    var exportProgress: Double?
    var exportedURL: URL?
    var errorMessage: String?

    @ObservationIgnored private let trimmer = VideoTrimmer()
    @ObservationIgnored private var timeObserver: Any?

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

    var canExport: Bool {
        endSeconds - startSeconds >= 0.1 && exportProgress == nil
    }

    func export() async {
        guard canExport else { return }
        exportProgress = 0
        exportedURL = nil
        errorMessage = nil

        let destination = Paths.newExportURL()
        let range = CMTimeRange(
            start: CMTime(seconds: startSeconds, preferredTimescale: 600),
            end: CMTime(seconds: endSeconds, preferredTimescale: 600)
        )

        do {
            let url = try await trimmer.export(
                source: item.url,
                range: range,
                preset: preset,
                to: destination,
                progress: { [weak self] p in
                    Task { @MainActor in self?.exportProgress = Double(p) }
                }
            )
            exportProgress = nil
            exportedURL = url
            NSWorkspace.shared.activateFileViewerSelecting([url])
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
