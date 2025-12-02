//
//  NeoTextField.swift
//  GYMRar
//
//  Neobrutalism styled text field component
//

import SwiftUI

struct NeoTextField: View {
    @Environment(\.colorScheme) private var colorScheme

    let placeholder: String
    @Binding var text: String
    let icon: String?

    init(_ placeholder: String, text: Binding<String>, icon: String? = nil) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.6))
            }

            TextField(placeholder, text: $text)
                .font(NeoFont.bodyLarge)
                .foregroundStyle(NeoColors.text(for: colorScheme))
        }
        .padding(12)
        .background(NeoColors.surface(for: colorScheme))
        .overlay(
            Rectangle()
                .stroke(NeoColors.border(for: colorScheme), lineWidth: 2)
        )
    }
}

// MARK: - Multiline Text Field

struct NeoTextEditor: View {
    @Environment(\.colorScheme) private var colorScheme

    let placeholder: String
    @Binding var text: String
    let minHeight: CGFloat

    init(_ placeholder: String, text: Binding<String>, minHeight: CGFloat = 100) {
        self.placeholder = placeholder
        self._text = text
        self.minHeight = minHeight
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(NeoFont.bodyLarge)
                    .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.4))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
            }

            TextEditor(text: $text)
                .font(NeoFont.bodyLarge)
                .foregroundStyle(NeoColors.text(for: colorScheme))
                .scrollContentBackground(.hidden)
                .frame(minHeight: minHeight)
        }
        .padding(12)
        .background(NeoColors.surface(for: colorScheme))
        .overlay(
            Rectangle()
                .stroke(NeoColors.border(for: colorScheme), lineWidth: 2)
        )
    }
}

// MARK: - Preview

#Preview("Neo TextField - Light") {
    NeoTextFieldPreview()
        .preferredColorScheme(.light)
}

#Preview("Neo TextField - Dark") {
    NeoTextFieldPreview()
        .preferredColorScheme(.dark)
}

private struct NeoTextFieldPreview: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var name = ""
    @State private var search = ""
    @State private var notes = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("TEXT FIELDS")
                    .font(NeoFont.headlineLarge)
                    .foregroundStyle(NeoColors.text(for: colorScheme))

                VStack(alignment: .leading, spacing: 8) {
                    Text("BASIC")
                        .font(NeoFont.labelMedium)
                        .foregroundStyle(NeoColors.text(for: colorScheme))
                    NeoTextField("Enter name", text: $name)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("WITH ICON")
                        .font(NeoFont.labelMedium)
                        .foregroundStyle(NeoColors.text(for: colorScheme))
                    NeoTextField("Search exercises", text: $search, icon: "magnifyingglass")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("MULTILINE")
                        .font(NeoFont.labelMedium)
                        .foregroundStyle(NeoColors.text(for: colorScheme))
                    NeoTextEditor("Add notes...", text: $notes)
                }
            }
            .padding()
        }
        .neoBackground()
    }
}
