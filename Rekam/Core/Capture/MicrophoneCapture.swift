import AVFoundation
import CoreMedia

final class MicrophoneCapture: NSObject, @unchecked Sendable {
    typealias SampleHandler = @Sendable (CMSampleBuffer) -> Void

    private let session = AVCaptureSession()
    private let output = AVCaptureAudioDataOutput()
    private let queue = DispatchQueue(label: "rekam.mic.capture", qos: .userInitiated)
    private var handler: SampleHandler?

    func start(deviceID: String? = nil, handler: @escaping SampleHandler) async throws {
        try await ensureAuthorization()
        self.handler = handler

        let resolved = deviceID.flatMap { AVCaptureDevice(uniqueID: $0) }
            ?? AVCaptureDevice.default(for: .audio)
        guard let device = resolved else {
            throw NSError(domain: "Rekam.Mic", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "No audio input device available."])
        }
        let input = try AVCaptureDeviceInput(device: device)

        session.beginConfiguration()
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(output) { session.addOutput(output) }
        output.setSampleBufferDelegate(self, queue: queue)
        session.commitConfiguration()

        session.startRunning()
    }

    func stop() {
        session.stopRunning()
        for input in session.inputs { session.removeInput(input) }
        for output in session.outputs { session.removeOutput(output) }
        handler = nil
    }

    private func ensureAuthorization() async throws {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: return
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            if !granted {
                throw NSError(domain: "Rekam.Mic", code: -2,
                              userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied."])
            }
        case .denied, .restricted:
            throw NSError(domain: "Rekam.Mic", code: -3,
                          userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied or restricted."])
        @unknown default:
            return
        }
    }
}

extension MicrophoneCapture: AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        handler?(sampleBuffer)
    }
}
