//
//  NeoSection.swift
//  GYMRar
//
//  Neobrutalism styled section component with colored header
//

import SwiftUI

struct NeoSection<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let color: Color
    let content: () -> Content

    init(
        _ title: String,
        color: Color = NeoColors.primary,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.color = color
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header bar
            Text(title.uppercased())
                .font(NeoFont.labelMedium)
                .foregroundStyle(NeoColors.text(for: .light))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(color)
                .overlay(
                    Rectangle()
                        .stroke(NeoColors.border(for: colorScheme), lineWidth: 2)
                )

            // Content area
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(NeoColors.surface(for: colorScheme))
            .overlay(
                Rectangle()
                    .stroke(NeoColors.border(for: colorScheme), lineWidth: 2)
                    .offset(y: -1)
            )
        }
        .background(
            NeoColors.border(for: colorScheme)
                .offset(x: 4, y: 4)
        )
    }
}

// MARK: - Section Row Helper

struct NeoSectionRow<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct NeoSectionDivider: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Rectangle()
            .fill(NeoColors.border(for: colorScheme))
            .frame(height: 1)
    }
}

// MARK: - Preview

#Preview("Neo Section - Light") {
    NeoSectionPreview()
        .preferredColorScheme(.light)
}

#Preview("Neo Section - Dark") {
    NeoSectionPreview()
        .preferredColorScheme(.dark)
}

private struct NeoSectionPreview: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("SECTIONS")
                    .font(NeoFont.headlineLarge)
                    .foregroundStyle(NeoColors.text(for: colorScheme))

                NeoSection("Basic Section") {
                    NeoSectionRow {
                        Text("This is a basic section with default primary color")
                            .font(NeoFont.bodyMedium)
                            .foregroundStyle(NeoColors.text(for: colorScheme))
                    }
                }

                NeoSection("Settings", color: NeoColors.warning) {
                    NeoSectionRow {
                        HStack {
                            Text("Notifications")
                                .font(NeoFont.bodyLarge)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundStyle(NeoColors.text(for: colorScheme))
                    }
                    NeoSectionDivider()
                    NeoSectionRow {
                        HStack {
                            Text("Privacy")
                                .font(NeoFont.bodyLarge)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundStyle(NeoColors.text(for: colorScheme))
                    }
                }

                NeoSection("Workout Summary", color: NeoColors.success) {
                    NeoSectionRow {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Bench Press")
                                    .font(NeoFont.headlineMedium)
                                Spacer()
                                Text("3x10")
                                    .font(NeoFont.numericSmall)
                            }
                            Text("60 kg")
                                .font(NeoFont.bodySmall)
                                .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.7))
                        }
                        .foregroundStyle(NeoColors.text(for: colorScheme))
                    }
                    NeoSectionDivider()
                    NeoSectionRow {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Squat")
                                    .font(NeoFont.headlineMedium)
                                Spacer()
                                Text("4x8")
                                    .font(NeoFont.numericSmall)
                            }
                            Text("80 kg")
                                .font(NeoFont.bodySmall)
                                .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.7))
                        }
                        .foregroundStyle(NeoColors.text(for: colorScheme))
                    }
                }

                NeoSection("Day 1: Push", color: NeoColors.secondary) {
                    NeoSectionRow {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Chest, Shoulders, Triceps")
                                .font(NeoFont.bodyMedium)
                                .foregroundStyle(NeoColors.text(for: colorScheme))
                            Text("5 exercises")
                                .font(NeoFont.bodySmall)
                                .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.6))
                        }
                    }
                }
            }
            .padding()
        }
        .neoBackground()
    }
}
