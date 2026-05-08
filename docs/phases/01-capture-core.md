# Phase 1 — Capture core

## Goal

Build the headless capture engine: an `actor` that, given a content selection and a configuration, records the screen + system audio + mic into a single HEVC `.mp4` file. No UI yet — driven from a unit test or a temporary debug button.

## Inputs / preconditions

- Phase 0 complete (entitlements, folder scaffold).

## Deliverables

- `Rekam/Core/Capture/CaptureConfiguration.swift` — `struct` holding codec, fps, bitrate, scale factor, audio toggles. Three static presets: `.smaller`, `.balanced`, `.higher`.
- `Rekam/Core/Capture/ContentPicker.swift` — thin async wrapper around `SCContentSharingPicker`; returns an `SCContentFilter`.
- `Rekam/Core/Capture/MicrophoneCapture.swift` — `AVCaptureSession` + `AVCaptureAudioDataOutput`; emits `CMSampleBuffer`s via a delegate or `AsyncStream`.
- `Rekam/Core/Capture/ScreenRecorder.swift` — `actor`. Owns:
  - `SCStream` (video + system audio outputs)
  - `MicrophoneCapture`
  - `AVAssetWriter` with one HEVC video input (`AVAssetWriterInput`) and two AAC audio inputs (system + mic).
  - Public API: `start(filter:configuration:outputURL:) async throws`, `stop() async throws -> URL`.
- `RekamTests/ScreenRecorderTests.swift` — at minimum, a smoke test that records a 2-second clip from the main display and asserts the output file exists, has nonzero size, and `AVURLAsset` reports a video track and ≥ 1 audio track.

## Implementation steps

1. Define `CaptureConfiguration` with `videoCodec = .hevc`, `frameRate`, `averageBitrate`, `scale`, `captureSystemAudio`, `captureMicrophone`. Add the three presets.
2. Implement `ContentPicker.pick() async throws -> SCContentFilter` using `SCContentSharingPicker.shared`.
3. Implement `MicrophoneCapture` exposing `start()`, `stop()`, and a sample-buffer continuation.
4. Implement `ScreenRecorder`:
   1. Build `SCStreamConfiguration` from `CaptureConfiguration` (size, fps, `capturesAudio = true`, pixel format BGRA).
   2. Create `AVAssetWriter(outputURL: ..., fileType: .mp4)`.
   3. Configure `AVAssetWriterInput` for video with HEVC settings (`AVVideoCompressionPropertiesKey` → `AverageBitRate`, `MaxKeyFrameIntervalDuration = 2`, `ProfileLevel = HEVC_Main_AutoLevel`).
   4. Configure two AAC `AVAssetWriterInput`s (system, mic) at 128 kbps, 48 kHz stereo.
   5. Implement `SCStreamOutput` for `.screen` and `.audio`; on first video sample, call `startSession(atSourceTime:)`.
   6. Forward each sample buffer into the actor via `Task { await self.append(...) }`.
   7. On `stop()`, mark inputs finished, `await writer.finishWriting()`.
5. Wire a temporary debug button in `RootView` (gated behind `#if DEBUG`) that calls `ContentPicker` then records for 5 seconds.
6. Write the `XCTest` smoke test.

## Verification

- Run the smoke test → green; output file plays in QuickTime with both audio tracks.
- Manual: trigger the debug button, talk into the mic + play system audio, confirm both are audible in playback.
- File size for a 10-second 1080p30 capture is in the few-MB range, not tens of MB.

## Risks / notes

- **First-run TCC prompts**: screen recording and mic each prompt once. Expect to grant in System Settings, then relaunch.
- **PTS alignment**: only call `startSession(atSourceTime:)` once, with the first *video* sample's PTS. Audio samples arriving before that must be dropped.
- **Sandbox writes**: write to `FileManager.default.temporaryDirectory` for raw recordings during this phase; Phase 3 moves them to a stable location.
- **HEVC bitrate keys**: use `AVVideoAverageBitRateKey`. Setting `Quality` instead can produce wildly varying file sizes.
