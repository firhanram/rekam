# Phase 12 — Choose microphone device

## Goal

Let the user pick which audio input device records alongside the screen. Today the recorder always uses `AVCaptureDevice.default(for: .audio)` — typically the built-in mic, even when the user has AirPods, a USB mic, or an audio interface they'd rather use. After this phase, a dropdown in the Record view lists every available input and the user can switch at any time before starting a capture.

## Inputs / preconditions

- Phases 0–11 complete; the on/off mic toggle and `MicrophoneCapture` lifecycle already work.

## Deliverables

- `Rekam/Core/Capture/MicrophoneDevices.swift` — `MicrophoneOption(id, name)` and `MicrophoneDevices.available()` using `AVCaptureDevice.DiscoverySession(deviceTypes: [.microphone, .external], mediaType: .audio, position: .unspecified)`.
- `Rekam/Core/Capture/MicrophoneCapture.swift` — `start(deviceID: String? = nil, handler:)`. Resolves via `AVCaptureDevice(uniqueID:)`; falls back to `AVCaptureDevice.default(for: .audio)`.
- `Rekam/Core/Capture/CaptureConfiguration.swift` — new `microphoneDeviceID: String?`, default `nil` on all presets.
- `Rekam/Core/Capture/ScreenRecorder.swift` — passes `configuration.microphoneDeviceID` into `mic.start(deviceID:handler:)`.
- `Rekam/Features/Recording/RecordingViewModel.swift` — `availableMicrophones`, `selectedMicrophoneID` proxy, `refreshMicrophones()`, plus observers for `AVCaptureDeviceWasConnected` / `AVCaptureDeviceWasDisconnected` so hot-plugged devices appear without a relaunch. If the previously selected device disappears, fall back to `nil` (system default).
- `Rekam/Features/Recording/RecordingView.swift` — new `microphoneCard` between the quality picker and source card, with a `Menu` showing **System default** plus each available device. Disabled when the mic toggle is off, no devices exist, or while a recording is active.

## Implementation steps

1. Add `MicrophoneDevices.swift`.
2. Update `MicrophoneCapture.start` to accept `deviceID`.
3. Add `microphoneDeviceID` to `CaptureConfiguration` (and update the three static presets).
4. Forward the field from `ScreenRecorder.start` into `MicrophoneCapture.start`.
5. Extend `RecordingViewModel` with the device list, the proxy property, and the connect/disconnect observers.
6. Add the `microphoneCard` view to `RecordingView`.

## Verification

1. `xcodebuild -scheme Rekam -configuration Debug build` → succeeds, no new warnings.
2. With only the built-in mic: the menu shows **System default** and **MacBook microphone** (or similar). Defaults to system default.
3. Pair AirPods or plug a USB mic: the menu refreshes within a couple of seconds via the connect notification. Pick the new device, record, speak, stop → playback confirms voice came from the chosen device.
4. Toggle the mic off in the controls bar → the picker greys out; the recorded file has no microphone track.
5. Disconnect the selected device while idle → the picker reverts to **System default** automatically.

## Risks / notes

- Hot-swap **during** recording is out of scope; the device is locked at start.
- System audio device selection is a separate concern (governed by ScreenCaptureKit) and is not addressed here.
- The selection isn't persisted across launches; the default is **System default** every time. If we ever want stickiness, `@AppStorage` on the `microphoneDeviceID` is a one-line addition.
