# Phase 5 — Editor UI

## Goal

Replace the Phase 4 temp button with a real `TrimEditorView`: `AVPlayer` preview, dual-handle range slider over the timeline, scrub-to-current-time, play/pause, and an Export button that runs the trimmer with progress feedback.

## Inputs / preconditions

- Phase 4 complete (`VideoTrimmer` is reliable and tested).

## Deliverables

- `Rekam/Features/Editor/PlayerContainer.swift` — `NSViewRepresentable` wrapping `AVPlayerView` (AppKit) with controls hidden (we render our own).
- `Rekam/Features/Editor/TrimSliderView.swift` — custom dual-handle slider built on `GeometryReader` + `DragGesture`. Reports `start` and `end` as `CMTime` bound to the view model.
- `Rekam/Features/Editor/TrimEditorViewModel.swift` — `@Observable`. Owns:
  - `player: AVPlayer`
  - `asset: AVURLAsset`
  - `selection: TrimSelection`
  - `exportProgress: Double?`
  - `func export(preset:) async throws -> URL`
- `Rekam/Features/Editor/TrimEditorView.swift` — vertical stack of player, custom timeline + slider, transport controls (play/pause, jump-to-start/end), preset picker, Export button.
- Update `LibraryView` row tap action to present `TrimEditorView` in a sheet (or new `Window` via `WindowGroup` if multi-document feel is desired).

## Implementation steps

1. Build `PlayerContainer` returning `AVPlayerView` with `controlsStyle = .none`.
2. Build `TrimSliderView`:
   - Track + two draggable handles + a highlighted range fill.
   - Clamp `start ≤ end - minGap` (e.g. 0.1s).
   - Tap on track seeks the player; dragging a handle also seeks.
3. Build `TrimEditorViewModel`:
   - On init, create `AVPlayer(playerItem:)`, set `selection = full duration`.
   - Observe `player.currentTime()` via `addPeriodicTimeObserver` to drive the playhead in `TrimSliderView`.
   - `export(preset:)` calls `VideoTrimmer.export` with `CMTimeRange(start: selection.start, end: selection.end)` to a freshly-named file in `~/Downloads`; updates `exportProgress` from `AVAssetExportSession.progress` (poll on a `Task`).
4. Wire `LibraryView` row → `.sheet(item:)` presenting `TrimEditorView(item:)`.
5. After successful export, reveal in Finder and dismiss the sheet.

## Verification

- Open a 30s recording, drag handles to `[10s..20s]`, hit Export.
- Output in `~/Downloads` is exactly the selected segment (~10s), opens in QuickTime.
- Play/pause works; scrubbing the playhead seeks the player.
- Export progress UI updates from 0 → 1.

## Risks / notes

- `AVPlayerView` is AppKit; the SwiftUI bridge needs careful lifecycle (don't recreate the view on every body recompute — use `Coordinator`).
- Use `AVPlayer.seek(to:toleranceBefore: .zero, toleranceAfter: .zero)` for frame-accurate scrubbing on handle drag.
- Removing the periodic time observer on view dismiss is mandatory to avoid retain leaks.
- Long exports: keep the sheet open and disable the export button while running; show indeterminate spinner if `progress` doesn't advance for >2s.
