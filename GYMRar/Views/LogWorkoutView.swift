//
//  LogWorkoutView.swift
//  GYMRar
//
//  Created by Alejandro Gonzalez on 10/11/25.
//


import SwiftUI
import SwiftData

struct LogWorkoutView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \Calibration.alias) private var calibrations: [Calibration]
    @State private var workout: Workout
    private let routine: Routine?

    init(routine: Routine?) {
        self.routine = routine
        _workout = State(initialValue: Workout(date: .now, gym: routine?.gym))
    }

    var body: some View {
        Form {
            Section("Gym") { Text(workout.gym?.name ?? "No gym") }
            Section("Entries") {
                ForEach($workout.entries) { $set in
                    WorkoutSetRow(set: $set, gym: workout.gym, calibrations: calibrations)
                }
                .onDelete { idx in workout.entries.remove(atOffsets: idx) }

                Button { addNextFromRoutine() } label: {
                    Label("Add next exercise", systemImage: "plus")
                }
            }
            Section {
                Button {
                    ctx.insert(workout); try? ctx.save()
                } label: { Label("Save Workout", systemImage: "tray.and.arrow.down") }
                .disabled(workout.entries.isEmpty)
            }
        }
        .navigationTitle("Log Workout")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively) // mitiga warnings de teclado
        .onAppear { if workout.entries.isEmpty { seedFirstTwo() } }
    }

    private func seedFirstTwo() {
        guard let first = routine?.days.first?.items.prefix(2) else { return }
        var order = 1
        for it in first {
            workout.entries.append(WorkoutSet(
                exerciseName: it.exerciseName,
                order: order, reps: it.setScheme.repMin, weightValue: 20,
                weightUnit: it.unitOverride ?? (workout.gym?.defaultUnit ?? .kg),
                rpe: 7.5, note: nil, calibrationAlias: nil
            ))
            order += 1
        }
    }

    private func addNextFromRoutine() {
        guard let plan = routine?.days.first?.items else { return }
        let used = Set(workout.entries.map { $0.exerciseName })
        if let next = plan.first(where: { !used.contains($0.exerciseName) }) {
            let unit = next.unitOverride ?? (workout.gym?.defaultUnit ?? .kg)
            let order = (workout.entries.map { $0.order }.max() ?? 0) + 1
            workout.entries.append(WorkoutSet(
                exerciseName: next.exerciseName,
                order: order, reps: next.setScheme.repMin,
                weightValue: 20, weightUnit: unit, rpe: 7.5, note: nil, calibrationAlias: nil
            ))
        }
    }
}

private struct WorkoutSetRow: View {
    @Binding var set: WorkoutSet
    var gym: Gym?
    var calibrations: [Calibration]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(set.exerciseName).font(.headline)

            Stepper("Reps: \(set.reps)", value: $set.reps, in: 1...50)

            HStack {
                TextField("Weight", value: $set.weightValue, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                Picker("", selection: Binding(get: { set.weightUnit }, set: { set.weightUnit = $0 })) {
                    ForEach(WeightUnit.allCases) { u in Text(u.symbol).tag(u) }
                }.pickerStyle(.segmented)
            }

            let gymCal = calibrations.filter {
                $0.gym?.id == gym?.id && $0.baseExerciseName == set.exerciseName
            }

            if !gymCal.isEmpty {
                Picker("Machine", selection: Binding<String?>(
                    get: { set.calibrationAlias },
                    set: { set.calibrationAlias = $0 }
                )) {
                    Text("None").tag(String?.none)
                    ForEach(gymCal, id: \.id) { c in
                        Text(c.alias).tag(String?.some(c.alias))
                    }
                }.pickerStyle(.menu)

                if let alias = set.calibrationAlias,
                   let cal = gymCal.first(where: { $0.alias == alias }) {
                    let realKg = CalibrationMath.realWeight(
                        marked: set.weightValue,
                        machineUnit: cal.machineUnit,
                        a: cal.a, b: cal.b,
                        outputUnit: .kg
                    )
                    let display = set.weightUnit == .kg ? realKg : UnitConv.convert(realKg, from: .kg, to: .lb)
                    Text("Real ≈ \(display, specifier: "%.1f") \(set.weightUnit.symbol)")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}
