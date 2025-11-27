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
    @State private var draft: WorkoutDraft
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var isSaved = false
    @State private var showSavedBanner = false
    @State private var saveSuccessPulse = false
    private let routine: Routine?
    @Environment(\.dismiss) private var dismiss

    init(routine: Routine?) {
        self.routine = routine
        _draft = State(initialValue: WorkoutDraft(date: .now, gym: routine?.gym))
    }

    var body: some View {
        Form {
            Section("Gym") { Text(draft.gym?.name ?? "No gym") }
            Section("Entries") {
                ForEach($draft.entries) { $set in
                    WorkoutSetRow(set: $set, gym: draft.gym, calibrations: calibrations)
                }
                .onDelete { idx in draft.entries.remove(atOffsets: idx) }

                Button { addNextFromRoutine() } label: {
                    Label("Add next exercise", systemImage: "plus")
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
        .onAppear { if draft.entries.isEmpty { seedFirstTwo() } }
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
    }

    private func seedFirstTwo() {
        guard let first = routine?.days.first?.items.prefix(2) else { return }
        var order = 1
        for it in first {
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

    private func addNextFromRoutine() {
        guard let plan = routine?.days.first?.items else { return }
        let used = Set(draft.entries.map { $0.exerciseName })
        if let next = plan.first(where: { !used.contains($0.exerciseName) }) {
            let unit = next.unitOverride ?? (draft.gym?.defaultUnit ?? .kg)
            let order = (draft.entries.map { $0.order }.max() ?? 0) + 1
            draft.entries.append(.init(
                exerciseName: next.exerciseName,
                order: order, reps: next.setScheme.repMin,
                weightValue: 20, weightUnit: unit, rpe: 7.5, note: nil, calibrationAlias: nil
            ))
        }
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
