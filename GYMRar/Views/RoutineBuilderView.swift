//
//  RoutineBuilderView.swift
//  GYMRar
//
//  Created by Alejandro Gonzalez on 10/11/25.
//

import SwiftUI
import SwiftData
import Combine
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Draft Models

struct RoutineDayDraft: Identifiable {
    let id = UUID()
    var label: String
    var items: [RoutineItemDraft]

    init(label: String, items: [RoutineItemDraft] = []) {
        self.label = label
        self.items = items
    }

    init(from day: RoutineDay) {
        self.label = day.label
        self.items = day.items.map { RoutineItemDraft(from: $0) }
    }

    func toRoutineDay() -> RoutineDay {
        RoutineDay(label: label, items: items.map { $0.toRoutineItem() })
    }
}

struct RoutineItemDraft: Identifiable {
    let id = UUID()
    var exerciseName: String
    var sets: Int
    var repMin: Int
    var repMax: Int
    var rpeNote: String?
    var progression: ProgressionRule
    var unitOverride: WeightUnit?

    init(exerciseName: String, sets: Int = 3, repMin: Int = 8, repMax: Int = 12,
         rpeNote: String? = nil, progression: ProgressionRule = .doubleProgression,
         unitOverride: WeightUnit? = nil) {
        self.exerciseName = exerciseName
        self.sets = sets
        self.repMin = repMin
        self.repMax = repMax
        self.rpeNote = rpeNote
        self.progression = progression
        self.unitOverride = unitOverride
    }

    init(from item: RoutineItem) {
        self.exerciseName = item.exerciseName
        self.sets = item.sets
        self.repMin = item.repMin
        self.repMax = item.repMax
        self.rpeNote = item.rpeNote
        self.progression = item.progression
        self.unitOverride = item.unitOverride
    }

    func toRoutineItem() -> RoutineItem {
        RoutineItem(
            exerciseName: exerciseName,
            setScheme: .init(sets: sets, repMin: repMin, repMax: repMax, rpeNote: rpeNote),
            progression: progression,
            unitOverride: unitOverride
        )
    }
}

// MARK: - Main View

struct RoutineBuilderView: View {
    @Environment(\.modelContext) private var ctx
    let container: ModelContainer
    @Query(sort: \Exercise.name) private var catalog: [Exercise]
    @Query private var gyms: [Gym]
    @Environment(\.dismiss) private var dismiss

    // Routine being edited (nil for new routine)
    var editingRoutine: Routine?

    @State private var name: String = ""
    @State private var selectedGym: Gym?
    @State private var days: [RoutineDayDraft] = []

    @State private var isSaving = false
    @State private var saveError: String?
    @State private var saveSuccessPulse = false

    // Exercise picker sheet state
    @State private var showExercisePicker = false
    @State private var editingDayIndex: Int?

    // Expanded exercise for inline editing
    @State private var expandedItemId: UUID?

    // AI
    @StateObject private var aiServiceHolder = AIHolder()
    @State private var showAIPromptSheet = false

