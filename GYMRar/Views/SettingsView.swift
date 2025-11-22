//
//  SettingsView.swift
//  GYMRar
//
//  Created by Alejandro Gonzalez on 10/11/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("preferredUnit") private var preferredUnitRaw: String = WeightUnit.kg.rawValue
    var preferredUnit: WeightUnit {
        get { WeightUnit(rawValue: preferredUnitRaw) ?? .kg }
        set { preferredUnitRaw = newValue.rawValue }
    }

    var body: some View {
        Form {
            Section("Units") {
                Picker("Default unit", selection: Binding(get: { preferredUnit }, set: { preferredUnitRaw = $0.rawValue })) {
                    ForEach(WeightUnit.allCases, id: \.self) { u in Text(u.symbol).tag(u) }
                }.pickerStyle(.segmented)
                Text("Puedes cambiar la unidad por ejercicio en el log o en el builder.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }.navigationTitle("Settings")
    }
}

