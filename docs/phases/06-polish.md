# Phase 6 — Polish & hardening

## Goal

Take the working app from Phase 5 and make it shippable: graceful errors, edge-case handling, accessibility passes, app icon, and a basic performance check on long recordings.

## Inputs / preconditions

- Phases 0–5 complete; the full record → library → trim → export loop works.

## Deliverables

- **Error surfacing**: a single `ErrorAlertModifier` that turns any thrown error in a view model into a user-facing alert with a friendly message + a "Copy details" button.
- **Permission helpers**: a startup check that detects denied screen-recording / mic permissions and routes the user to the relevant System Settings pane via `x-apple.systempreferences:` URLs.
- **`NSSavePanel` fallback**: when writing to `~/Downloads` fails, prompt the user for a destination instead.
- **Edge-case handling**:
  - Disk full while recording → stop cleanly, surface error.
  - Source disappearing mid-recording (e.g. window closed) → finalize what we have.
  - Empty trim range → disabled Export button.
- **Accessibility**: VoiceOver labels on all controls; keyboard shortcuts for Record (`⌘R`), Stop (`⌘.`), Play/Pause (`Space`), Export (`⌘E`).
- **App icon**: replace placeholder in `Assets.xcassets` with a designed icon set.
- **Performance check**: record 10 minutes at 1080p30 `.balanced` preset. Confirm:
  - File size roughly matches the bitrate × duration math (~5 Mbps × 600s ≈ 375 MB, allowing headroom for audio).
  - Memory stays flat (no continuous growth — leaks would indicate sample-buffer retention).
  - CPU dominated by VideoToolbox encoder, not our actor message loop.

## Implementation steps

1. Add `ErrorAlertModifier` in `Rekam/Features/Shared/` (create folder if needed); apply at `RootView` level via environment.
2. Implement permission checks with `CGPreflightScreenCaptureAccess()` and `AVCaptureDevice.authorizationStatus(for: .audio)`.
3. Refactor export path to attempt direct write, catch sandbox failure, fall back to `NSSavePanel`.
4. Audit each view for `.accessibilityLabel`/`.accessibilityHint`. Add `.keyboardShortcut` modifiers.
5. Replace app icon assets.
6. Run the 10-minute profiling session in Instruments (Time Profiler + Allocations). File any findings as TODOs.

## Verification

- Manually deny screen-recording permission → app shows a clear message + button that opens the right Settings pane.
- Manually fill `~/Downloads` (or simulate by exporting to a read-only path) → `NSSavePanel` appears.
- VoiceOver navigation reaches every control with a sensible label.
- All keyboard shortcuts trigger their actions.
- 10-minute recording profile shows flat memory and the expected file size.

## Risks / notes

- Don't gold-plate. This phase is "make rough edges smooth," not "add new features." If something here grows into a real feature, defer it to a v2 plan.
- Instruments runs are time-consuming; one good 10-minute run beats five rushed ones.