    var body: some View {
        NavigationStack {
            Form {
                basicsSection
                daysSection
                addDaySection

                if #available(iOS 26, *) {
                    aiSection
                }

                saveSection
            }
            .navigationTitle(editingRoutine == nil ? "New Routine" : "Edit Routine")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                setupInitialState()
                if #available(iOS 26, *) {
                    if aiServiceHolder.service == nil {
                        aiServiceHolder.bootstrap(container: container)
                    }
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                if let dayIdx = editingDayIndex {
                    ExercisePickerView { exercise in
                        addExerciseToDay(exercise, dayIndex: dayIdx)
                    }
                }
            }
            .sheet(isPresented: $showAIPromptSheet) {
                if #available(iOS 26, *), let service = aiServiceHolder.service {
                    AIPromptSheet(
                        aiService: service,
                        currentRoutine: buildCurrentContext(),
                        exercises: catalog.map { $0.name },
                        onApply: { draft in
                            applyAIDraft(draft)
                        }
                    )
                }
            }
            .alert("Could not save", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveError ?? "")
            }
        }
        .sensoryFeedback(.success, trigger: saveSuccessPulse)
    }

    // MARK: - Sections

    private var basicsSection: some View {
        Section("Basics") {
            TextField("Routine name", text: $name)
            Picker("Gym (optional)", selection: $selectedGym) {
                Text("None").tag(Gym?.none)
                ForEach(gyms) { g in Text(g.name).tag(Gym?.some(g)) }
            }
        }
    }

    private var daysSection: some View {
        ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
            Section {
                dayContent(for: index)
            } header: {
                dayHeader(for: index)
            }
        }
    }

    private var addDaySection: some View {
        Section {
            Button {
                withAnimation {
                    days.append(RoutineDayDraft(label: "Day \(days.count + 1)"))
                }
            } label: {
                Label("Add Day", systemImage: "plus.circle")
            }
        }
    }

    @available(iOS 26, *)
    private var aiSection: some View {
        Section("AI Assistant") {
            Button {
                showAIPromptSheet = true
            } label: {
                HStack {
                    Label("Ask AI to help", systemImage: "sparkles")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var saveSection: some View {
        Section {
            Button {
                saveRoutine()
            } label: {
                if isSaving {
                    Label("Saving...", systemImage: "hourglass")
                } else {
                    Label("Save Routine", systemImage: "tray.and.arrow.down")
                }
            }
            .disabled(isSaving || name.isEmpty || days.isEmpty || days.allSatisfy { $0.items.isEmpty })
        }
    }

    // MARK: - Day UI Components

    @ViewBuilder
    private func dayHeader(for index: Int) -> some View {
        HStack {
            TextField("Day name", text: $days[index].label)
                .textFieldStyle(.plain)
                .font(.headline)
            Spacer()
            if days.count > 1 {
                Button(role: .destructive) {
                    withAnimation {
                        _ = days.remove(at: index)
                    }
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
            }
        }
    }

    @ViewBuilder
    private func dayContent(for dayIndex: Int) -> some View {
        ForEach(Array(days[dayIndex].items.enumerated()), id: \.element.id) { itemIndex, item in
            exerciseRow(dayIndex: dayIndex, itemIndex: itemIndex, item: item)
        }
        .onDelete { offsets in
            days[dayIndex].items.remove(atOffsets: offsets)
        }
        .onMove { from, to in
            days[dayIndex].items.move(fromOffsets: from, toOffset: to)
        }

        Button {
            editingDayIndex = dayIndex
            showExercisePicker = true
        } label: {
            Label("Add Exercise", systemImage: "plus")
        }
    }

    @ViewBuilder
    private func exerciseRow(dayIndex: Int, itemIndex: Int, item: RoutineItemDraft) -> some View {
        let isExpanded = expandedItemId == item.id

        VStack(alignment: .leading, spacing: 8) {
            // Main row - tap to expand
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedItemId = isExpanded ? nil : item.id
                }
            } label: {
                HStack {
                    Text(item.exerciseName)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(item.sets)x\(item.repMin)-\(item.repMax)")
                        .foregroundStyle(.secondary)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded inline editor
            if isExpanded {
                VStack(spacing: 12) {
                    HStack {
                        Text("Sets")
                            .frame(width: 60, alignment: .leading)
                        Stepper("\(days[dayIndex].items[itemIndex].sets)", value: $days[dayIndex].items[itemIndex].sets, in: 1...10)
                    }

                    HStack {
                        Text("Reps")
                            .frame(width: 60, alignment: .leading)
                        Stepper("\(days[dayIndex].items[itemIndex].repMin)", value: $days[dayIndex].items[itemIndex].repMin, in: 1...30)
                        Text("-")
                        Stepper("\(days[dayIndex].items[itemIndex].repMax)", value: $days[dayIndex].items[itemIndex].repMax, in: 1...30)
                    }

                    HStack {
                        Text("RPE")
                            .frame(width: 60, alignment: .leading)
                        TextField("e.g. RPE 8", text: Binding(
                            get: { days[dayIndex].items[itemIndex].rpeNote ?? "" },
                            set: { days[dayIndex].items[itemIndex].rpeNote = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Actions

    private func setupInitialState() {
        if let routine = editingRoutine {
            name = routine.name
            selectedGym = routine.gym
            days = routine.days.map { RoutineDayDraft(from: $0) }
        } else if days.isEmpty {
            // Start with one empty day for custom routines
            days = [RoutineDayDraft(label: "Day 1")]
        }
    }

    private func addExerciseToDay(_ exercise: Exercise, dayIndex: Int) {
        let item = RoutineItemDraft(
            exerciseName: exercise.name,
            unitOverride: exercise.defaultUnit
        )
        days[dayIndex].items.append(item)
    }

    private func saveRoutine() {
        guard !isSaving else { return }
        isSaving = true

        let routineDays = days.map { $0.toRoutineDay() }

        if let existing = editingRoutine {
            // Update existing routine
            existing.name = name
            existing.gym = selectedGym
            existing.days = routineDays
        } else {
            // Create new routine
            let routine = Routine(name: name, gym: selectedGym, days: routineDays)
            ctx.insert(routine)
        }

        do {
            try ctx.save()
            saveSuccessPulse.toggle()
            dismiss()
        } catch {
            if editingRoutine == nil {
                // Rollback insertion if it was a new routine
                // (existing routine changes will be rolled back automatically)
            }
            saveError = error.localizedDescription
            isSaving = false
        }
    }

    // MARK: - AI Helpers

    private func buildCurrentContext() -> CurrentRoutineContext {
        CurrentRoutineContext(
            name: name,
            days: days.map { day in
                CurrentRoutineContext.DayContext(
                    label: day.label,
                    exercises: day.items.map { $0.exerciseName }
                )
            }
        )
    }

    @available(iOS 26, *)
    private func applyAIDraft(_ draft: RoutineDraft) {
        let routine = draft.toRoutine(for: selectedGym)
        self.name = routine.name
        self.days = routine.days.map { RoutineDayDraft(from: $0) }
    }
}

// MARK: - Initializers for different entry points

extension RoutineBuilderView {
    /// Initialize for creating a new custom routine
    init(container: ModelContainer) {
        self.container = container
        self.editingRoutine = nil
    }

    /// Initialize for editing an existing routine
    init(container: ModelContainer, editing routine: Routine) {
        self.container = container
        self.editingRoutine = routine
    }

    /// Initialize with a template pre-applied
    init(container: ModelContainer, template: SplitType, gym: Gym? = nil) {
        self.container = container
        self.editingRoutine = nil
        let templateRoutine = LocalRulesEngine.makeRoutine(for: template, gym: gym)
        _name = State(initialValue: templateRoutine.name)
        _selectedGym = State(initialValue: gym)
        _days = State(initialValue: templateRoutine.days.map { RoutineDayDraft(from: $0) })
    }
}

// MARK: - AI Holder

final class AIHolder: ObservableObject {
    #if canImport(FoundationModels)
    @Published var service: FoundationAIService?
    #else
    @Published var service: Any?
    #endif

    func bootstrap(container: ModelContainer) {
        if #available(iOS 26, *) {
            #if canImport(FoundationModels)
            var tools: [any Tool] = []
            if let inventoryTool = (InventoryTool(container: container) as Any) as? any Tool {
                tools = [inventoryTool]
            }
            self.service = FoundationAIService(tools: tools)
            #endif
        }
    }
}
