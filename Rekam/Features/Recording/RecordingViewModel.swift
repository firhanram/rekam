import Foundation
import Observation
import ScreenCaptureKit

@MainActor
@Observable
final class RecordingViewModel {
    var state: RecorderState = .idle
    var configuration: CaptureConfiguration = .balanced
    var filter: SCContentFilter?
    var sourceLabel: String = "No source selected"
    var lastRecordingURL: URL?
    var elapsed: TimeInterval = 0

    @ObservationIgnored private let recorder = ScreenRecorder()
    @ObservationIgnored private let picker = ContentPicker()
    @ObservationIgnored private let store = RecordingStore()
    @ObservationIgnored private var timerTask: Task<Void, Never>?

    func chooseSource() async {
        do {
            let filter = try await picker.pick()
            self.filter = filter
            self.sourceLabel = describe(filter: filter)
        } catch ContentPickerError.cancelled {
            // user dismissed; leave existing selection in place
        } catch {
            self.state = .failed(error.localizedDescription)
        }
    }

    func toggleRecording() async {
        switch state {
        case .idle, .failed:
            await start()
        case .recording:
            await stop()
        case .preparing, .stopping:
            break
        }
    }

    func setPreset(_ preset: CaptureConfiguration.Preset) {
        configuration = .from(preset: preset)
    }

    private func start() async {
        guard let filter else {
            state = .failed("Pick a source first.")
            return
        }
        state = .preparing
        let url = stagingURL()
        do {
            try await recorder.start(filter: filter, configuration: configuration, outputURL: url)
            let started = Date()
            state = .recording(startedAt: started)
            startTimer(from: started)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func stop() async {
        state = .stopping
        stopTimer()
        do {
            let tempURL = try await recorder.stop()
            let destination = Paths.newRecordingURL()
            let finalURL = (try? store.move(from: tempURL, to: destination)) ?? tempURL
            lastRecordingURL = finalURL
            state = .idle
            elapsed = 0
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func startTimer(from start: Date) {
        stopTimer()
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                self?.elapsed = Date().timeIntervalSince(start)
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func stagingURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("rekam-staging-\(Int(Date().timeIntervalSince1970)).mp4")
    }

    private func describe(filter: SCContentFilter) -> String {
        let rect = filter.contentRect
        let w = Int(rect.width)
        let h = Int(rect.height)
        return "Source: \(w) × \(h)"
    }
}
