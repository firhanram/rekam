# Phase 2 — Recording UI

## Goal

Replace the debug button with a real `RecordingView`: user picks quality preset, clicks "Choose source…" to invoke `SCContentSharingPicker`, hits record, sees an elapsed timer, and stops to land an `.mp4` on disk. Mic and system-audio toggles are exposed.

## Inputs / preconditions

- Phase 1 complete (`ScreenRecorder` works headlessly).

## Deliverables

- `Rekam/Features/Recording/RecordingViewModel.swift` — `@Observable` class wrapping `ScreenRecorder`. Owns `RecorderState`, the chosen `SCContentFilter`, the chosen `CaptureConfiguration`, and the elapsed-time timer.
- `Rekam/Features/Recording/RecordingControls.swift` — record/stop button, elapsed-time label, mic + system-audio toggles, preset picker.
- `Rekam/Features/Recording/RecordingView.swift` — composes the above; "Choose source…" button bound to `ContentPicker`.
- Update `RootView` to host `RecordingView` in the Record tab.

## Implementation steps

1. Define `RecorderState` per `ARCHITECTURE.md` §6 (in `Core/Capture/` since it's owned by the recorder concept).
2. Build `RecordingViewModel`:
   - `state: RecorderState`
   - `configuration: CaptureConfiguration` (default `.balanced`)
   - `filter: SCContentFilter?`
   - `chooseSource()`, `start()`, `stop()` async methods.
   - Drive the timer via `Timer.publish` or an `AsyncStream` while in `.recording`.
3. Build `RecordingControls` as a horizontal toolbar.
4. Build `RecordingView`:
   - Top: preset segmented control + audio toggles.
   - Middle: thumbnail/preview of selected source (use `SCContentFilter.contentRect` description as text for now).
   - Bottom: `RecordingControls`.
   - Disable the record button while `filter == nil` or state is `.preparing`/`.stopping`.
5. On stop, log the resulting URL (Phase 3 handles persistence).

## Verification

- Choose a display, hit record, talk for a few seconds, stop.
- Output file is logged to the console; opens in QuickTime with both audio tracks present.
- Toggling preset between recordings produces visibly different file sizes.
- Toggling off the mic produces a file with only the system-audio track.

## Risks / notes

- `SCContentSharingPicker` is system-modal; ensure it's invoked from `@MainActor`.
- Surface failures via an alert (`state == .failed`); never crash on permission denial.
- Timer should tear down on stop or view disappear to avoid leaks.
