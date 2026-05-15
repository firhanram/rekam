# Phase 13 — Preview recording in a standalone window

## Goal

Add an option to open a recording in its own macOS window instead of the existing modal trim sheet. Today, clicking a Library row presents the trim editor as a sheet anchored to the main window — useful, but blocking and not movable independently. After this phase, right-clicking a row exposes a **Preview in New Window** entry that opens the same trim editor (player, scrubber, transport, export) in a standalone resizable window. The sheet path is preserved; the new option is additive. Multiple recordings can be previewed side-by-side.

## Inputs / preconditions

- Phases 0–12 complete; `TrimEditorView` already works as a sheet and uses `@Environment(\.dismiss)`.
- macOS 14+ deployment target (project already requires it for `@Observable`).

## Deliverables

- `Rekam/Core/Storage/RecordingStore.swift` — new `item(for url: URL) async -> RecordingItem?` that loads file size, creation date, and asset duration for a single URL. `list()` is refactored to call this helper.
- `Rekam/RekamApp.swift` — second scene `WindowGroup("Preview", id: "preview", for: URL.self)` that resolves the URL to a `RecordingItem` via `RecordingStore().item(for:)` and renders `TrimEditorView`. Falls back to an "unavailable" placeholder when the file no longer exists (e.g., it was deleted between launches).
- `Rekam/Features/Library/LibraryView.swift` — `@Environment(\.openWindow)` added; new context-menu entry **Preview in New Window** above **Open in Trim Editor** that calls `openWindow(id: "preview", value: item.url)`.

## Implementation steps

1. Extract the per-URL metadata block from `RecordingStore.list()` into `RecordingStore.item(for:)`, returning `nil` when the file is missing.
2. Add the `WindowGroup(for: URL.self)` scene in `RekamApp`. Use a small wrapper view that loads the `RecordingItem` in a `.task(id: url)` and shows the trim editor or a "Recording unavailable" placeholder.
3. Add the `openWindow` environment value and the new context-menu button in `LibraryView`.
4. Document phase 13 (this file).

## Verification

1. `xcodebuild -scheme Rekam -configuration Debug build` succeeds with no new warnings.
2. Library → right-click a recording → **Preview in New Window** opens a standalone window with the full trim editor (player, scrubber, transport, export) and the filename in the title bar.
3. Open two different recordings in separate windows simultaneously; play one while pausing the other — each window's audio/video is independent.
4. Resize, move, and minimize the preview window independently of the main window. Close the main window — preview windows keep functioning.
5. Single-clicking a row still opens the existing modal sheet (regression check).
6. Export from inside a windowed preview saves to Downloads exactly like the sheet path.
7. Close the preview via the title-bar red button **and** via the in-view `xmark` button — both work.
8. Delete a recording's file outside the app, then trigger SwiftUI state restoration for a stale URL → the placeholder ("Recording unavailable") renders instead of crashing.

## Risks / notes

- `RecordingItem` itself can't be used as the `WindowGroup` value because `CMTime` isn't `Codable`. Using `URL` (which is also `RecordingItem.id`) sidesteps this and preserves SwiftUI state restoration.
- Each window builds its own `TrimEditorViewModel`, so per-window `AVPlayer` isolation is automatic — no shared-state work needed.
- State restoration may reopen previously open preview windows on relaunch; this is desirable. If the underlying file was deleted in between, the placeholder view handles it gracefully.
- Hot-swap of the underlying file (rename/move while a window is open) is out of scope; the window is bound to the original URL and will show the placeholder on next launch if the file disappears.
