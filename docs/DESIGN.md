# Design system

Claude-inspired dual-mode theme for Rekam. Warm off-whites in light mode, warm dark browns in dark mode. Coral-orange accent throughout.

All tokens live in `Rekam/Resources/AppColors.swift`, `AppFonts.swift`, `AppSpacing.swift`.

Color mode is user-selectable: **Automatic** (follows system), **Light**, or **Dark**. Set via Settings → Appearance.

---

## Colors

All colors are adaptive — they resolve automatically based on the active color scheme.

### Neutral surfaces

| Token | Light | Dark | Swift constant | Usage |
|---|---|---|---|---|
| Canvas | `#FDFCFA` | `#1A1815` | `AppColors.canvas` | Main window background |
| Surface | `#F7F5F0` | `#201D18` | `AppColors.surface` | Sidebar, panel backgrounds |
| Surface+ | `#F2EFE9` | `#2A251D` | `AppColors.surfacePlus` | Timeline track, input backgrounds |
| Subtle | `#EAE8E3` | `#3A352B` | `AppColors.subtle` | Section dividers, subtle fills |
| Border | `#DDD9D2` | `#3A352B` | `AppColors.border` | Default borders, separators |
| Muted | `#C8C4BC` | `#6A6158` | `AppColors.muted` | Disabled borders, placeholders |

### Text scale

| Token | Light | Dark | Swift constant | Usage |
|---|---|---|---|---|
| Primary | `#1A1916` | `#E8E6E3` | `AppColors.textPrimary` | Main text, headings |
| Secondary | `#3B3A37` | `#C4BEB5` | `AppColors.textSecondary` | Body text, labels |
| Tertiary | `#6B6760` | `#9A9389` | `AppColors.textTertiary` | Supporting text, captions |
| Placeholder | `#8C8982` | `#6A6158` | `AppColors.textPlaceholder` | Input placeholders, hints |
| Faint | `#A09D96` | `#5A5549` | `AppColors.textFaint` | Section labels, eyebrows |

### Brand accent — Claude orange-coral

| Token | Light | Dark | Swift constant | Usage |
|---|---|---|---|---|
| Tint 50 | `#FAF0EA` | `#2A2018` | `AppColors.brandTint50` | Hover backgrounds |
| Tint 100 | `#EECFBA` | `#3A2A1A` | `AppColors.brandTint100` | Active borders, trim-range fill |
| Primary | `#D4622E` | `#D4622E` | `AppColors.brand` | Record button, CTA, active selection, scrubber playhead |
| Hover | `#C96A2A` | `#E67D22` | `AppColors.brandHover` | Hover state |
| Pressed | `#A84E1E` | `#C96A2A` | `AppColors.brandPressed` | Pressed / active state |

### Recording status — pulsing red

A dedicated red is used **only** for the live "REC" indicator and elapsed-time chip while a capture is in progress. Brand orange remains the primary CTA; red is reserved so it always reads as "recording right now."

| Token | Light | Dark | Swift constant | Usage |
|---|---|---|---|---|
| Recording | `#D93025` | `#FF5C52` | `AppColors.recording` | Live REC dot, recording-state chip |
| Recording Bg | `#FDEEEC` | `#2E1A18` | `AppColors.recordingBg` | Background for the REC chip |

### Semantic — status & feedback

| Token | Light Bg | Dark Bg | Light Text | Dark Text | Swift bg constant | Usage |
|---|---|---|---|---|---|---|
| Success | `#EAF5EE` | `#1A2E20` | `#1D6B3A` | `#4CAF50` | `AppColors.successBg` | Export complete, saved |
| Info | `#EBF3FB` | `#1A2535` | `#1E5F8F` | `#42A5F5` | `AppColors.infoBg` | Informational toasts |
| Warning | `#FEF4E6` | `#2E2510` | `#8A5A0B` | `#F3DF31` | `AppColors.warningBg` | Permission needed, large file |
| Error | `#FDEEEC` | `#2E1A18` | `#9B2A1E` | `#FF6B6B` | `AppColors.errorBg` | Capture failed, export failed |

