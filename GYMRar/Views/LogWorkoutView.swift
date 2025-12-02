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
    @Query private var gyms: [Gym]
    @State private var draft: WorkoutDraft
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var isSaved = false
    @State private var showSavedBanner = false
    @State private var saveSuccessPulse = false
    @State private var showExercisePicker = false
    private let routine: Routine?
    @Environment(\.dismiss) private var dismiss

    init(routine: Routine?) {
        self.routine = routine
        _draft = State(initialValue: WorkoutDraft(date: .now, gym: routine?.gym))
    }

    var body: some View {
        Form {
            Section("Gym") {
                Picker("Gym", selection: $draft.gym) {
                    Text("None").tag(Gym?.none)
                    ForEach(gyms) { gym in
                        Text(gym.name).tag(Gym?.some(gym))
                    }
                }
            }
            ForEach(groupedExercises, id: \.name) { group in
                Section(group.name) {
                    ForEach(group.indices, id: \.self) { idx in
                        WorkoutSetRow(
                            set: $draft.entries[idx],
                            setNumber: group.indices.firstIndex(of: idx)! + 1,
                            gym: draft.gym,
                            calibrations: calibrations
                        )
                    }
                    .onDelete { offsets in
                        let indicesToRemove = offsets.map { group.indices[$0] }
                        draft.entries.remove(atOffsets: IndexSet(indicesToRemove))
                    }

                    Button {
                        addSetForExercise(group.name)
                    } label: {
                        Label("Add set", systemImage: "plus")
                    }
                }
            }

            Section {
                Button { showExercisePicker = true } label: {
                    Label("Add exercise", systemImage: "plus")
                }
            }
            Section {
                Button {
                    saveWorkout()
                } label: {
                    if isSaving {
                        Label("Saving…", systemImage: "hourglass")
                    } else {
                        Label("Save Workout", systemImage: "tray.and.arrow.down")
                    }
                }
                .disabled(draft.entries.isEmpty || isSaving || isSaved)
            }
        }
        .navigationTitle("Log Workout")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively) // mitiga warnings de teclado
        .onAppear { if draft.entries.isEmpty { seedAllExercises() } }
        .alert("No se pudo guardar", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveError ?? "")
        }
        .overlay(alignment: .top) {
            if showSavedBanner {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Workout guardado")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.thinMaterial, in: Capsule())
                .padding(.top, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .sensoryFeedback(.success, trigger: saveSuccessPulse)
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerView { exercise in
                addExercise(exercise)
            }
        }
    }

    private func seedAllExercises() {
        guard let items = routine?.days.first?.items else { return }
        var order = 1
        for it in items {
            draft.entries.append(.init(
                exerciseName: it.exerciseName,
                order: order,
                reps: it.setScheme.repMin,
                weightValue: 20,
                weightUnit: it.unitOverride ?? (draft.gym?.defaultUnit ?? .kg),
                rpe: 7.5,
                note: nil,
                calibrationAlias: nil
            ))
            order += 1
        }
    }

    private func addExercise(_ exercise: Exercise) {
        let unit = draft.gym?.defaultUnit ?? .kg
        let order = (draft.entries.map { $0.order }.max() ?? 0) + 1
        draft.entries.append(.init(
            exerciseName: exercise.name,
            order: order,
            reps: 10,
            weightValue: 20,
            weightUnit: unit,
            rpe: 7.5,
            note: nil,
            calibrationAlias: nil
        ))
    }

    private func addSetForExercise(_ exerciseName: String) {
        // Find an existing set for this exercise to copy defaults from
        let existing = draft.entries.first(where: { $0.exerciseName == exerciseName })
        let unit = existing?.weightUnit ?? draft.gym?.defaultUnit ?? .kg
        let weight = existing?.weightValue ?? 20
        let reps = existing?.reps ?? 10
        let order = (draft.entries.map { $0.order }.max() ?? 0) + 1

        draft.entries.append(.init(
            exerciseName: exerciseName,
            order: order,
            reps: reps,
            weightValue: weight,
            weightUnit: unit,
            rpe: existing?.rpe ?? 7.5,
            note: nil,
            calibrationAlias: existing?.calibrationAlias
        ))
    }

    private var groupedExercises: [(name: String, indices: [Int])] {
        var groups: [(name: String, indices: [Int])] = []
        var seen: [String: Int] = [:] // exerciseName -> index in groups

        for (index, entry) in draft.entries.enumerated() {
            if let groupIndex = seen[entry.exerciseName] {
                groups[groupIndex].indices.append(index)
            } else {
                seen[entry.exerciseName] = groups.count
                groups.append((name: entry.exerciseName, indices: [index]))
            }
        }
        return groups
    }
}

// MARK: - Drafts

private struct WorkoutDraft {
    var date: Date
    var gym: Gym?
    var entries: [WorkoutSetDraft] = []

    func toModel() -> Workout {
        let sets = entries.map { draft in
            WorkoutSet(
                exerciseName: draft.exerciseName,
                order: draft.order,
                reps: draft.reps,
                weightValue: draft.weightValue,
                weightUnit: draft.weightUnit,
                rpe: draft.rpe,
                note: draft.note,
                calibrationAlias: draft.calibrationAlias
            )
        }
        return Workout(date: date, gym: gym, entries: sets)
    }
}

private struct WorkoutSetDraft: Identifiable {
    var id = UUID()
    var exerciseName: String
    var order: Int
    var reps: Int
    var weightValue: Double
    var weightUnit: WeightUnit
    var rpe: Double?
    var note: String?
    var calibrationAlias: String?
}

// MARK: - Save helpers

private extension LogWorkoutView {
    func saveWorkout() {
        guard !isSaving else { return }
        guard !draft.entries.isEmpty else { return }
        isSaving = true

        let workout = draft.toModel()
        ctx.insert(workout)
        do {
            try ctx.save()
            saveSuccessPulse.toggle()
            withAnimation(.spring(duration: 0.35)) { showSavedBanner = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.3)) { showSavedBanner = false }
            }
            isSaved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                dismiss()
            }
        } catch {
            saveError = error.localizedDescription
            ctx.delete(workout)
            isSaved = false
        }

        isSaving = false
    }
}

private struct WorkoutSetRow: View {
    @Binding var set: WorkoutSetDraft
    var setNumber: Int
    var gym: Gym?
    var calibrations: [Calibration]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Set \(setNumber)").font(.subheadline).foregroundStyle(.secondary)

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
