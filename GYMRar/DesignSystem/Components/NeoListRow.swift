//
//  NeoListRow.swift
//  GYMRar
//
//  Neobrutalism styled list row component
//

import SwiftUI

struct NeoListRow<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let color: Color?
    let showChevron: Bool
    let content: () -> Content

    init(
        color: Color? = nil,
        showChevron: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.color = color
        self.showChevron = showChevron
        self.content = content
    }

    var body: some View {
        HStack {
            content()

            if showChevron {
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.5))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color ?? NeoColors.surface(for: colorScheme))
        .overlay(
            Rectangle()
                .stroke(NeoColors.border(for: colorScheme), lineWidth: 2)
        )
    }
}

// MARK: - Tappable List Row

struct NeoTappableRow<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    let color: Color?
    let showChevron: Bool
    let action: () -> Void
    let content: () -> Content

    init(
        color: Color? = nil,
        showChevron: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.color = color
        self.showChevron = showChevron
        self.action = action
        self.content = content
    }

    var body: some View {
        Button(action: action) {
            HStack {
                content()

                if showChevron {
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.5))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color ?? NeoColors.surface(for: colorScheme))
            .overlay(
                Rectangle()
                    .stroke(NeoColors.border(for: colorScheme), lineWidth: 2)
            )
            .offset(x: isPressed ? 2 : 0, y: isPressed ? 2 : 0)
            .background(
                NeoColors.border(for: colorScheme)
                    .offset(x: isPressed ? 2 : 4, y: isPressed ? 2 : 4)
            )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .sensoryFeedback(.impact(weight: .light), trigger: isPressed)
    }
}

// MARK: - Swipeable List Row

struct NeoSwipeableRow<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var offset: CGFloat = 0
    @State private var isShowingDelete = false

    let onDelete: () -> Void
    let content: () -> Content

    init(
        onDelete: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.onDelete = onDelete
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete background
            HStack {
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 80, height: .infinity)
                }
                .background(NeoColors.danger)
            }

            // Main content
            NeoListRow {
                content()
            }
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = max(value.translation.width, -80)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3)) {
                            if value.translation.width < -40 {
                                offset = -80
                                isShowingDelete = true
                            } else {
                                offset = 0
                                isShowingDelete = false
                            }
                        }
                    }
            )
        }
        .frame(height: 56)
        .clipped()
    }
}

// MARK: - Preview

#Preview("Neo List Row - Light") {
    NeoListRowPreview()
        .preferredColorScheme(.light)
}

#Preview("Neo List Row - Dark") {
    NeoListRowPreview()
        .preferredColorScheme(.dark)
}

private struct NeoListRowPreview: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("LIST ROWS")
                    .font(NeoFont.headlineLarge)
                    .foregroundStyle(NeoColors.text(for: colorScheme))

                VStack(alignment: .leading, spacing: 8) {
                    Text("BASIC")
                        .font(NeoFont.labelMedium)
                        .foregroundStyle(NeoColors.text(for: colorScheme))

                    NeoListRow {
                        Text("Simple list row")
                            .font(NeoFont.bodyLarge)
                            .foregroundStyle(NeoColors.text(for: colorScheme))
                    }

                    NeoListRow(showChevron: true) {
                        Text("With chevron")
                            .font(NeoFont.bodyLarge)
                            .foregroundStyle(NeoColors.text(for: colorScheme))
                    }

                    NeoListRow(color: NeoColors.primary) {
                        Text("Colored background")
                            .font(NeoFont.bodyLarge)
                            .foregroundStyle(NeoColors.text(for: .light))
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("TAPPABLE")
                        .font(NeoFont.labelMedium)
                        .foregroundStyle(NeoColors.text(for: colorScheme))

                    NeoTappableRow(action: {}) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Push Day")
                                .font(NeoFont.headlineMedium)
                            Text("5 exercises")
                                .font(NeoFont.bodySmall)
                                .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.6))
                        }
                        .foregroundStyle(NeoColors.text(for: colorScheme))
                    }

                    NeoTappableRow(color: NeoColors.accent, action: {}) {
                        HStack(spacing: 12) {
                            Image(systemName: "dumbbell.fill")
                                .font(.title2)
                            Text("Gym A")
                                .font(NeoFont.headlineMedium)
                        }
                        .foregroundStyle(NeoColors.text(for: .light))
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("COMPLEX CONTENT")
                        .font(NeoFont.labelMedium)
                        .foregroundStyle(NeoColors.text(for: colorScheme))

                    NeoListRow {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Bench Press")
                                    .font(NeoFont.headlineMedium)
                                Text("Chest")
                                    .font(NeoFont.bodySmall)
                                    .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.6))
                            }
                            Spacer()
                            Text("3x10")
                                .font(NeoFont.numeric)
                        }
                        .foregroundStyle(NeoColors.text(for: colorScheme))
                    }
                }
            }
            .padding()
        }
        .neoBackground()
    }
}
