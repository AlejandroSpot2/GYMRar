//
//  NeoColors.swift
//  GYMRar
//
//  Neobrutalism color palette with light/dark mode support
//

import SwiftUI

enum NeoColors {
    // MARK: - Primary Palette

    /// Yellow - Main actions, Today tab
    static let primary = Color(hex: "FFD93D")

    /// Pink - Routines tab
    static let secondary = Color(hex: "FF6B9D")

    /// Teal - Success states, Gyms tab
    static let accent = Color(hex: "4ECDC4")

    // MARK: - Semantic Colors

    /// Teal - Success states
    static let success = Color(hex: "4ECDC4")

    /// Coral red - Destructive actions
    static let danger = Color(hex: "FF6B6B")

    /// Orange - Warnings, Settings tab
    static let warning = Color(hex: "FFA94D")

    /// Light blue - Info, History tab
    static let info = Color(hex: "74B9FF")

    // MARK: - Adaptive Colors (Light/Dark Mode)

    /// Near black for light mode text
    private static let darkColor = Color(hex: "1A1A2E")

    /// Cream for light mode backgrounds
    private static let lightColor = Color(hex: "FFFEF0")

    /// Elevated dark for dark mode cards
    private static let surfaceDark = Color(hex: "2A2A3E")

    /// Text color - Dark in light mode, cream in dark mode
    static func text(for colorScheme: ColorScheme) -> Color {
        colorScheme == .light ? darkColor : lightColor
    }

    /// Background color - Cream in light mode, dark in dark mode
    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .light ? lightColor : darkColor
    }

    /// Surface color for cards - White in light mode, elevated dark in dark mode
    static func surface(for colorScheme: ColorScheme) -> Color {
        colorScheme == .light ? .white : surfaceDark
    }

    /// Border color - Black in light mode, white in dark mode
    static func border(for colorScheme: ColorScheme) -> Color {
        colorScheme == .light ? .black : .white
    }

    // MARK: - Tab Colors

    static let tabToday = primary
    static let tabRoutines = secondary
    static let tabGyms = accent
    static let tabHistory = info
    static let tabSettings = warning
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}

// MARK: - Preview

#Preview("Neo Colors - Light") {
    NeoColorPreview()
        .preferredColorScheme(.light)
}

#Preview("Neo Colors - Dark") {
    NeoColorPreview()
        .preferredColorScheme(.dark)
}

private struct NeoColorPreview: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("COLOR PALETTE")
                    .font(.headline.bold())

                Group {
                    ColorSwatch(name: "Primary", color: NeoColors.primary)
                    ColorSwatch(name: "Secondary", color: NeoColors.secondary)
                    ColorSwatch(name: "Accent", color: NeoColors.accent)
                    ColorSwatch(name: "Danger", color: NeoColors.danger)
                    ColorSwatch(name: "Warning", color: NeoColors.warning)
                    ColorSwatch(name: "Info", color: NeoColors.info)
                }

                Divider()

                Text("ADAPTIVE COLORS")
                    .font(.headline.bold())

                Group {
                    ColorSwatch(name: "Text", color: NeoColors.text(for: colorScheme))
                    ColorSwatch(name: "Background", color: NeoColors.background(for: colorScheme))
                    ColorSwatch(name: "Surface", color: NeoColors.surface(for: colorScheme))
                    ColorSwatch(name: "Border", color: NeoColors.border(for: colorScheme))
                }
            }
            .padding()
        }
        .background(NeoColors.background(for: colorScheme))
    }
}

private struct ColorSwatch: View {
    @Environment(\.colorScheme) private var colorScheme
    let name: String
    let color: Color

    var body: some View {
        HStack {
            Rectangle()
                .fill(color)
                .frame(width: 60, height: 40)
                .overlay(Rectangle().stroke(NeoColors.border(for: colorScheme), lineWidth: 2))
            Text(name)
                .font(.headline)
                .foregroundStyle(NeoColors.text(for: colorScheme))
            Spacer()
        }
    }
}
