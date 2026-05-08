import AVFoundation

enum ExportPreset: String, CaseIterable, Identifiable, Sendable {
    case passthrough
    case smaller
    case balanced
    case higher

    var id: String { rawValue }

    var label: String {
        switch self {
        case .passthrough: "Lossless"
        case .smaller: "Smaller"
        case .balanced: "Balanced"
        case .higher: "Higher"
        }
    }

    var avPresetName: String {
        switch self {
        case .passthrough: AVAssetExportPresetPassthrough
        case .smaller: AVAssetExportPresetHEVC1920x1080
        case .balanced: AVAssetExportPresetHEVCHighestQuality
        case .higher: AVAssetExportPresetHEVCHighestQuality
        }
    }
}
