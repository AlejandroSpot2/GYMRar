//
//  NeoModifiers.swift
//  GYMRar
//
//  Neobrutalism view modifiers for consistent styling
//

import SwiftUI

// MARK: - Neo Border Modifier

struct NeoBorderModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let width: CGFloat
    let color: Color?

    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .stroke(color ?? NeoColors.border(for: colorScheme), lineWidth: width)
            )
    }
}

extension View {
    /// Adds a bold neobrutalism border
    func neoBorder(width: CGFloat = 3, color: Color? = nil) -> some View {
        modifier(NeoBorderModifier(width: width, color: color))
    }
}

// MARK: - Neo Shadow Modifier

struct NeoShadowModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let offset: CGFloat
    let color: Color?

    func body(content: Content) -> some View {
        content
            .background(
                (color ?? NeoColors.border(for: colorScheme))
                    .offset(x: offset, y: offset)
            )
    }
}

extension View {
    /// Adds a hard offset shadow (neobrutalism style)
    func neoShadow(offset: CGFloat = 4, color: Color? = nil) -> some View {
        modifier(NeoShadowModifier(offset: offset, color: color))
    }
}

// MARK: - Neo Card Modifier (Combined)

struct NeoCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let backgroundColor: Color?
    let borderWidth: CGFloat
    let shadowOffset: CGFloat
    let padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(backgroundColor ?? NeoColors.surface(for: colorScheme))
            .neoBorder(width: borderWidth)
            .neoShadow(offset: shadowOffset)
    }
}

extension View {
    /// Combines background, border, and shadow for card styling
    func neoCard(
        background: Color? = nil,
        borderWidth: CGFloat = 3,
        shadowOffset: CGFloat = 4,
        padding: CGFloat = 16
    ) -> some View {
        modifier(NeoCardModifier(
            backgroundColor: background,
            borderWidth: borderWidth,
            shadowOffset: shadowOffset,
            padding: padding
        ))
    }
}

// MARK: - Neo Background Modifier

struct NeoBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(NeoColors.background(for: colorScheme))
    }
}

extension View {
    /// Applies the neobrutalism background color
    func neoBackground() -> some View {
        modifier(NeoBackgroundModifier())
    }
}

// MARK: - Preview

#Preview("Neo Modifiers - Light") {
    NeoModifiersPreview()
        .preferredColorScheme(.light)
}

#Preview("Neo Modifiers - Dark") {
    NeoModifiersPreview()
        .preferredColorScheme(.dark)
}

private struct NeoModifiersPreview: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("MODIFIERS")
                    .font(NeoFont.headlineLarge)
                    .foregroundStyle(NeoColors.text(for: colorScheme))

                // Border only
                Text("neoBorder()")
                    .font(NeoFont.bodyLarge)
                    .padding()
                    .background(NeoColors.surface(for: colorScheme))
                    .neoBorder()

                // Shadow only
                Text("neoShadow()")
                    .font(NeoFont.bodyLarge)
                    .padding()
                    .background(NeoColors.surface(for: colorScheme))
                    .neoShadow()

                // Combined card
                VStack(alignment: .leading, spacing: 8) {
                    Text("neoCard()")
                        .font(NeoFont.headlineMedium)
                    Text("Combines background, border, and shadow")
                        .font(NeoFont.bodySmall)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .neoCard()

                // Card with custom color
                VStack(alignment: .leading, spacing: 8) {
                    Text("neoCard(background:)")
                        .font(NeoFont.headlineMedium)
                    Text("With custom background color")
                        .font(NeoFont.bodySmall)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .neoCard(background: NeoColors.primary)

                // Different shadow sizes
                HStack(spacing: 16) {
                    Text("2px")
                        .padding(8)
                        .background(NeoColors.secondary)
                        .neoBorder(width: 2)
                        .neoShadow(offset: 2)

                    Text("4px")
                        .padding(8)
                        .background(NeoColors.accent)
                        .neoBorder(width: 2)
                        .neoShadow(offset: 4)

                    Text("6px")
                        .padding(8)
                        .background(NeoColors.warning)
                        .neoBorder(width: 2)
                        .neoShadow(offset: 6)
                }
                .font(NeoFont.bodyLarge)
            }
            .padding()
            .foregroundStyle(NeoColors.text(for: colorScheme))
        }
        .neoBackground()
    }
}
