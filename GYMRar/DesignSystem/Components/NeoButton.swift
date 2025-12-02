//
//  NeoButton.swift
//  GYMRar
//
//  Neobrutalism button component with filled/outline variants
//

import SwiftUI

// MARK: - Button Variant & Size

enum NeoButtonVariant {
    case filled
    case outline
}

enum NeoButtonSize {
    case small
    case medium
    case large

    var padding: EdgeInsets {
        switch self {
        case .small: EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        case .medium: EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        case .large: EdgeInsets(top: 16, leading: 28, bottom: 16, trailing: 28)
        }
    }

    var font: Font {
        switch self {
        case .small: NeoFont.labelSmall
        case .medium: NeoFont.labelMedium
        case .large: NeoFont.labelLarge
        }
    }

    var borderWidth: CGFloat {
        switch self {
        case .small: 2
        case .medium: 2.5
        case .large: 3
        }
    }

    var shadowOffset: CGFloat {
        switch self {
        case .small: 3
        case .medium: 4
        case .large: 5
        }
    }
}

// MARK: - Neo Button Style

struct NeoButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled

    let variant: NeoButtonVariant
    let size: NeoButtonSize
    let color: Color
    let fullWidth: Bool

    func makeBody(configuration: Configuration) -> some View {
        let pressOffset: CGFloat = configuration.isPressed ? size.shadowOffset / 2 : 0

        configuration.label
            .font(size.font)
            .textCase(.uppercase)
            .foregroundStyle(textColor)
            .padding(size.padding)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(backgroundColor)
            .overlay(
                Rectangle()
                    .stroke(NeoColors.border(for: colorScheme), lineWidth: size.borderWidth)
            )
            .offset(x: pressOffset, y: pressOffset)
            .background(
                NeoColors.border(for: colorScheme)
                    .offset(x: size.shadowOffset - pressOffset, y: size.shadowOffset - pressOffset)
            )
            .opacity(isEnabled ? 1.0 : 0.5)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .medium, intensity: 0.7), trigger: configuration.isPressed)
    }

    private var textColor: Color {
        switch variant {
        case .filled:
            return NeoColors.text(for: .light) // Always dark text on colored backgrounds
        case .outline:
            return NeoColors.text(for: colorScheme)
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .filled:
            return color
        case .outline:
            return NeoColors.surface(for: colorScheme)
        }
    }
}

// MARK: - Neo Button View

struct NeoButton: View {
    let title: String
    let icon: String?
    let variant: NeoButtonVariant
    let size: NeoButtonSize
    let color: Color
    let fullWidth: Bool
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        variant: NeoButtonVariant = .filled,
        size: NeoButtonSize = .medium,
        color: Color = NeoColors.primary,
        fullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.variant = variant
        self.size = size
        self.color = color
        self.fullWidth = fullWidth
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
        }
        .buttonStyle(NeoButtonStyle(
            variant: variant,
            size: size,
            color: color,
            fullWidth: fullWidth
        ))
    }
}

// MARK: - Preview

#Preview("Neo Buttons - Light") {
    NeoButtonPreview()
        .preferredColorScheme(.light)
}

#Preview("Neo Buttons - Dark") {
    NeoButtonPreview()
        .preferredColorScheme(.dark)
}

private struct NeoButtonPreview: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("BUTTONS")
                    .font(NeoFont.headlineLarge)
                    .foregroundStyle(NeoColors.text(for: colorScheme))

                // Filled variants
                VStack(alignment: .leading, spacing: 12) {
                    Text("FILLED")
                        .font(NeoFont.labelMedium)
                        .foregroundStyle(NeoColors.text(for: colorScheme))

                    HStack(spacing: 12) {
                        NeoButton("Primary", color: NeoColors.primary) {}
                        NeoButton("Secondary", color: NeoColors.secondary) {}
                    }

                    HStack(spacing: 12) {
                        NeoButton("Success", color: NeoColors.success) {}
                        NeoButton("Danger", color: NeoColors.danger) {}
                    }
                }

                Divider()

                // Outline variants
                VStack(alignment: .leading, spacing: 12) {
                    Text("OUTLINE")
                        .font(NeoFont.labelMedium)
                        .foregroundStyle(NeoColors.text(for: colorScheme))

                    HStack(spacing: 12) {
                        NeoButton("Outline", variant: .outline) {}
                        NeoButton("Delete", variant: .outline, color: NeoColors.danger) {}
                    }
                }

                Divider()

                // Sizes
                VStack(alignment: .leading, spacing: 12) {
                    Text("SIZES")
                        .font(NeoFont.labelMedium)
                        .foregroundStyle(NeoColors.text(for: colorScheme))

                    HStack(spacing: 12) {
                        NeoButton("Small", size: .small) {}
                        NeoButton("Medium", size: .medium) {}
                    }
                    NeoButton("Large", size: .large) {}
                }

                Divider()

                // With icons
                VStack(alignment: .leading, spacing: 12) {
                    Text("WITH ICONS")
                        .font(NeoFont.labelMedium)
                        .foregroundStyle(NeoColors.text(for: colorScheme))

                    HStack(spacing: 12) {
                        NeoButton("Start", icon: "play.fill", color: NeoColors.success) {}
                        NeoButton("Add", icon: "plus", color: NeoColors.info) {}
                    }
                }

                Divider()

                // Full width
                VStack(alignment: .leading, spacing: 12) {
                    Text("FULL WIDTH")
                        .font(NeoFont.labelMedium)
                        .foregroundStyle(NeoColors.text(for: colorScheme))

                    NeoButton("Start Workout", icon: "play.fill", size: .large, color: NeoColors.success, fullWidth: true) {}
                }

                Divider()

                // Disabled
                VStack(alignment: .leading, spacing: 12) {
                    Text("DISABLED")
                        .font(NeoFont.labelMedium)
                        .foregroundStyle(NeoColors.text(for: colorScheme))

                    NeoButton("Disabled", color: NeoColors.primary) {}
                        .disabled(true)
                }
            }
            .padding()
        }
        .neoBackground()
    }
}
