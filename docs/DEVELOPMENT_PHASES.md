# Rekam — Development Phases

This document breaks the implementation defined in [`ARCHITECTURE.md`](./ARCHITECTURE.md) into six sequential, independently-verifiable phases. Each phase has its own detail document under [`phases/`](./phases/).

The order follows the architecture's "Implementation order" section: build the capture engine first, then the recording UI, then storage and library browsing, then trim/export. Each phase produces a runnable app you can smoke-test before moving on.

| # | Phase | Goal | Detail |
|---|---|---|---|
| 0 | **Project setup** | Entitlements, Info.plist, folder scaffold, RootView shell | [`phases/00-setup.md`](./phases/00-setup.md) |
| 1 | **Capture core** | Record screen + system audio + mic to an `.mp4` file via `SCStream` + `AVAssetWriter` | [`phases/01-capture-core.md`](./phases/01-capture-core.md) |
| 2 | **Recording UI** | SwiftUI `RecordingView` driving the capture engine; quality presets; source picker | [`phases/02-recording-ui.md`](./phases/02-recording-ui.md) |
| 3 | **Storage & Library** | Persist recordings, list them with metadata, reveal in Finder | [`phases/03-storage-library.md`](./phases/03-storage-library.md) |
| 4 | **Trim & Export** | Trim a recording to `[start..end]` and export HEVC `.mp4` to `~/Downloads` | [`phases/04-trim-export.md`](./phases/04-trim-export.md) |
| 5 | **Editor UI** | `TrimEditorView` with `AVPlayer` preview and dual-handle range slider | [`phases/05-editor-ui.md`](./phases/05-editor-ui.md) |
| 6 | **Polish & hardening** | Error handling, edge cases, accessibility, app icon, basic perf checks | [`phases/06-polish.md`](./phases/06-polish.md) |
| 7 | **Resolution cap** | Cap output to per-preset long-edge pixels and retune bitrates to shrink files | [`phases/07-resolution-cap.md`](./phases/07-resolution-cap.md) |
| 8 | **Encoder tuning** | Encoder hints + audio bitrate retune for additional savings on top of phase 7 | [`phases/08-encoder-tuning.md`](./phases/08-encoder-tuning.md) |
| 9 | **Rename on export** | Always prompt with NSSavePanel so the user can choose filename and folder | [`phases/09-rename-on-export.md`](./phases/09-rename-on-export.md) |
| 10 | **Drop `Rekam-` prefix** | Default filenames are just `<timestamp>.mp4` — less noise in Library and save panel | [`phases/10-drop-rekam-prefix.md`](./phases/10-drop-rekam-prefix.md) |
| 11 | **Keep recording alive on tab switch** | Lift view models to `RootView` so switching to Library doesn't kill an active capture | [`phases/11-keep-recording-alive-on-tab-switch.md`](./phases/11-keep-recording-alive-on-tab-switch.md) |

## Conventions for each phase doc

Every phase document follows the same structure:

1. **Goal** — one paragraph: what the phase delivers.
2. **Inputs / preconditions** — what must already exist (previous phase, permissions, etc.).
3. **Deliverables** — concrete files added or modified.
4. **Implementation steps** — ordered task list.
5. **Verification** — how to manually smoke-test the result.
6. **Risks / notes** — known pitfalls specific to this phase.

## Done definition (per phase)

A phase is "done" when:

- All deliverables exist and compile (`xcodebuild` clean build, no warnings introduced).
- The verification steps pass on the developer's machine.
- A commit is created on `main` with a Conventional Commit subject scoped to the phase (e.g. `feat(capture): record screen + audio to mp4`).
