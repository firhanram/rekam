# Phase 9 — Rename on export

## Goal

Let the user choose the filename (and optionally the folder) when exporting to Downloads. Today both export paths silently write `Rekam-<timestamp>.mp4` to `~/Downloads`; the user has no opportunity to rename without going to Finder afterwards.

## Inputs / preconditions

- Phases 0–8 complete; export pipeline works end-to-end.
- `ExportDestination.resolve(...)` already wraps `NSSavePanel` for the failure-fallback case — we just need to invoke it on the happy path too.

## Deliverables

- `Rekam/Core/Export/ExportDestination.swift`:
  - Add `prompt(suggestedName:directory:) async throws -> URL` — always shows `NSSavePanel`, defaults to `~/Downloads`.
  - Keep `resolve(...)` for callers that still want the silent path (we won't use it from the new export sites, but it's not worth deleting).
- `Rekam/Features/Editor/TrimEditorViewModel.swift`:
  - `export()` calls `ExportDestination.prompt(suggestedName: defaultExportName)`.
  - `defaultExportName` derives from the source recording: strip `.mp4`, append `-trim.mp4`. Example: `Rekam-20260507-130045-trim.mp4`.
- `Rekam/Features/Library/LibraryViewModel.swift`:
  - `exportToDownloads(_:)` becomes `export(_:)` — same call, but now prompts. Suggested name = the source recording's basename.

Cancellation already returns `ExportDestinationError.cancelled` and is silently swallowed by both view models.

## Implementation steps

1. Add `prompt(suggestedName:)` to `ExportDestination` that opens `NSSavePanel` pre-pointed at `Paths.downloadsDirectory` and pre-filled with the suggested name.
2. Replace `ExportDestination.resolve()` with `ExportDestination.prompt(suggestedName: ...)` in both view models.
3. In `TrimEditorViewModel.export()`, build the suggested name from `item.url.deletingPathExtension().lastPathComponent + "-trim.mp4"`.
4. In `LibraryViewModel.exportToDownloads(_:)`, suggest the source filename verbatim.

## Verification

1. `xcodebuild -scheme Rekam -configuration Debug build` → succeeds, no new warnings.
2. Library row → "Export to Downloads" → save panel appears, defaults to Downloads + the recording's name → change the name → file saves with the new name and is revealed.
3. Trim editor → Export → save panel appears with `<source>-trim.mp4` pre-filled → user can rename and pick another folder if desired.
4. Cancel the panel → no error, no file written, UI stays put.

## Risks / notes

- `NSSavePanel`'s extension-hidden behavior is off by default, which is fine — keep `.mp4` visible so the user knows.
- We retain the entitlement `com.apple.security.files.user-selected.read-write` (added in Phase 0) so the user can save outside `~/Downloads` as well.
- If the user wants the old silent behavior back, we'd add a setting; out of scope for v1.
