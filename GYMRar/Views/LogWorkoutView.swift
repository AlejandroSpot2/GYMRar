//
//  LogWorkoutView.swift
//  GYMRar
//
//  Created by Alejandro Gonzalez on 10/11/25.
//

import SwiftUI
import SwiftData

struct LogWorkoutView: View {
    @Environment(\.colorScheme) private var colorScheme
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
        ScrollView {
            VStack(spacing: 16) {
                // Gym picker
                NeoSection("Gym", color: NeoColors.accent) {
                    NeoPicker(selection: $draft.gym) {
                        Text("None").tag(Gym?.none)
                        ForEach(gyms) { gym in
                            Text(gym.name).tag(Gym?.some(gym))
                        }
                    }
                    .padding(16)
                }

                // Exercise groups
                ForEach(groupedExercises, id: \.name) { group in
                    NeoSection(group.name, color: NeoColors.primary) {
                        VStack(spacing: 0) {
                            ForEach(group.indices, id: \.self) { idx in
                                WorkoutSetRow(
                                    set: $draft.entries[idx],
                                    setNumber: group.indices.firstIndex(of: idx)! + 1,
                                    gym: draft.gym,
                                    calibrations: calibrations,
                                    onDelete: {
                                        draft.entries.remove(at: idx)
                                    }
                                )

                                if idx != group.indices.last {
                                    NeoSectionDivider()
                                }
                            }

                            NeoSectionDivider()

                            Button {
                                addSetForExercise(group.name)
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add set")
                                }
                                .font(NeoFont.bodyLarge)
                                .foregroundStyle(NeoColors.primary)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                            }
                        }
                    }
                }

                // Add exercise button
                NeoButton("Add Exercise", icon: "plus", variant: .outline, fullWidth: true) {
                    showExercisePicker = true
                }

                // Save button
                NeoButton(
                    isSaving ? "Saving..." : "Save Workout",
                    icon: isSaving ? "hourglass" : "tray.and.arrow.down",
                    size: .large,
                    color: NeoColors.success,
                    fullWidth: true
                ) {
                    saveWorkout()
                }
                .disabled(draft.entries.isEmpty || isSaving || isSaved)
            }
            .padding()
        }
        .neoBackground()
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Log Workout")
        .navigationBarTitleDisplayMode(.inline)
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
                        .font(NeoFont.bodyLarge)
                }
                .foregroundStyle(NeoColors.text(for: .light))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(NeoColors.success)
                .neoBorder(width: 2)
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
        var seen: [String: Int] = [:]

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

// MARK: - Workout Set Row

private struct WorkoutSetRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var set: WorkoutSetDraft
    var setNumber: Int
    var gym: Gym?
    var calibrations: [Calibration]
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SET \(setNumber)")
                    .font(NeoFont.labelMedium)
                    .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.6))
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(NeoColors.danger)
                }
            }

            NeoStepper("Reps", value: $set.reps, in: 1...50)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WEIGHT")
                        .font(NeoFont.labelSmall)
                        .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.6))
                    TextField("Weight", value: $set.weightValue, format: .number.precision(.fractionLength(1)))
                        .font(NeoFont.numeric)
                        .keyboardType(.decimalPad)
                        .padding(10)
                        .background(NeoColors.surface(for: colorScheme))
                        .neoBorder(width: 2)
                        .foregroundStyle(NeoColors.text(for: colorScheme))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("UNIT")
                        .font(NeoFont.labelSmall)
                        .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.6))
                    NeoSegmentedPicker(selection: $set.weightUnit) {
                        ForEach(WeightUnit.allCases) { u in
                            Text(u.symbol).tag(u)
                        }
                    }
                }
            }

            let gymCal = calibrations.filter {
                $0.gym?.id == gym?.id && $0.baseExerciseName == set.exerciseName
            }

            if !gymCal.isEmpty {
                NeoPicker("Machine", selection: Binding<String?>(
                    get: { set.calibrationAlias },
                    set: { set.calibrationAlias = $0 }
                )) {
                    Text("None").tag(String?.none)
                    ForEach(gymCal, id: \.id) { c in
                        Text(c.alias).tag(String?.some(c.alias))
                    }
                }

                if let alias = set.calibrationAlias,
                   let cal = gymCal.first(where: { $0.alias == alias }) {
                    let realKg = CalibrationMath.realWeight(
                        marked: set.weightValue,
                        machineUnit: cal.machineUnit,
                        a: cal.a, b: cal.b,
                        outputUnit: .kg
                    )
                    let display = set.weightUnit == .kg ? realKg : UnitConv.convert(realKg, from: .kg, to: .lb)

                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Real ≈ \(display, specifier: "%.1f") \(set.weightUnit.symbol)")
                    }
                    .font(NeoFont.labelMedium)
                    .foregroundStyle(NeoColors.info)
                }
            }
        }
        .padding(12)
        .foregroundStyle(NeoColors.text(for: colorScheme))
    }
}

#Preview("Log Workout - Light") {
    NavigationStack {
        LogWorkoutView(routine: nil)
    }
    .modelContainer(for: [Workout.self, Gym.self, Calibration.self, Exercise.self])
    .preferredColorScheme(.light)
}

#Preview("Log Workout - Dark") {
    NavigationStack {
        LogWorkoutView(routine: nil)
    }
    .modelContainer(for: [Workout.self, Gym.self, Calibration.self, Exercise.self])
    .preferredColorScheme(.dark)
}
