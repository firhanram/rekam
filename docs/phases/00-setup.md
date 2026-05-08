# Phase 0 — Project setup

## Goal

Prepare the Xcode project so subsequent phases can plug in without yak-shaving: entitlements declared, mic usage description set, source folders scaffolded, and a minimal `RootView` shell visible at launch.

## Inputs / preconditions

- Empty `Rekam` Xcode project already scaffolded (macOS 15.1, SwiftUI, sandboxed).
- macOS 15.1+ dev machine.

## Deliverables

- `Rekam/Rekam.entitlements` — add mic + Downloads + user-selected read/write entitlements.
- `Info.plist` (or build-settings INFOPLIST keys) — add `NSMicrophoneUsageDescription`.
- Empty folder structure on disk and in the Xcode project:
  - `Rekam/Features/{Recording,Library,Editor}/`
  - `Rekam/Core/{Capture,Export,Storage}/`
- `Rekam/ContentView.swift` → renamed/refactored into `RootView` with a placeholder split view (`Record` | `Library`).

## Implementation steps

1. Open `Rekam.entitlements`. Add:
   - `com.apple.security.device.audio-input` = `true`
   - `com.apple.security.files.downloads.read-write` = `true`
   - `com.apple.security.files.user-selected.read-write` = `true` (replace the existing read-only entitlement).
2. Add `NSMicrophoneUsageDescription` = `"Rekam records your microphone alongside the screen."` to the target's Info settings.
3. Create the folder groups in Xcode (mirroring the on-disk layout from `ARCHITECTURE.md` §2). Empty `.swift` placeholder files are fine.
4. Refactor `ContentView` into `RootView` with a `NavigationSplitView` (sidebar with two items: Record / Library) and two empty destination views.
5. Update `RekamApp.swift` to use `RootView()`.

## Verification

- `xcodebuild -scheme Rekam build` succeeds with no warnings.
- App launches; window shows the split layout with the two empty tabs.
- Privacy & Security panel shows nothing yet (no capture attempted).

## Risks / notes

- Removing the existing `files.user-selected.read-only` entitlement is intentional — the `read-write` variant supersedes it.
- Don't request screen recording or mic permission yet; the OS prompts on first actual use.
