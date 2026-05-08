import AVFoundation
import CoreMedia
import ScreenCaptureKit
import VideoToolbox

private struct UncheckedSample: @unchecked Sendable {
    let buffer: CMSampleBuffer
}

enum ScreenRecorderError: Error {
    case alreadyRunning
    case notRunning
    case writerSetupFailed(String)
    case captureFailed(Error)
    case noDisplay
}

actor ScreenRecorder {
    private var stream: SCStream?
    private var streamOutput: StreamOutputForwarder?
    private var mic: MicrophoneCapture?

    private var writer: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var systemAudioInput: AVAssetWriterInput?
    private var micAudioInput: AVAssetWriterInput?

    private var sessionStarted = false
    private var outputURL: URL?
    private var configuration: CaptureConfiguration?

    func start(filter: SCContentFilter,
               configuration: CaptureConfiguration,
               outputURL: URL) async throws {
        guard stream == nil else { throw ScreenRecorderError.alreadyRunning }
        self.outputURL = outputURL
        self.configuration = configuration

        // ----- AVAssetWriter -----
        let writer: AVAssetWriter
        do {
            try? FileManager.default.removeItem(at: outputURL)
            writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        } catch {
            throw ScreenRecorderError.writerSetupFailed(error.localizedDescription)
        }

        let pixelScale = Double(filter.pointPixelScale)
        let scale = configuration.scale
        let rawWidth = Double(filter.contentRect.width) * pixelScale * scale
        let rawHeight = Double(filter.contentRect.height) * pixelScale * scale
        let outputWidth = Int(rawWidth)
        let outputHeight = Int(rawHeight)
        let evenWidth = outputWidth - (outputWidth % 2)
        let evenHeight = outputHeight - (outputHeight % 2)

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.hevc,
            AVVideoWidthKey: evenWidth,
            AVVideoHeightKey: evenHeight,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: configuration.averageVideoBitrate,
                AVVideoMaxKeyFrameIntervalDurationKey: 2.0,
                AVVideoProfileLevelKey: kVTProfileLevel_HEVC_Main_AutoLevel as String
            ]
        ]
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = true
        if writer.canAdd(videoInput) { writer.add(videoInput) }
        self.videoInput = videoInput

        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey: 48_000,
            AVEncoderBitRateKey: 128_000
        ]

        if configuration.captureSystemAudio {
            let input = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            input.expectsMediaDataInRealTime = true
            if writer.canAdd(input) { writer.add(input) }
            self.systemAudioInput = input
        }

        if configuration.captureMicrophone {
            let input = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            input.expectsMediaDataInRealTime = true
            if writer.canAdd(input) { writer.add(input) }
            self.micAudioInput = input
        }

        guard writer.startWriting() else {
            throw ScreenRecorderError.writerSetupFailed(
                writer.error?.localizedDescription ?? "startWriting() returned false"
            )
        }
        self.writer = writer

        // ----- SCStream -----
        let streamConfig = SCStreamConfiguration()
        streamConfig.width = evenWidth
        streamConfig.height = evenHeight
        streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(configuration.frameRate))
        streamConfig.queueDepth = 6
        streamConfig.pixelFormat = kCVPixelFormatType_32BGRA
        streamConfig.showsCursor = true
        streamConfig.capturesAudio = configuration.captureSystemAudio

        let forwarder = StreamOutputForwarder(recorder: self)
        let stream = SCStream(filter: filter, configuration: streamConfig, delegate: forwarder)
        try stream.addStreamOutput(forwarder, type: .screen, sampleHandlerQueue: nil)
        if configuration.captureSystemAudio {
            try stream.addStreamOutput(forwarder, type: .audio, sampleHandlerQueue: nil)
        }
        self.stream = stream
        self.streamOutput = forwarder

        try await stream.startCapture()

        // ----- Microphone -----
        if configuration.captureMicrophone {
            let mic = MicrophoneCapture()
            try await mic.start { [weak self] sample in
                guard let self else { return }
                let boxed = UncheckedSample(buffer: sample)
                Task { await self.handleMicSample(boxed) }
            }
            self.mic = mic
        }
    }

    func stop() async throws -> URL {
        guard let stream, let writer, let url = outputURL else {
            throw ScreenRecorderError.notRunning
        }

        try? await stream.stopCapture()
        mic?.stop()

        videoInput?.markAsFinished()
        systemAudioInput?.markAsFinished()
        micAudioInput?.markAsFinished()

        await writer.finishWriting()

        let finalError = writer.error
        let status = writer.status

        // Reset state
        self.stream = nil
        self.streamOutput = nil
        self.mic = nil
        self.writer = nil
        self.videoInput = nil
        self.systemAudioInput = nil
        self.micAudioInput = nil
        self.sessionStarted = false
        self.outputURL = nil
        self.configuration = nil

        if status == .failed, let finalError {
            throw ScreenRecorderError.writerSetupFailed(finalError.localizedDescription)
        }
        return url
    }

    fileprivate func handleStreamSample(_ boxed: UncheckedSample, type: SCStreamOutputType) {
        let sample = boxed.buffer
        guard let writer, writer.status == .writing else { return }
        guard sample.isValid, sample.numSamples > 0 else { return }

        switch type {
        case .screen:
            // Drop incomplete frames.
            if !isCompleteFrame(sample) { return }
            if !sessionStarted {
                let pts = CMSampleBufferGetPresentationTimeStamp(sample)
                writer.startSession(atSourceTime: pts)
                sessionStarted = true
            }
            if videoInput?.isReadyForMoreMediaData == true {
                videoInput?.append(sample)
            }
        case .audio:
            guard sessionStarted else { return }
            if systemAudioInput?.isReadyForMoreMediaData == true {
                systemAudioInput?.append(sample)
            }
        default:
            break
        }
    }

    fileprivate func handleMicSample(_ boxed: UncheckedSample) {
        let sample = boxed.buffer
        guard sessionStarted, let writer, writer.status == .writing else { return }
        guard sample.isValid, sample.numSamples > 0 else { return }
        if micAudioInput?.isReadyForMoreMediaData == true {
            micAudioInput?.append(sample)
        }
    }

    private func isCompleteFrame(_ sample: CMSampleBuffer) -> Bool {
        guard let attachments = CMSampleBufferGetSampleAttachmentsArray(sample, createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
              let info = attachments.first,
              let rawStatus = info[.status] as? Int,
              let status = SCFrameStatus(rawValue: rawStatus) else {
            return true
        }
        return status == .complete
    }
}

private final class StreamOutputForwarder: NSObject, SCStreamOutput, SCStreamDelegate, @unchecked Sendable {
    weak var recorder: ScreenRecorder?

    init(recorder: ScreenRecorder) {
        self.recorder = recorder
    }

    func stream(_ stream: SCStream,
                didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
                of type: SCStreamOutputType) {
        guard let recorder else { return }
        let boxed = UncheckedSample(buffer: sampleBuffer)
        Task { await recorder.handleStreamSample(boxed, type: type) }
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        // Surfaced via stop(); nothing to do here for v1.
    }
}
