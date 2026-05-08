# Phase 10 — Drop `Rekam-` prefix from filenames

## Goal

Stop prepending `Rekam-` to recording and export filenames. Users already know the app — the prefix is noise that pads every Library row and every save-panel suggestion (e.g. `Rekam-20260508-181057.mp4`). Default to the timestamp alone: `20260508-181057.mp4`.

## Inputs / preconditions

- Phases 0–9 complete; export/save flow lets users override the suggested name.

## Deliverables

- `Rekam/Core/Storage/Paths.swift`:
  - `newRecordingURL(now:)` produces `<yyyyMMdd-HHmmss>.mp4`.
  - `newExportURL(now:)` produces `<yyyyMMdd-HHmmss>.mp4`.
- `Rekam/Core/Export/ExportDestination.swift`:
  - `defaultName(now:)` produces `<yyyyMMdd-HHmmss>.mp4`.

Behavior of the trim editor's suggested-name (`<source>-trim.mp4`) is untouched — it's already derived from the recording's basename, so it picks up the new naming automatically.

## Implementation steps

1. Edit `Paths.newRecordingURL` and `Paths.newExportURL` to drop `Rekam-` from the produced name.
2. Edit `ExportDestination.defaultName` to do the same.
3. Existing recordings on disk are unaffected — they keep their old names. Only newly created files use the shorter pattern.

## Verification

1. `xcodebuild -scheme Rekam -configuration Debug build` → succeeds, no new warnings.
2. Record a new clip → Library row title is `<timestamp>.mp4` (no `Rekam-` prefix). Old recordings retain their original names.
3. Library → Export → save panel pre-fills with the new short name. Rename works as before.
4. Trim editor → Export → suggested name is `<source>-trim.mp4`, which now reads `<timestamp>-trim.mp4`.

## Risks / notes

- Pure naming change — no schema migration, no UI text changes, no breakage of existing recordings.
- If a future user wants the prefix back as a setting, that's a v2 feature; not in scope.
