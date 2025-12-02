//
//  SettingsView.swift
//  GYMRar
//
//  Created by Alejandro Gonzalez on 10/11/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("preferredUnit") private var preferredUnitRaw: String = WeightUnit.kg.rawValue

    private var preferredUnit: WeightUnit {
        get { WeightUnit(rawValue: preferredUnitRaw) ?? .kg }
        set { preferredUnitRaw = newValue.rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    NeoSection("Units", color: NeoColors.warning) {
                        VStack(alignment: .leading, spacing: 16) {
                            NeoSegmentedPicker(
                                "Default unit",
                                selection: Binding(
                                    get: { preferredUnit },
                                    set: { preferredUnitRaw = $0.rawValue }
                                )
                            ) {
                                ForEach(WeightUnit.allCases, id: \.self) { u in
                                    Text(u.symbol).tag(u)
                                }
                            }

                            Text("Puedes cambiar la unidad por ejercicio en el log o en el builder.")
                                .font(NeoFont.bodySmall)
                                .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.6))
                        }
                        .padding(16)
                    }

                    NeoSection("About", color: NeoColors.info) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Version")
                                    .font(NeoFont.bodyLarge)
                                Spacer()
                                Text("1.0.0")
                                    .font(NeoFont.bodyMedium)
                                    .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.6))
                            }
                        }
                        .padding(16)
                        .foregroundStyle(NeoColors.text(for: colorScheme))
                    }
                }
                .padding()
            }
            .neoBackground()
            .navigationTitle("Settings")
        }
    }
}

#Preview("Settings - Light") {
    SettingsView()
        .preferredColorScheme(.light)
}

#Preview("Settings - Dark") {
    SettingsView()
        .preferredColorScheme(.dark)
}
