import SwiftUI

enum AppFonts {
    static let display = Font.system(size: 22, weight: .medium, design: .default)
    static let title = Font.system(size: 15, weight: .medium, design: .default)
    static let body = Font.system(size: 13, weight: .regular, design: .default)
    static let mono = Font.system(size: 12, weight: .regular, design: .monospaced)
    static let eyebrow = Font.system(size: 10, weight: .medium, design: .default)
}

extension Text {
    func eyebrowStyle() -> some View {
        self
            .font(AppFonts.eyebrow)
            .tracking(1.0)
            .textCase(.uppercase)
            .foregroundStyle(AppColors.textFaint)
    }
}
