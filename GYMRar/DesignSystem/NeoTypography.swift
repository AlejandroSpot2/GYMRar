//
//  NeoTypography.swift
//  GYMRar
//
//  Neobrutalism typography scale with bold weights
//

import SwiftUI

enum NeoFont {
    // MARK: - Display (Large Headers)

    /// 34pt black - Hero text
    static let displayLarge = Font.system(size: 34, weight: .black)

    /// 28pt black - Section headers
    static let displayMedium = Font.system(size: 28, weight: .black)

    /// 24pt black - Sub-section headers
    static let displaySmall = Font.system(size: 24, weight: .black)

    // MARK: - Headlines

    /// 20pt bold - Card titles
    static let headlineLarge = Font.system(size: 20, weight: .bold)

    /// 17pt bold - List item titles
    static let headlineMedium = Font.system(size: 17, weight: .bold)

    /// 15pt bold - Inline headers
    static let headlineSmall = Font.system(size: 15, weight: .bold)

    // MARK: - Body

    /// 17pt semibold - Primary body text
    static let bodyLarge = Font.system(size: 17, weight: .semibold)

    /// 15pt medium - Secondary body text
    static let bodyMedium = Font.system(size: 15, weight: .medium)

    /// 13pt medium - Tertiary body text
    static let bodySmall = Font.system(size: 13, weight: .medium)

    // MARK: - Labels (Always uppercase in neo style)

    /// 14pt bold - Large labels
    static let labelLarge = Font.system(size: 14, weight: .bold)

    /// 12pt bold - Medium labels
    static let labelMedium = Font.system(size: 12, weight: .bold)

    /// 10pt bold - Small labels
    static let labelSmall = Font.system(size: 10, weight: .bold)

    // MARK: - Numeric (Monospaced for weights, reps, etc.)

    /// 20pt black monospaced - Large numbers
    static let numeric = Font.system(size: 20, weight: .black, design: .monospaced)

    /// 16pt bold monospaced - Small numbers
    static let numericSmall = Font.system(size: 16, weight: .bold, design: .monospaced)
}

// MARK: - Neo Label Style Modifier

struct NeoLabelStyle: ViewModifier {
    let font: Font
    let colorScheme: ColorScheme

    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundStyle(NeoColors.text(for: colorScheme))
            .textCase(.uppercase)
    }
}

extension View {
    func neoLabel(
        font: Font = NeoFont.labelMedium,
        colorScheme: ColorScheme
    ) -> some View {
        modifier(NeoLabelStyle(font: font, colorScheme: colorScheme))
    }
}

// MARK: - Preview

#Preview("Neo Typography - Light") {
    NeoTypographyPreview()
        .preferredColorScheme(.light)
}

#Preview("Neo Typography - Dark") {
    NeoTypographyPreview()
        .preferredColorScheme(.dark)
}

private struct NeoTypographyPreview: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    Text("DISPLAY")
                        .neoLabel(font: NeoFont.labelSmall, colorScheme: colorScheme)
                    Text("Display Large").font(NeoFont.displayLarge)
                    Text("Display Medium").font(NeoFont.displayMedium)
                    Text("Display Small").font(NeoFont.displaySmall)
                }

                Divider()

                Group {
                    Text("HEADLINES")
                        .neoLabel(font: NeoFont.labelSmall, colorScheme: colorScheme)
                    Text("Headline Large").font(NeoFont.headlineLarge)
                    Text("Headline Medium").font(NeoFont.headlineMedium)
                    Text("Headline Small").font(NeoFont.headlineSmall)
                }

                Divider()

                Group {
                    Text("BODY")
                        .neoLabel(font: NeoFont.labelSmall, colorScheme: colorScheme)
                    Text("Body Large").font(NeoFont.bodyLarge)
                    Text("Body Medium").font(NeoFont.bodyMedium)
                    Text("Body Small").font(NeoFont.bodySmall)
                }

                Divider()

                Group {
                    Text("LABELS")
                        .neoLabel(font: NeoFont.labelSmall, colorScheme: colorScheme)
                    Text("LABEL LARGE").font(NeoFont.labelLarge)
                    Text("LABEL MEDIUM").font(NeoFont.labelMedium)
                    Text("LABEL SMALL").font(NeoFont.labelSmall)
                }

                Divider()

                Group {
                    Text("NUMERIC")
                        .neoLabel(font: NeoFont.labelSmall, colorScheme: colorScheme)
                    Text("12345").font(NeoFont.numeric)
                    Text("67890").font(NeoFont.numericSmall)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .foregroundStyle(NeoColors.text(for: colorScheme))
        }
        .background(NeoColors.background(for: colorScheme))
    }
}
