//
//  GymsView.swift
//  GYMRar
//
//  Created by Alejandro Gonzalez on 10/11/25.
//

import SwiftUI
import SwiftData

struct GymsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var ctx
    @Query(sort: \Gym.name) private var gyms: [Gym]
    @State private var newGymName = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Add gym section
                    NeoSection("Add Gym", color: NeoColors.accent) {
                        HStack(spacing: 12) {
                            NeoTextField("Gym name", text: $newGymName)
                            NeoButton("Add", icon: "plus", size: .small, color: NeoColors.accent) {
                                guard !newGymName.isEmpty else { return }
                                ctx.insert(Gym(name: newGymName, defaultUnit: .kg))
                                try? ctx.save()
                                newGymName = ""
                            }
                        }
                        .padding(16)
                    }

                    // Gym list
                    if gyms.isEmpty {
                        NeoCard(color: NeoColors.surface(for: colorScheme)) {
                            VStack(spacing: 12) {
                                Image(systemName: "building.2")
                                    .font(.system(size: 40))
                                    .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.4))
                                Text("No gyms added yet")
                                    .font(NeoFont.bodyMedium)
                                    .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        }
                    } else {
                        VStack(spacing: 8) {
                            ForEach(gyms) { gym in
                                NavigationLink(destination: GymDetailView(gym: gym)) {
                                    NeoCard(color: NeoColors.surface(for: colorScheme)) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(gym.name)
                                                    .font(NeoFont.headlineMedium)
                                                if let note = gym.locationNote, !note.isEmpty {
                                                    Text(note)
                                                        .font(NeoFont.bodySmall)
                                                        .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.6))
                                                }
                                            }
                                            Spacer()
                                            Text(gym.defaultUnit.symbol)
                                                .font(NeoFont.labelLarge)
                                                .foregroundStyle(NeoColors.accent)
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.4))
                                        }
                                        .foregroundStyle(NeoColors.text(for: colorScheme))
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }
            .neoBackground()
            .navigationTitle("Gyms")
        }
    }
}

// MARK: - Gym Detail View

private struct GymDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var ctx
    @Bindable var gym: Gym
    @Query(sort: \Calibration.alias) private var allCalibrations: [Calibration]
    @State private var showAddCal = false

    private var gymCalibrations: [Calibration] {
        allCalibrations.filter { $0.gym?.id == gym.id }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Basics section
                NeoSection("Basics", color: NeoColors.accent) {
                    VStack(spacing: 16) {
                        NeoTextField("Name", text: $gym.name)

                        NeoSegmentedPicker("Default Unit", selection: $gym.defaultUnit) {
                            ForEach(WeightUnit.allCases) { u in
                                Text(u.symbol).tag(u)
                            }
                        }

                        NeoTextField("Location note", text: Binding($gym.locationNote, replacingNilWith: ""))
                    }
                    .padding(16)
                }

                // Calibrations section
                NeoSection("Calibrations", color: NeoColors.secondary) {
                    VStack(spacing: 0) {
                        if gymCalibrations.isEmpty {
                            Text("No calibrations added")
                                .font(NeoFont.bodyMedium)
                                .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .padding(16)
                        } else {
                            ForEach(gymCalibrations) { cal in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(cal.alias)
                                            .font(NeoFont.headlineMedium)
                                        Spacer()
                                        Button {
                                            ctx.delete(cal)
                                            try? ctx.save()
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundStyle(NeoColors.danger)
                                        }
                                    }
                                    Text(cal.baseExerciseName)
                                        .font(NeoFont.bodyMedium)
                                        .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.7))
                                    HStack {
                                        Text("real = \(cal.a, specifier: "%.2f") × marked + \(cal.b, specifier: "%.1f")")
                                            .font(NeoFont.labelSmall)
                                        Spacer()
                                        Text(cal.machineUnit.symbol)
                                            .font(NeoFont.labelMedium)
                                            .foregroundStyle(NeoColors.info)
                                    }
                                }
                                .padding(12)
                                .foregroundStyle(NeoColors.text(for: colorScheme))

                                if cal.id != gymCalibrations.last?.id {
                                    NeoSectionDivider()
                                }
                            }
                        }

                        NeoSectionDivider()

                        Button {
                            showAddCal = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Calibration")
                            }
                            .font(NeoFont.bodyLarge)
                            .foregroundStyle(NeoColors.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                        }
                    }
                }
            }
            .padding()
        }
        .neoBackground()
        .navigationTitle(gym.name)
        .sheet(isPresented: $showAddCal) {
            CalibrationEditorView(gym: gym)
        }
    }
}

// MARK: - Calibration Editor View

struct CalibrationEditorView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    let gym: Gym
    @State private var baseExerciseName = ""
    @State private var alias = ""
    @State private var a: Double = 1.0
    @State private var b: Double = 0.0
    @State private var machineUnit: WeightUnit = .kg

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    NeoSection("Machine Info", color: NeoColors.secondary) {
                        VStack(spacing: 16) {
                            NeoTextField("Base Exercise", text: $baseExerciseName)
                            NeoTextField("Alias (machine label)", text: $alias)
                        }
                        .padding(16)
                    }

                    NeoSection("Calibration Formula", color: NeoColors.info) {
                        VStack(spacing: 16) {
                            Text("real = a × marked + b")
                                .font(NeoFont.headlineMedium)
                                .foregroundStyle(NeoColors.text(for: colorScheme))
                                .frame(maxWidth: .infinity)

                            NeoDecimalStepper("a (multiplier)", value: $a, in: 0.1...2.0, step: 0.05, format: "%.2f")
                            NeoDecimalStepper("b (offset)", value: $b, in: -50...100, step: 2.5, format: "%.1f")

                            NeoSegmentedPicker("Machine Unit", selection: $machineUnit) {
                                ForEach(WeightUnit.allCases) { u in
                                    Text(u.symbol).tag(u)
                                }
                            }
                        }
                        .padding(16)
                    }
                }
                .padding()
            }
            .neoBackground()
            .navigationTitle("New Calibration")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let cal = Calibration(
                            gym: gym,
                            baseExerciseName: baseExerciseName,
                            alias: alias,
                            a: a,
                            b: b,
                            machineUnit: machineUnit
                        )
                        ctx.insert(cal)
                        try? ctx.save()
                        dismiss()
                    }
                    .disabled(baseExerciseName.isEmpty || alias.isEmpty)
                }
            }
        }
    }
}

// MARK: - Helper for optional TextField binding

extension Binding where Value == String {
    init(_ source: Binding<String?>, replacingNilWith defaultValue: String) {
        self.init(
            get: { source.wrappedValue ?? defaultValue },
            set: { source.wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }
}

#Preview("Gyms - Light") {
    GymsView()
        .modelContainer(for: [Gym.self, Calibration.self])
        .preferredColorScheme(.light)
}

#Preview("Gyms - Dark") {
    GymsView()
        .modelContainer(for: [Gym.self, Calibration.self])
        .preferredColorScheme(.dark)
}
