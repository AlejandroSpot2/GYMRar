//
//  GymsView.swift
//  GYMRar
//
//  Created by Alejandro Gonzalez on 10/11/25.
//


import SwiftUI
import SwiftData

struct GymsView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \Gym.name) private var gyms: [Gym]
    @Query(sort: \Calibration.alias) private var allCalibrations: [Calibration]
    @State private var newGymName = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Add Gym") {
                    HStack {
                        TextField("Name", text: $newGymName)
                        Button("Add") {
                            guard !newGymName.isEmpty else { return }
                            ctx.insert(Gym(name: newGymName, defaultUnit: .kg))
                            try? ctx.save(); newGymName = ""
                        }
                    }
                }
                ForEach(gyms) { g in
                    NavigationLink(destination: GymDetailView(gym: g)) {
                        Text(g.name); Spacer()
                        Text(g.defaultUnit.symbol).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Gyms")
        }
    }
}

private struct GymDetailView: View {
    @Environment(\.modelContext) private var ctx
    @Bindable var gym: Gym
    @Query(sort: \Calibration.alias) private var allCalibrations: [Calibration]
    @State private var showAddCal = false

    var body: some View {
        Form {
            Section("Basics") {
                TextField("Name", text: $gym.name)
                Picker("Default Unit", selection: $gym.defaultUnit) {
                    ForEach(WeightUnit.allCases) { u in Text(u.symbol).tag(u) }
                }.pickerStyle(.segmented)
                TextField("Note", text: Binding($gym.locationNote, replacingNilWith: ""))
            }
            Section("Calibrations") {
                let cals = allCalibrations.filter { $0.gym?.id == gym.id }
                ForEach(cals) { c in
                    VStack(alignment: .leading) {
                        Text(c.alias).font(.headline)
                        Text("\(c.baseExerciseName) • real=\(c.a)·marked+\(c.b)")
                            .foregroundStyle(.secondary)
                        Text("Machine unit: \(c.machineUnit.symbol)").foregroundStyle(.secondary)
                    }
                }
                .onDelete { idx in
                    let cals = allCalibrations.filter { $0.gym?.id == gym.id }
                    idx.map { cals[$0] }.forEach { ctx.delete($0) }
                    try? ctx.save()
                }
                Button("Add Calibration") { showAddCal = true }
            }
        }
        .navigationTitle(gym.name)
        .sheet(isPresented: $showAddCal) { CalibrationEditorView(gym: gym) }
    }
}

struct CalibrationEditorView: View {
    @Environment(\.modelContext) private var ctx
    var gym: Gym
    @State private var baseExerciseName = ""
    @State private var alias = ""
    @State private var a: Double = 1.0
    @State private var b: Double = 0.0
    @State private var machineUnit: WeightUnit = .kg
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("Base Exercise", text: $baseExerciseName)
                TextField("Alias (machine label)", text: $alias)
                Stepper("a (multiplier): \(a, specifier: "%.2f")", value: $a, in: 0.1...2.0, step: 0.05)
                Stepper("b (offset): \(b, specifier: "%.1f")", value: $b, in: -50...100, step: 2.5)
                Picker("Machine Unit", selection: $machineUnit) {
                    ForEach(WeightUnit.allCases) { u in Text(u.symbol).tag(u) }
                }.pickerStyle(.segmented)
            }
            .navigationTitle("New Calibration")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let cal = Calibration(gym: gym, baseExerciseName: baseExerciseName,
                                              alias: alias, a: a, b: b, machineUnit: machineUnit)
                        ctx.insert(cal); try? ctx.save(); dismiss()
                    }.disabled(baseExerciseName.isEmpty || alias.isEmpty)
                }
            }
        }
    }
}

// Helper para optionals en TextField
extension Binding where Value == String {
    init(_ source: Binding<String?>, replacingNilWith defaultValue: String) {
        self.init(get: { source.wrappedValue ?? defaultValue },
                  set: { source.wrappedValue = $0.isEmpty ? nil : $0 })
    }
}
