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
    var scale: Double
    var captureSystemAudio: Bool
    var captureMicrophone: Bool

    static let smaller = CaptureConfiguration(
        preset: .smaller,
        frameRate: 30,
        averageVideoBitrate: 3_000_000,
        scale: 0.75,
        captureSystemAudio: true,
        captureMicrophone: true
    )

    static let balanced = CaptureConfiguration(
        preset: .balanced,
        frameRate: 30,
        averageVideoBitrate: 5_000_000,
        scale: 1.0,
        captureSystemAudio: true,
        captureMicrophone: true
    )

    static let higher = CaptureConfiguration(
        preset: .higher,
        frameRate: 60,
        averageVideoBitrate: 12_000_000,
        scale: 1.0,
        captureSystemAudio: true,
        captureMicrophone: true
    )

    static func from(preset: Preset) -> CaptureConfiguration {
        switch preset {
        case .smaller: .smaller
        case .balanced: .balanced
        case .higher: .higher
        }
    }
}
