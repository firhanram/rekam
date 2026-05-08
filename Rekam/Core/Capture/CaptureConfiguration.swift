import AVFoundation
import CoreMedia
import Foundation

struct CaptureConfiguration: Sendable, Equatable {
    enum Preset: String, CaseIterable, Identifiable, Sendable {
        case smaller
        case balanced
        case higher

        var id: String { rawValue }

        var label: String {
            switch self {
            case .smaller: "Smaller"
            case .balanced: "Balanced"
            case .higher: "Higher"
            }
        }
    }

    var preset: Preset
    var frameRate: Int
    var averageVideoBitrate: Int
    var maxLongEdgePixels: Int?
    var captureSystemAudio: Bool
    var captureMicrophone: Bool
    var microphoneDeviceID: String?

    static let smaller = CaptureConfiguration(
        preset: .smaller,
        frameRate: 30,
        averageVideoBitrate: 1_200_000,
        maxLongEdgePixels: 1280,
        captureSystemAudio: true,
        captureMicrophone: true,
        microphoneDeviceID: nil
    )

    static let balanced = CaptureConfiguration(
        preset: .balanced,
        frameRate: 30,
        averageVideoBitrate: 2_500_000,
        maxLongEdgePixels: 1920,
        captureSystemAudio: true,
        captureMicrophone: true,
        microphoneDeviceID: nil
    )

    static let higher = CaptureConfiguration(
        preset: .higher,
        frameRate: 30,
        averageVideoBitrate: 5_000_000,
        maxLongEdgePixels: 2560,
        captureSystemAudio: true,
        captureMicrophone: true,
        microphoneDeviceID: nil
    )

    static func from(preset: Preset) -> CaptureConfiguration {
        switch preset {
        case .smaller: .smaller
        case .balanced: .balanced
        case .higher: .higher
        }
    }
}
