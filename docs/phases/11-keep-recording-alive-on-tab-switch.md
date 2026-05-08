# Phase 11 — Keep recording alive across tab switches

## Goal

Switching from the **Record** sidebar item to **Library** while a recording is in progress currently destroys the active capture: the file ends up incomplete and the user effectively loses the take. After this phase, switching tabs is a free navigation operation — the recording continues uninterrupted, and switching back shows the still-running timer and stop button.

## Problem

`RootView` uses a `NavigationSplitView` with a `switch` in its `detail` builder:

```swift
} detail: {
    switch selection ?? .record {
    case .record: RecordingView()
    case .library: LibraryView()
    }
}
```

`RecordingView` owns its view model as local view-state:

```swift
@State private var viewModel = RecordingViewModel()
```

When the user switches to Library, SwiftUI tears down `RecordingView`. That deallocates the `@State`-owned `RecordingViewModel`, which owns the `ScreenRecorder` actor, which owns the `SCStream` and `AVAssetWriter`. None of those gracefully `stop()` / `finishWriting()` from a `deinit`, so the output file is left in an inconsistent state and capture silently stops.

`LibraryView` has the same shape, so reloads of the library list also happen on every tab switch — wasteful but not destructive.

## Approach

Lift `RecordingViewModel` and `LibraryViewModel` up to `RootView` as `@State`. Both views become *consumers* of an externally-owned model rather than owners of their own. Lifetimes are bound to `RootView`, which isn't recreated on tab switch, so the recorder actor (and its stream/writer) lives until the user actually stops or the app quits.

## Deliverables

- `Rekam/RootView.swift`:
  - Add `@State private var recordingViewModel = RecordingViewModel()` and `@State private var libraryViewModel = LibraryViewModel()`.
  - Pass both into the corresponding child views.
- `Rekam/Features/Recording/RecordingView.swift`:
  - Replace `@State private var viewModel = RecordingViewModel()` with `let viewModel: RecordingViewModel` (or `@Bindable var viewModel: RecordingViewModel`, since it's `@Observable`).
- `Rekam/Features/Library/LibraryView.swift`:
  - Same lift: `let viewModel: LibraryViewModel`. Move the `editingItem` `@State` to stay where it is (it's local UI state, fine to recreate).

## Implementation steps

1. Make `RootView` the owner of both view models (`@State`).
2. Update `RecordingView`'s init to take a `RecordingViewModel`. Pass `recordingViewModel` from `RootView`.
3. Update `LibraryView`'s init to take a `LibraryViewModel`. Pass `libraryViewModel` from `RootView`.
4. Drop the previews for both views, or change them to construct a fresh model inline (`#Preview { RecordingView(viewModel: .init()) }`).
5. No changes to the view models themselves.

## Verification

1. `xcodebuild -scheme Rekam -configuration Debug build` → succeeds, no new warnings.
2. Pick a source, start recording. Wait ~3 s, switch to Library, wait ~3 s, switch back to Record → elapsed timer reads ~6 s and is still ticking; record button still shows **Stop**.
3. Hit Stop → final clip duration is ~6 s, plays cleanly in QuickTime, both audio tracks present.
4. Library list still auto-refreshes when a recording lands (Phase 6 notification path is unaffected).

## Risks / notes

- `LibraryView`'s `.task { await viewModel.refresh() }` only fires once per view lifetime now (i.e. when `RootView` first loads). The `.onReceive(.rekamRecordingSaved)` path keeps it fresh after recordings; explicit refresh on tab show is no longer triggered, but isn't needed.
- If we ever add a "refresh now" button in Library, hook it to `viewModel.refresh()` directly.
- `RootView` lives for the lifetime of the window/app, so the recorder actor is retained for the same span. That's intentional — the user stays in control of when to stop.
