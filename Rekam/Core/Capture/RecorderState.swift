import Foundation

enum RecorderState: Equatable {
    case idle
    case preparing
    case recording(startedAt: Date)
    case stopping
    case failed(String)

    var isActive: Bool {
        switch self {
        case .recording: true
        default: false
        }
    }

    var isBusy: Bool {
        switch self {
        case .preparing, .stopping: true
        default: false
        }
    }
}
