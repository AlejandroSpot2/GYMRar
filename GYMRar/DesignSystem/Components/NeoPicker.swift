//
//  NeoPicker.swift
//  GYMRar
//
//  Neobrutalism styled picker component
//

import SwiftUI

struct NeoPicker<SelectionValue: Hashable, Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String?
    @Binding var selection: SelectionValue
    @ViewBuilder let content: () -> Content

    init(
        _ title: String? = nil,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self._selection = selection
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title {
                Text(title.uppercased())
                    .font(NeoFont.labelMedium)
                    .foregroundStyle(NeoColors.text(for: colorScheme))
            }

            Picker(title ?? "", selection: $selection) {
                content()
            }
            .pickerStyle(.menu)
            .font(NeoFont.bodyLarge)
            .foregroundStyle(NeoColors.text(for: colorScheme))
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(NeoColors.surface(for: colorScheme))
            .overlay(
                Rectangle()
                    .stroke(NeoColors.border(for: colorScheme), lineWidth: 2)
            )
        }
    }
}

// MARK: - Segmented Picker Variant

struct NeoSegmentedPicker<SelectionValue: Hashable, Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String?
    @Binding var selection: SelectionValue
    @ViewBuilder let content: () -> Content

    init(
        _ title: String? = nil,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self._selection = selection
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title {
                Text(title.uppercased())
                    .font(NeoFont.labelMedium)
                    .foregroundStyle(NeoColors.text(for: colorScheme))
            }

            Picker(title ?? "", selection: $selection) {
                content()
            }
            .pickerStyle(.segmented)
            .padding(4)
            .background(NeoColors.surface(for: colorScheme))
            .overlay(
                Rectangle()
                    .stroke(NeoColors.border(for: colorScheme), lineWidth: 2)
            )
        }
    }
}

// MARK: - Preview

#Preview("Neo Picker - Light") {
    NeoPickerPreview()
        .preferredColorScheme(.light)
}

#Preview("Neo Picker - Dark") {
    NeoPickerPreview()
        .preferredColorScheme(.dark)
}

private struct NeoPickerPreview: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedOption = "Option 1"
    @State private var selectedUnit = "kg"

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("PICKERS")
                    .font(NeoFont.headlineLarge)
                    .foregroundStyle(NeoColors.text(for: colorScheme))

                VStack(alignment: .leading, spacing: 8) {
                    Text("MENU PICKER")
                        .font(NeoFont.labelMedium)
                        .foregroundStyle(NeoColors.text(for: colorScheme))

                    NeoPicker("Routine", selection: $selectedOption) {
                        Text("Option 1").tag("Option 1")
                        Text("Option 2").tag("Option 2")
                        Text("Option 3").tag("Option 3")
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("SEGMENTED PICKER")
                        .font(NeoFont.labelMedium)
                        .foregroundStyle(NeoColors.text(for: colorScheme))

                    NeoSegmentedPicker("Weight Unit", selection: $selectedUnit) {
                        Text("kg").tag("kg")
                        Text("lb").tag("lb")
                    }
                }
            }
            .padding()
        }
        .neoBackground()
    }
}
