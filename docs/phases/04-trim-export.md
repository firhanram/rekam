# Phase 4 — Trim & Export

## Goal

Given a `RecordingItem` and a `[start..end]` time range, produce a trimmed HEVC `.mp4` in `~/Downloads/Rekam-<timestamp>.mp4`. No editor UI yet — this phase is the headless trimmer plus a temporary "Export full clip to Downloads" button to validate the pipeline.

## Inputs / preconditions

- Phase 3 complete (we have `RecordingItem`s on disk).

## Deliverables

- `Rekam/Core/Export/ExportPresets.swift` — enum mapping `.smaller / .balanced / .higher` to `AVAssetExportSession` presets and any custom options.
- `Rekam/Core/Export/VideoTrimmer.swift` — `actor` or `struct` with:
  - `func export(source: URL, range: CMTimeRange, preset: ExportPreset, to destination: URL) async throws`
  - Internally builds `AVMutableComposition`, inserts the time range from each track of the source asset, then runs `AVAssetExportSession`.
  - Falls back to `AVAssetExportPresetPassthrough` when the source already matches the target codec/quality and no re-encode is needed (pure trim → fastest path, lossless).
- `RekamTests/VideoTrimmerTests.swift` — fixture: a short pre-recorded `.mp4` in test bundle; assert trimmed output exists, duration matches `range`, has audio + video tracks.
- Temporary "Export to Downloads" button on `LibraryView` rows that calls the trimmer with the full duration.

## Implementation steps

1. Define `ExportPreset` enum; map to `AVAssetExportPresetHEVCHighestQuality` for `.higher`, a custom HEVC config for `.balanced`/`.smaller`, and `Passthrough` for the no-re-encode case.
2. Implement `VideoTrimmer.export`:
   1. Load `AVURLAsset` for `source`; `try await asset.load(.tracks, .duration)`.
   2. Build `AVMutableComposition`. For each `AVMediaType` in `[.video, .audio]`, fetch tracks and `insertTimeRange(range, of: track, at: .zero)`.
   3. Choose preset; if passthrough is viable, use it.
   4. Configure `AVAssetExportSession(asset: composition, presetName:)` with `outputURL`, `outputFileType = .mp4`, `shouldOptimizeForNetworkUse = true`.
   5. `await exportSession.export()`; throw on failure with `exportSession.error`.
3. Wire the temp button: pick a row → call trimmer with `CMTimeRange(start: .zero, duration: item.duration)` → reveal output in Finder.

## Verification

- Test: trimmer cuts `[2s..5s]` of a 10s fixture; output asset reports `duration ≈ 3s`; both tracks present.
- Manual: hit the temp Export button on a recording → file lands in `~/Downloads`, plays in QuickTime.
- File size with `.smaller` preset is meaningfully below the source.

## Risks / notes

- **Sandbox + Downloads**: `com.apple.security.files.downloads.read-write` (Phase 0) is required. If denied, fall back to `NSSavePanel` (Phase 6 polish).
- `AVAssetExportSession` is finicky about supported preset/file-type combos — verify with `exportSession.supportedFileTypes` before invoking.
- Passthrough requires the source to already match output settings; safe heuristic is "no re-encode requested AND user did not change codec/scale."
- Long exports: surface progress via `exportSession.progress` (Phase 5/6 wires it into UI).