### Quality preset palette

Used on the preset segmented control and the metadata badge in the Library row.

| Preset | Light Bg | Dark Bg | Light Text | Dark Text | Swift constant |
|---|---|---|---|---|---|
| Smaller | `#EAF5EE` | `#1A2E20` | `#1D6B3A` | `#4CAF50` | `AppColors.presetSmaller` |
| Balanced | `#EBF3FB` | `#1A2535` | `#1E5F8F` | `#42A5F5` | `AppColors.presetBalanced` |
| Higher | `#F0EBF8` | `#251A30` | `#6040A0` | `#AB47BC` | `AppColors.presetHigher` |

---

## Typography

All fonts are native — SF Pro Display, SF Pro Text, SF Mono. Zero imports.

| Role | Size | Weight | Font | Swift constant |
|---|---|---|---|---|
| Display | 22pt | 500 | SF Pro Display | `AppFonts.display` |
| Title | 15pt | 500 | SF Pro Display | `AppFonts.title` |
| Body | 13pt | 400 | SF Pro Text | `AppFonts.body` |
| Mono | 12pt | 400 | SF Mono | `AppFonts.mono` |
| Eyebrow | 10pt | 500 | SF Pro Text | `AppFonts.eyebrow` |

**Rules:**
- Eyebrow labels: `0.10em` letter spacing, all caps.
- SF Mono used for: timecodes (00:01:23.456), elapsed-recording timer, file size, bitrate, resolution.

---

## Spacing scale

All values as `CGFloat` in `AppSpacing`.

| Token | Value | Swift constant | Usage |
|---|---|---|---|
| xs | 4 | `AppSpacing.xs` | Icon padding, tight gaps |
| sm | 8 | `AppSpacing.sm` | Internal component gaps |
| md | 12 | `AppSpacing.md` | Row padding |
| lg | 16 | `AppSpacing.lg` | Panel padding |
| xl | 24 | `AppSpacing.xl` | Section gaps |
| xxl | 32 | `AppSpacing.xxl` | Large section gaps |
| xxxl | 48 | `AppSpacing.xxxl` | Page-level spacing |

---

## Corner radius

| Token | Value | Swift constant | Usage |
|---|---|---|---|
| Badge | 3 | `AppSpacing.radiusBadge` | Preset badges, status pills |
| Input | 5 | `AppSpacing.radiusInput` | Text inputs, scrubber handles |
| Card | 7 | `AppSpacing.radiusCard` | Sidebar rows, library list items |
| Panel | 10 | `AppSpacing.radiusPanel` | Player container, sheets, cards |
| Pill | 20 | `AppSpacing.radiusPill` | Record button, REC chip |

---

## Elevation

### Light mode

| Level | Background | Border | Shadow | Usage |
|---|---|---|---|---|
| 0 | `#F7F5F0` | `#EAE8E3` | none | Sidebar background |
| 1 | `#FDFCFA` | `#DDD9D2` | 0 1 3px rgba(0,0,0,.05) | Cards, panels |
| 2 | `#FFFFFF` | `#DDD9D2` | 0 2 8px rgba(0,0,0,.07) | Dropdowns, popovers |
| 3 | `#FFFFFF` | `#DDD9D2` | 0 4 16px rgba(0,0,0,.10) | Modals, trim-editor sheet |

### Dark mode

| Level | Background | Border | Shadow | Usage |
|---|---|---|---|---|
| 0 | `#201D18` | `#3A352B` | none | Sidebar background |
| 1 | `#1A1815` | `#3A352B` | 0 1 3px rgba(0,0,0,.20) | Cards, panels |
| 2 | `#2A251D` | `#3A352B` | 0 2 8px rgba(0,0,0,.25) | Dropdowns, popovers |
| 3 | `#2A251D` | `#3A352B` | 0 4 16px rgba(0,0,0,.30) | Modals, trim-editor sheet |

