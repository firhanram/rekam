# Phase 8 — Encoder + audio tuning

## Goal

Add the small-but-cumulative refinements: tell the encoder our frame rate, lengthen GOPs, and trim audio bitrates. Expected additional **10–15 %** size reduction on top of Phase 7.

## Inputs / preconditions

- Phase 7 complete (resolution cap in place).

## Deliverables

- `Rekam/Core/Capture/ScreenRecorder.swift` — inside `AVVideoCompressionPropertiesKey`:
  - **Add** `AVVideoExpectedSourceFrameRateKey: configuration.frameRate` — gives VideoToolbox explicit fps for ABR math.
  - **Change** `AVVideoMaxKeyFrameIntervalDurationKey` from `2.0` → `4.0` seconds. Longer GOPs help compression for low-motion screencasts.
- Audio settings split into two dictionaries:
  - System audio: stereo, **96 kbps** (down from 128).
  - Microphone: **mono, 64 kbps** (down from stereo 128).

  Combined audio bitrate: 160 kbps (down from 256). Saves ~0.7 MB / minute.

## Implementation steps

1. Update the video compression-properties dict with the two new/changed keys.
2. Replace the single `audioSettings` dict with `systemAudioSettings` and `micAudioSettings`. Apply each to its corresponding `AVAssetWriterInput`.
3. No UI changes.

## Verification

1. `xcodebuild -scheme Rekam -configuration Debug build` → succeeds, no warnings.
2. Re-record 35 s with `.balanced` → output ~10–12 MB (slightly below Phase 7).
3. Open in QuickTime: verify both audio tracks remain audible; spoken voice on the mic track is clear.
4. (Optional) `ffprobe` the file: confirm video has `r_frame_rate=30/1` and audio tracks report 96k / 64k.

## Risks / notes

- Longer GOPs (4 s keyframes) are fine for screencasts (low motion). Trim seek precision is unaffected — Editor uses `tolerance: .zero` and falls back to nearest keyframe automatically.
- Don't set `AVVideoQualityKey` alongside `AverageBitRate` — they're mutually exclusive.
- Mono mic at 64 kbps AAC-LC is transparent for voice; if a future user wants stereo mic input we can promote to 96 kbps stereo behind the same toggle.
