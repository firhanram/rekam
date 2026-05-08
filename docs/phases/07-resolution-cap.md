# Phase 7 — Resolution cap

## Goal

Cap recording output to a per-preset maximum long edge (1280 / 1920 / 2560 px) instead of encoding at the source's full pixel resolution. This is the single biggest file-size lever — a 35-second `.balanced` recording on a Retina display should drop from **36 MB → ~12 MB** (~3× reduction).

## Inputs / preconditions

- Phases 0–6 complete; recording end-to-end works.
- Subagent investigation confirmed the root cause: `.balanced` (scale 1.0) on a 1512×982-pt × 2× display feeds the encoder ~3024×1964 (5.94 MP/frame). 5 Mbps spread across that resolution is below VideoToolbox's quality threshold, so the encoder overshoots the bitrate target rather than degrade quality.

## Deliverables

- `Rekam/Core/Capture/CaptureConfiguration.swift`:
  - Replace `scale: Double` with `maxLongEdgePixels: Int?` (nil = no cap).
  - Retuned static presets:

    | Preset | Cap (px) | fps | Bitrate |
    |---|---|---|---|
    | `.smaller` | 1280 | 30 | 1_200_000 |
    | `.balanced` | 1920 | 30 | 2_500_000 |
    | `.higher` | 2560 | 30 | 5_000_000 |

- `Rekam/Core/Capture/ScreenRecorder.swift` (lines ~48–55): replace the `pixelScale * scale` math with a helper that:
  1. Computes full pixel dims = `contentRect.{w,h} * pointPixelScale`.
  2. If `maxLongEdgePixels` is set and the longer edge exceeds it, scales both edges down by the same ratio (preserve aspect ratio).
  3. Snaps both to even integers.

## Implementation steps

1. Update `CaptureConfiguration` — drop `scale`, add `maxLongEdgePixels`, retune the three preset values.
2. Add a private `cappedDimensions(filter:cap:)` helper in `ScreenRecorder` returning `(width: Int, height: Int)`.
3. Replace the existing dim calc with the new helper. Both `AVAssetWriterInput`'s `AVVideoWidthKey/HeightKey` and `SCStreamConfiguration.width/height` use the same numbers.
4. Confirm no UI code reads `.scale` (it doesn't — `RecordingView` only references `.preset`).

## Verification

1. `xcodebuild -scheme Rekam -configuration Debug build` → succeeds, no new warnings.
2. Record 35 s with `.balanced` on a Retina display → output **≤ 14 MB**, plays in QuickTime.
3. `mdls -name kMDItemPixelWidth -name kMDItemPixelHeight <file>` → long edge equals the preset cap.
4. Repeat with `.smaller` → output **≤ 7 MB**.

## Risks / notes

- If the source is *smaller* than the cap, no upscaling — encode at native size.
- Library row's preset badge is unaffected (decorative).
- If sizes still overshoot meaningfully, suspect VideoToolbox is ignoring `AverageBitRate`; fall back to `AVVideoQualityKey: 0.45`. Not expected.
