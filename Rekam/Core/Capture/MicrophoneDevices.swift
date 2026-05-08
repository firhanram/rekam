import AVFoundation

struct MicrophoneOption: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
}

enum MicrophoneDevices {
    static func available() -> [MicrophoneOption] {
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        )
        return session.devices.map { device in
            MicrophoneOption(id: device.uniqueID, name: device.localizedName)
        }
    }
}
