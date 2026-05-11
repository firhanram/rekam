# Rekam

A small, size-optimized screen recorder for macOS. Capture a window, region, or display — with system audio and your choice of microphone — then trim and export to HEVC `.mp4`.

Built with SwiftUI + ScreenCaptureKit + AVFoundation. Sandboxed. macOS 15.1+.

## Features

- **Capture** a display, an app window, an arbitrary region, or all windows of an app via the system `SCContentSharingPicker`.
- **Audio** — system audio (captured by ScreenCaptureKit) plus a microphone of your choice (built-in, USB, AirPods, audio interface). Hot-plugged devices show up automatically.
- **Quality presets** — `Smaller / Balanced / Higher`. Output is capped at `1280 / 1920 / 2560` long-edge pixels and ~`1.2 / 2.5 / 5 Mbps` HEVC, so files stay small without visible quality loss for screencasts.
- **Library** — every recording is listed with duration, size, and a relative date. Right-click for Reveal in Finder, Export, or Delete.
- **Trim editor** — dual-handle range slider with frame-accurate scrubbing, monospaced timecode chips, and `AVPlayer` preview. Keyboard shortcuts for play/pause (`Space`), export (`⌘E`), close (`Esc`).
- **Export** — opens an `NSSavePanel` so you can rename and pick a folder. Defaults to `~/Downloads`.

## Quick start

```bash
git clone <repo-url> Rekam
cd Rekam
open Rekam.xcodeproj
# Cmd-R to run
```

On first launch, macOS will prompt for screen recording and microphone permission. After granting them, choose a source from the Record tab and hit **Record** (or press `⌘R`). Stop with `⌘.`.

## Architecture

The codebase is split into reusable core modules and feature modules:

```
Rekam/
├── Core/
│   ├── Capture/       # ScreenRecorder actor + SCStream/AVAssetWriter wiring
│   ├── Export/        # AVMutableComposition trimmer + NSSavePanel resolver
│   └── Storage/       # Paths, RecordingStore, RecordingItem
├── Features/
│   ├── Recording/     # RecordingView + RecordingViewModel
│   ├── Library/       # LibraryView + LibraryViewModel
│   └── Editor/        # TrimEditorView + TrimEditorViewModel
└── Resources/         # AppColors / AppFonts / AppSpacing (Claude-themed)
```

Details:

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — tech choices, data flow, encoding settings, permissions.
- [`docs/DESIGN.md`](docs/DESIGN.md) — Claude-inspired design system (dual-mode tokens, components, motion).
- [`docs/DEVELOPMENT_PHASES.md`](docs/DEVELOPMENT_PHASES.md) — phased implementation index, with one detail doc per phase under [`docs/phases/`](docs/phases/).

## File-size strategy

Apple's built-in screen recorder produces large files because it encodes at the source's full pixel resolution. Rekam:

- caps output to a per-preset long edge (1280 / 1920 / 2560 px),
- targets screencast-realistic HEVC bitrates (1.2 / 2.5 / 5 Mbps),
- tells VideoToolbox the source frame rate explicitly,
- uses 4-second GOPs (fine for low-motion content),
- encodes system audio as 96 kbps stereo and the mic as 64 kbps mono AAC-LC.

A 35-second `.balanced` capture on a Retina display lands around **10–13 MB** rather than the ~36 MB you'd get without these tweaks.

## Permissions

Granted via the system TCC prompts on first use. The app declares:

- `com.apple.security.app-sandbox`
- `com.apple.security.device.audio-input`
- `com.apple.security.files.downloads.read-write`
- `com.apple.security.files.user-selected.read-write`
- `NSMicrophoneUsageDescription` in `Info.plist`

Screen recording itself is gated by TCC, not entitlements — approve once in **System Settings → Privacy & Security → Screen Recording**.

## Status

The app ships the full record → library → trim → export loop, plus polish (permission helpers, save-panel fallback, accessibility, keyboard shortcuts). Phases 7–12 documented under [`docs/phases/`](docs/phases/) cover size tuning, rename-on-export, the microphone picker, and the tab-switch fix.
