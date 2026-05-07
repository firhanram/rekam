# Rekam — Architecture

A macOS 15.1 SwiftUI app for recording the screen, trimming clips, and exporting size-optimized videos.

**Confirmed scope**

- Capture: display + window/region + system audio + microphone
- Output: HEVC (H.265) in `.mp4`
- Destination: `~/Downloads`

---

## 1. Technology choices

| Concern | Choice | Why |
|---|---|---|
| Screen capture | **ScreenCaptureKit** (`SCStream`, `SCContentSharingPicker`) | Apple's modern, hardware-accelerated capture API. Required for window/region selection on macOS 14+. Replaces the deprecated CGDisplayStream. |
| System audio | `SCStream` audio output | ScreenCaptureKit delivers system audio CMSampleBuffers in the same stream — no virtual audio driver needed. |
| Microphone | `AVCaptureSession` → `AVCaptureAudioDataOutput` | Mic is independent of `SCStream`; mixed in at write time. |
| Encoding (live) | **`AVAssetWriter`** with one HEVC video input + two AAC audio inputs (system + mic) | Streams CMSampleBuffers straight to disk; no intermediate uncompressed file. |
| Codec | **HEVC** (`AVVideoCodecType.hevc`) in `.mp4` | ~30–50% smaller than H.264 at equivalent quality on Apple Silicon. Hardware-encoded via VideoToolbox. |
| Trim / export | **`AVMutableComposition` + `AVAssetExportSession`** with `AVAssetExportPresetHEVCHighestQuality` (passthrough when no re-encode needed) | Native, GPU-accelerated. Passthrough avoids quality loss for pure trims. |
| Playback / scrubber | `AVPlayer` + `AVPlayerView` (AppKit-backed via `NSViewRepresentable`) | Frame-accurate seeking for trim handles. |
| UI | SwiftUI + small AppKit bridges (`AVPlayerView`, `NSSavePanel` fallback) | Project is already SwiftUI. |
| Architecture pattern | **MVVM** with `@Observable` view models | Idiomatic for SwiftUI on macOS 15. |
| Concurrency | Swift Concurrency (`async`/`await`, `actor` for the recorder) | Capture callbacks are off-main; an `actor` serializes writer state safely. |

---

## 2. Folder layout

```
Rekam/
├── RekamApp.swift                  // existing
├── ContentView.swift               // existing — becomes RootView
├── Features/
│   ├── Recording/
│   │   ├── RecordingView.swift
│   │   ├── RecordingViewModel.swift
│   │   └── RecordingControls.swift
│   ├── Library/
│   │   ├── LibraryView.swift
│   │   └── LibraryViewModel.swift
│   └── Editor/
│       ├── TrimEditorView.swift
│       ├── TrimEditorViewModel.swift
│       ├── TrimSliderView.swift
│       └── PlayerContainer.swift   // NSViewRepresentable<AVPlayerView>
└── Core/
    ├── Capture/
    │   ├── ScreenRecorder.swift            // actor — owns SCStream + AVAssetWriter
    │   ├── CaptureConfiguration.swift      // resolution, fps, bitrate, codec
    │   ├── ContentPicker.swift             // wraps SCContentSharingPicker
    │   └── MicrophoneCapture.swift         // AVCaptureSession wrapper
    ├── Export/
    │   ├── VideoTrimmer.swift              // AVMutableComposition + ExportSession
    │   └── ExportPresets.swift             // HEVC quality presets
    └── Storage/
        ├── RecordingStore.swift            // enumerates files, metadata
        └── Paths.swift                     // Downloads folder resolution
```

---

## 3. Data flow

### 3.1 Recording pipeline

```
SCContentSharingPicker  ─┐
                         ▼
                ┌──────────────────┐  video CMSampleBuffer (BGRA)
                │     SCStream     │ ─────────────────────────────┐
                └──────────────────┘                               │
                         │ system audio CMSampleBuffer             │
                         ▼                                         │
                ┌──────────────────┐  mic CMSampleBuffer           │
                │ AVCaptureSession │ ──┐                           │
                └──────────────────┘   │                           │
                                       ▼                           ▼
                              ┌────────────────────────────────────────┐
                              │            AVAssetWriter               │
                              │  videoInput (HEVC) + audio×2 (AAC)     │
                              │            → .mp4 on disk              │
                              └────────────────────────────────────────┘
```