---

## Icon system

Native SF Symbols only — no third-party icon libs.

| Icon | SF Symbol name | Usage |
|---|---|---|
| Record | `record.circle` | Record button (idle state) |
| Recording | `record.circle.fill` | Record button (active, tinted `recording`) |
| Stop | `stop.fill` | Stop button while recording |
| Play | `play.fill` | Play in trim editor |
| Pause | `pause.fill` | Pause in trim editor |
| Trim | `scissors` | Trim editor entry, range slider handles |
| Export | `square.and.arrow.up` | Export to Downloads |
| Reveal | `folder` | Reveal in Finder |
| Library | `film.stack` | Library tab in sidebar |
| Source | `rectangle.on.rectangle` | "Choose source…" / SCContentSharingPicker |
| Mic on | `mic.fill` | Mic toggle (on) |
| Mic off | `mic.slash` | Mic toggle (off) |
| System audio | `speaker.wave.2.fill` | System-audio toggle (on) |
| System audio off | `speaker.slash` | System-audio toggle (off) |
| Trash | `trash` | Delete recording |
| Settings | `gear` | Settings button |
| Chevron | `chevron.right` | Disclosure / row affordance |
| Checkmark | `checkmark` | Success states |
| Xmark | `xmark` | Close, cancel |

---

## Component recipes

Concrete combinations of the tokens above. These are the canonical looks for Rekam's primary UI surfaces.

### Record button (primary CTA)

- Idle: pill (radius `radiusPill`), bg `brand`, fg white, icon `record.circle`, label `Record` (`AppFonts.title`).
- Hover: bg `brandHover`.
- Pressed: bg `brandPressed`.
- Recording: bg `recordingBg`, fg `recording`, icon `stop.fill`, label `Stop` + monospace elapsed time `00:00:12`. The leading dot pulses (1s ease in/out, 60% → 100% opacity).

### Quality preset segmented control

Three pills (`radiusBadge`) labeled **Smaller / Balanced / Higher**. Selected pill uses the matching `presetSmaller/Balanced/Higher` background + text colors. Unselected pill: bg `surfacePlus`, fg `textTertiary`.

### Library row

- Container: `radiusCard`, bg `surface`, border `border`, padding `md`.
- Hover: bg `brandTint50`, border `brandTint100`.
- Layout: thumbnail (16:9, `radiusInput`) ─ title (`AppFonts.title`, `textPrimary`) + subtitle (`AppFonts.body`, `textTertiary`, mono for size + duration) ─ trailing chevron (`textFaint`).

### Trim slider

- Track: height 6, bg `surfacePlus`, `radiusBadge`.
- Selected range: bg `brandTint100` light / `brand` dark at 40% alpha.
- Handles: 14×24, bg `brand`, `radiusInput`, icon `scissors` rotated 90° at `textFaint` opacity 60%.
- Playhead: 2px vertical line, color `brand`, ignores hit-testing.
- Timecode chips above each handle: `AppFonts.mono`, `textSecondary`, bg `surface`, `radiusBadge`, padding `xs`.

### Player container

- Outer: bg `canvas`, `radiusPanel`, elevation level 1.
- Letterbox bars use `surfacePlus`.
- Custom transport bar below the video: bg `surface`, divider `border`, controls `textSecondary` with `brand` for the active play/pause state.

---

## Motion

- **REC pulse**: 1.0s ease-in-out, opacity 0.6 → 1.0 → 0.6, infinite.
- **Hover transitions**: 120ms ease-out for color/background changes.
- **Sheet present/dismiss**: system default (`.sheet`).
- **Export progress**: linear interpolation; never spring — progress should look mechanical, not bouncy.
- **No emoji, no decorative animation**: motion is reserved for state communication (recording, exporting, hover).
