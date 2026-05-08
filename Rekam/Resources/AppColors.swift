import SwiftUI

enum AppColors {
    // Neutral surfaces
    static let canvas = adaptive(light: 0xFDFCFA, dark: 0x1A1815)
    static let surface = adaptive(light: 0xF7F5F0, dark: 0x201D18)
    static let surfacePlus = adaptive(light: 0xF2EFE9, dark: 0x2A251D)
    static let subtle = adaptive(light: 0xEAE8E3, dark: 0x3A352B)
    static let border = adaptive(light: 0xDDD9D2, dark: 0x3A352B)
    static let muted = adaptive(light: 0xC8C4BC, dark: 0x6A6158)

    // Text scale
    static let textPrimary = adaptive(light: 0x1A1916, dark: 0xE8E6E3)
    static let textSecondary = adaptive(light: 0x3B3A37, dark: 0xC4BEB5)
    static let textTertiary = adaptive(light: 0x6B6760, dark: 0x9A9389)
    static let textPlaceholder = adaptive(light: 0x8C8982, dark: 0x6A6158)
    static let textFaint = adaptive(light: 0xA09D96, dark: 0x5A5549)

    // Brand accent
    static let brandTint50 = adaptive(light: 0xFAF0EA, dark: 0x2A2018)
    static let brandTint100 = adaptive(light: 0xEECFBA, dark: 0x3A2A1A)
    static let brand = adaptive(light: 0xD4622E, dark: 0xD4622E)
    static let brandHover = adaptive(light: 0xC96A2A, dark: 0xE67D22)
    static let brandPressed = adaptive(light: 0xA84E1E, dark: 0xC96A2A)

    // Recording status
    static let recording = adaptive(light: 0xD93025, dark: 0xFF5C52)
    static let recordingBg = adaptive(light: 0xFDEEEC, dark: 0x2E1A18)

    // Semantic
    static let successBg = adaptive(light: 0xEAF5EE, dark: 0x1A2E20)
    static let successText = adaptive(light: 0x1D6B3A, dark: 0x4CAF50)
    static let infoBg = adaptive(light: 0xEBF3FB, dark: 0x1A2535)
    static let infoText = adaptive(light: 0x1E5F8F, dark: 0x42A5F5)
    static let warningBg = adaptive(light: 0xFEF4E6, dark: 0x2E2510)
    static let warningText = adaptive(light: 0x8A5A0B, dark: 0xF3DF31)
    static let errorBg = adaptive(light: 0xFDEEEC, dark: 0x2E1A18)
    static let errorText = adaptive(light: 0x9B2A1E, dark: 0xFF6B6B)

    // Quality preset palette
    static let presetSmallerBg = adaptive(light: 0xEAF5EE, dark: 0x1A2E20)
    static let presetSmallerText = adaptive(light: 0x1D6B3A, dark: 0x4CAF50)
    static let presetBalancedBg = adaptive(light: 0xEBF3FB, dark: 0x1A2535)
    static let presetBalancedText = adaptive(light: 0x1E5F8F, dark: 0x42A5F5)
    static let presetHigherBg = adaptive(light: 0xF0EBF8, dark: 0x251A30)
    static let presetHigherText = adaptive(light: 0x6040A0, dark: 0xAB47BC)

    private static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark]) != nil
            return nsColor(hex: isDark ? dark : light)
        })
    }

    private static func nsColor(hex: UInt32) -> NSColor {
        let r = CGFloat((hex >> 16) & 0xFF) / 255
        let g = CGFloat((hex >> 8) & 0xFF) / 255
        let b = CGFloat(hex & 0xFF) / 255
        return NSColor(srgbRed: r, green: g, blue: b, alpha: 1)
    }
}
