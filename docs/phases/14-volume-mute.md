# Phase 14 — Adjust audio volume (and mute/unmute) after recording

## Goal

Give the user a way to lower, raise (up to original), or fully mute a recording's audio from inside the trim editor — both for live playback and for the exported MP4. Before this phase the only options were to re-record or to post-process the file in another app. After this phase, the trim editor exposes a volume slider (0%–100%) and a speaker icon that toggles mute, both of which apply in real time during preview and are baked into the exported file.

## Inputs / preconditions

- Phases 0–13 complete; the trim editor already owns an `AVPlayer` (`TrimEditorViewModel.player`) and the export goes through `VideoTrimmer.export`.
- macOS 14+ deployment target.

## Deliverables

- `Rekam/Core/Export/VideoTrimmer.swift` — `export(...)` gains `volume: Float = 1.0` and `isMuted: Bool = false`.
  - When `isMuted`, the audio tracks are **omitted** from the composition entirely — the exported file is silent under any preset (passthrough included). This avoids `AVAssetExportSession`'s passthrough preset silently ignoring an `audioMix`.
  - When `0 ≤ volume < 1.0` and not muted, the trimmer attaches an `AVMutableAudioMix` to the export session. Because `AVAssetExportPresetPassthrough` does not honor `audioMix`, the preset is transparently upgraded to `AVAssetExportPresetHighestQuality` for partial-volume exports; all other presets honor the mix directly.
- `Rekam/Features/Editor/TrimEditorViewModel.swift` — new observed `volume: Double` (0…1, default 1.0), `isMuted: Bool` (default false), `hasAudio: Bool` (loaded once from `asset.loadTracks(withMediaType: .audio)`). Helpers `setVolume(_:)` and `toggleMute()` mirror to `player.volume` / `player.isMuted` and maintain a `lastNonZeroVolume` so unmuting restores the prior level.
- `Rekam/Features/Editor/TrimEditorView.swift` — new `volumeRow` between transport and export rows: speaker icon button (`speaker.wave.2.fill` / `speaker.slash.fill`) + 0–1 `Slider` + percentage label. Disabled when `!hasAudio` or during export.

## Implementation steps

1. Extend `VideoTrimmer.export` with the two new parameters; collect the composition audio track IDs while inserting tracks and build the `AVMutableAudioMix` if the effective level is below 1.0.
2. Add `volume`, `isMuted`, `hasAudio`, `setVolume`, `toggleMute` to `TrimEditorViewModel`; load `hasAudio` asynchronously in `init`; pass the new args into `trimmer.export`.
3. Add `volumeRow` to `TrimEditorView`.
4. Document phase 14 (this file) and bump the README status line.

## Verification

1. `xcodebuild -scheme Rekam -configuration Debug build` succeeds with no new warnings.
2. Open a recording with audio in the trim editor → drag the volume slider to ~25% while playing → preview audio gets quieter immediately.
3. Click the speaker icon → preview mutes and the icon switches to `speaker.slash.fill`; click again → audio returns at the prior slider value.
4. With **mute** on, export under each preset (Lossless / Smaller / Balanced / Higher) → opened in QuickTime the audio track is missing or fully silent.
5. With volume at 25% and Lossless preset, export → exported audio is at ~25%; the video stream is re-encoded at HighestQuality (preset upgrade is transparent). With volume at 25% under any other preset, audio matches the slider as expected.
6. With volume at 100% and not muted, exported audio is bit-identical to the original under `passthrough`.
5. Open a recording captured with the mic toggle off → the volume row is greyed out and inputs don't respond.
6. Switch the export preset (Lossless → Smaller/Balanced/Higher) with volume at 50% → exported file still respects the level.
7. Open the editor a second time on the same clip → starts back at 100% and unmuted (intentionally not persisted).

## Risks / notes

- `AVAssetExportPresetPassthrough` + `audioMix` is supported on macOS 12+; project deploys macOS 14+.
- Range is capped at 100% — no boosting to avoid clipping in the exported file.
- Volume settings are per-session only; persistence would require sidecar metadata and is out of scope.
- Multi-audio-track recordings (not currently produced by the recorder) would get the same scalar applied to each track; per-track mixing is out of scope.
