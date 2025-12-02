//
//  NeoCard.swift
//  GYMRar
//
//  Neobrutalism card container component
//

import SwiftUI

struct NeoCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let color: Color?
    let borderWidth: CGFloat
    let shadowOffset: CGFloat
    let padding: CGFloat
    let content: () -> Content

    init(
        color: Color? = nil,
        borderWidth: CGFloat = 3,
        shadowOffset: CGFloat = 4,
        padding: CGFloat = 16,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.color = color
        self.borderWidth = borderWidth
        self.shadowOffset = shadowOffset
        self.padding = padding
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color ?? NeoColors.surface(for: colorScheme))
            .overlay(
                Rectangle()
                    .stroke(NeoColors.border(for: colorScheme), lineWidth: borderWidth)
            )
            .background(
                NeoColors.border(for: colorScheme)
                    .offset(x: shadowOffset, y: shadowOffset)
            )
    }
}

// MARK: - Preview

#Preview("Neo Card - Light") {
    NeoCardPreview()
        .preferredColorScheme(.light)
}

#Preview("Neo Card - Dark") {
    NeoCardPreview()
        .preferredColorScheme(.dark)
}

private struct NeoCardPreview: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("CARDS")
                    .font(NeoFont.headlineLarge)
                    .foregroundStyle(NeoColors.text(for: colorScheme))

                NeoCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Default Card")
                            .font(NeoFont.headlineMedium)
                        Text("This is a card with default surface background")
                            .font(NeoFont.bodyMedium)
                    }
                    .foregroundStyle(NeoColors.text(for: colorScheme))
                }

                NeoCard(color: NeoColors.primary) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Primary Card")
                            .font(NeoFont.headlineMedium)
                        Text("This is a card with primary color background")
                            .font(NeoFont.bodyMedium)
                    }
                    .foregroundStyle(NeoColors.text(for: .light))
                }

                NeoCard(color: NeoColors.secondary) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Secondary Card")
                            .font(NeoFont.headlineMedium)
                        Text("This is a card with secondary color background")
                            .font(NeoFont.bodyMedium)
                    }
                    .foregroundStyle(NeoColors.text(for: .light))
                }

                NeoCard(color: NeoColors.accent, shadowOffset: 6) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Larger Shadow")
                            .font(NeoFont.headlineMedium)
                        Text("This card has a 6px shadow offset")
                            .font(NeoFont.bodyMedium)
                    }
                    .foregroundStyle(NeoColors.text(for: .light))
                }
            }
            .padding()
        }
        .neoBackground()
    }
}