- `ScreenRecorder` is an `actor`. It owns the `SCStream`, the mic `AVCaptureSession`, and the `AVAssetWriter`.
- Sample-buffer delegate callbacks forward into the actor via `Task { await recorder.append(...) }`.
- Writer is started on the **first video sample's PTS** to keep tracks aligned.

### 3.2 Trim & export pipeline

```
recording.mp4  →  AVURLAsset
                       ▼
              AVMutableComposition
              (insert [start..end] of video + audio tracks)
                       ▼
              AVAssetExportSession
              preset = HEVCHighestQuality
              (or passthrough if no re-encode)
                       ▼
              ~/Downloads/Rekam-<timestamp>.mp4
```

---

## 4. Encoding settings (size-optimized)

`CaptureConfiguration` defaults:

| Setting | Value | Rationale |
|---|---|---|
| Codec | `kCMVideoCodecType_HEVC` | Best size/quality on Apple Silicon. |
| Pixel format | `kCVPixelFormatType_32BGRA` (capture) | SCK default; encoder converts internally. |
| Frame rate | **30 fps** (configurable 24/30/60) | 30 is plenty for screencasts; 60 nearly doubles bitrate. |
| Bitrate | **~5 Mbps @ 1080p, ~12 Mbps @ 4K** target average | Tunable per preset. |
| Keyframe interval | 2 seconds | Balances seekability and compression. |
| Profile | HEVC Main | Broad compatibility. |
| Color | BT.709, automatic transfer | Matches typical displays. |
| Audio | AAC-LC, 128 kbps stereo, 48 kHz | Standard, small. |
| Scaling | Capture at output resolution; optional 0.5/0.75 downscale in "smaller file" mode | Downscaling is the single biggest size lever. |

UI exposes three presets: **Smaller file / Balanced / Higher quality** — each tweaks bitrate + scale factor.

---

## 5. Permissions & entitlements

`Rekam.entitlements`:

```xml
<key>com.apple.security.app-sandbox</key><true/>
<key>com.apple.security.device.audio-input</key><true/>           <!-- mic -->
<key>com.apple.security.files.downloads.read-write</key><true/>   <!-- write to Downloads -->
<key>com.apple.security.files.user-selected.read-write</key><true/> <!-- Save As... fallback -->
```

`Info.plist`:

- `NSMicrophoneUsageDescription` — "Rekam records your microphone alongside the screen."

Screen recording is gated by **TCC** (system prompt on first `SCShareableContent.current`); no entitlement required, but the user must approve once in System Settings → Privacy & Security → Screen Recording.

---

## 6. State model

```swift
enum RecorderState {
    case idle
    case preparing
    case recording(startedAt: Date)
    case stopping
    case failed(Error)
}

struct RecordingItem: Identifiable, Hashable {
    let id: UUID
    let url: URL
    let createdAt: Date
    let duration: CMTime
    let sizeBytes: Int64
}

struct TrimSelection {
    var start: CMTime
    var end: CMTime
}
```

`RecordingViewModel` owns `RecorderState`. `TrimEditorViewModel` owns the `AVPlayer`, the loaded asset, and `TrimSelection`.

---

## 7. UI flow

1. **RootView** — split/tab layout: `Record` | `Library`.
2. **Record tab** — quality preset picker, "Choose source…" (opens `SCContentSharingPicker`), record button, elapsed timer, mic + system-audio toggles.
3. **Library tab** — list/grid of `RecordingItem`s; click opens **TrimEditorView**.
4. **TrimEditor** — `AVPlayer` preview, dual-handle range slider, "Export" → `VideoTrimmer` → `~/Downloads/Rekam-<timestamp>.mp4` → reveal in Finder.

---

## 8. Risks & follow-ups

- **Sandbox + Downloads writes** — `files.downloads.read-write` enables direct writes; fallback to `NSSavePanel` if denied.
- **Mic / system audio sync drift** — use sample PTS as-is; do not retime. Small drift is acceptable.
- **Long recordings** — `AVAssetWriter` finalizes a single moov atom; a crash mid-recording corrupts the file. Future mitigation: segmenting via `AVAssetWriterDelegate`.
- **Cursor visibility** — `SCStreamConfiguration.showsCursor = true` by default. Expose a toggle later if needed.

---

## 9. Implementation order

`Core/Capture` → `Features/Recording` → `Core/Storage` → `Features/Library` → `Core/Export` → `Features/Editor`.

Smoke-test after each module: record a 10s clip, verify the file in `~/Downloads`, trim it, re-export.
