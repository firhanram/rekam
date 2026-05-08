# Phase 3 — Storage & Library

## Goal

Stop dropping recordings in the temp directory. Persist them to a stable app location, enumerate them as `RecordingItem`s with metadata, and surface them in a `LibraryView` with delete and "Reveal in Finder" actions.

## Inputs / preconditions

- Phase 2 complete (recording produces a file we can persist).

## Deliverables

- `Rekam/Core/Storage/Paths.swift` — resolves:
  - `recordingsDirectory` → `Application Support/Rekam/Recordings/` (created lazily).
  - `downloadsDirectory` → `FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!`.
- `Rekam/Core/Storage/RecordingStore.swift` — enumerates `recordingsDirectory`, returns `[RecordingItem]`, supports `delete(_:)`. Reads duration and size lazily via `AVURLAsset.load(.duration)` and `URLResourceValues`.
- `Rekam/Features/Library/LibraryViewModel.swift` — `@Observable`; loads items, observes the directory (`DispatchSourceFileSystemObject` or simple refresh on appear).
- `Rekam/Features/Library/LibraryView.swift` — list with rows showing date, duration, size; context menu: Open in Trim Editor (Phase 5), Reveal in Finder, Delete.
- Update `RecordingViewModel` to write the final file into `Paths.recordingsDirectory` with `Rekam-yyyyMMdd-HHmmss.mp4` naming.

## Implementation steps

1. Implement `Paths` with computed `URL` properties and a `ensureExists()` helper.
2. Implement `RecordingStore.list() async -> [RecordingItem]` using `FileManager.default.contentsOfDirectory` + `URLResourceValues` for `.fileSize` and `.creationDate`, and `AVURLAsset` for duration.
3. Implement `RecordingStore.delete(_:) throws`.
4. Implement `LibraryViewModel` with `items`, `refresh()`, `delete(_:)`.
5. Build `LibraryView`:
   - `List(viewModel.items)` with rows showing `createdAt` (formatted), `duration` (mm:ss), `sizeBytes` (`.byteCount`).
   - `.contextMenu` with Reveal in Finder (`NSWorkspace.shared.activateFileViewerSelecting`) and Delete.
   - Refresh `.onAppear` and after every delete.
6. Update `RecordingViewModel.stop()` to move the temp file into `Paths.recordingsDirectory` with the timestamped name.

## Verification

- Record three clips → all three appear in Library with correct duration and size.
- Right-click → Reveal in Finder opens `Application Support/Rekam/Recordings/`.
- Delete removes the file from disk and the row from the list.
- Quit and relaunch → recordings persist.

## Risks / notes

- `Application Support` for sandboxed apps lives under `~/Library/Containers/<bundle-id>/Data/Library/Application Support/Rekam/` — that's expected; the export step (Phase 4) is what lands the user-facing file in `~/Downloads`.
- `AVURLAsset.load(.duration)` is async — don't call from a sync context.
- File-system observers are nice-to-have; a simple `refresh()` on appear is sufficient for v1.
