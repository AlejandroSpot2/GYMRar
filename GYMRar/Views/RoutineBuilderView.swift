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
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var ctx
    let container: ModelContainer
    @Query(sort: \Exercise.name) private var catalog: [Exercise]
    @Query private var gyms: [Gym]
    @Environment(\.dismiss) private var dismiss

    var editingRoutine: Routine?

    @State private var name: String = ""
    @State private var selectedGym: Gym?
    @State private var days: [RoutineDayDraft] = []

    @State private var isSaving = false
    @State private var saveError: String?
    @State private var saveSuccessPulse = false

    @State private var showExercisePicker = false
    @State private var editingDayIndex: Int?
    @State private var expandedItemId: UUID?

    @StateObject private var aiServiceHolder = AIHolder()
    @State private var showAIPromptSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    basicsSection
                    daysSection
                    addDaySection

                    if #available(iOS 26, *) {
                        aiSection
                    }

                    saveSection
                }
                .padding()
            }
            .neoBackground()
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(editingRoutine == nil ? "New Routine" : "Edit Routine")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
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
                ExercisePickerView { exercise in
                    if let dayIdx = editingDayIndex {
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
        NeoSection("Basics", color: NeoColors.secondary) {
            VStack(spacing: 16) {
                NeoTextField("Routine name", text: $name)

                NeoPicker("Gym (optional)", selection: $selectedGym) {
                    Text("None").tag(Gym?.none)
                    ForEach(gyms) { g in Text(g.name).tag(Gym?.some(g)) }
                }
            }
            .padding(16)
        }
    }

    private var daysSection: some View {
        ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
            NeoSection(day.label, color: NeoColors.primary) {
                VStack(spacing: 0) {
                    dayHeader(for: index)
                    NeoSectionDivider()
                    dayContent(for: index)
                }
            }
        }
    }

    private var addDaySection: some View {
        NeoButton("Add Day", icon: "plus.circle", variant: .outline, fullWidth: true) {
            withAnimation {
                days.append(RoutineDayDraft(label: "Day \(days.count + 1)"))
            }
        }
    }

    @available(iOS 26, *)
    private var aiSection: some View {
        NeoCard(color: NeoColors.info.opacity(0.2)) {
            Button {
                showAIPromptSheet = true
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(NeoColors.info)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI ASSISTANT")
                            .font(NeoFont.labelMedium)
                        Text("Ask AI to help build your routine")
                            .font(NeoFont.bodySmall)
                            .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.7))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.4))
                }
                .foregroundStyle(NeoColors.text(for: colorScheme))
            }
        }
    }

    private var saveSection: some View {
        NeoButton(
            isSaving ? "Saving..." : "Save Routine",
            icon: isSaving ? "hourglass" : "tray.and.arrow.down",
            size: .large,
            color: NeoColors.success,
            fullWidth: true
        ) {
            saveRoutine()
        }
        .disabled(isSaving || name.isEmpty || days.isEmpty || days.allSatisfy { $0.items.isEmpty })
    }

    // MARK: - Day UI Components

    @ViewBuilder
    private func dayHeader(for index: Int) -> some View {
        HStack {
            TextField("Day name", text: $days[index].label)
                .font(NeoFont.bodyLarge)
                .foregroundStyle(NeoColors.text(for: colorScheme))
            Spacer()
            if days.count > 1 {
                Button {
                    withAnimation {
                        _ = days.remove(at: index)
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(NeoColors.danger)
                }
            }
        }
        .padding(12)
    }

    @ViewBuilder
    private func dayContent(for dayIndex: Int) -> some View {
        ForEach(Array(days[dayIndex].items.enumerated()), id: \.element.id) { itemIndex, item in
            exerciseRow(dayIndex: dayIndex, itemIndex: itemIndex, item: item)

            if itemIndex < days[dayIndex].items.count - 1 {
                NeoSectionDivider()
            }
        }

        NeoSectionDivider()

        Button {
            editingDayIndex = dayIndex
            showExercisePicker = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Exercise")
            }
            .font(NeoFont.bodyLarge)
            .foregroundStyle(NeoColors.primary)
            .frame(maxWidth: .infinity)
            .padding(12)
        }
    }

    @ViewBuilder
    private func exerciseRow(dayIndex: Int, itemIndex: Int, item: RoutineItemDraft) -> some View {
        let isExpanded = expandedItemId == item.id

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expandedItemId = isExpanded ? nil : item.id
                    }
                } label: {
                    HStack {
                        Text(item.exerciseName)
                            .font(NeoFont.bodyLarge)
                            .foregroundStyle(NeoColors.text(for: colorScheme))
                        Spacer()
                        Text("\(item.sets)x\(item.repMin)-\(item.repMax)")
                            .font(NeoFont.numericSmall)
                            .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.7))
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.5))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    days[dayIndex].items.remove(at: itemIndex)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(NeoColors.danger)
                }
            }

            if isExpanded {
                VStack(spacing: 12) {
                    NeoStepper("Sets", value: $days[dayIndex].items[itemIndex].sets, in: 1...10)

                    HStack(spacing: 8) {
                        Text("Reps")
                            .font(NeoFont.bodyLarge)
                            .foregroundStyle(NeoColors.text(for: colorScheme))
                        Spacer()
                        NeoCompactStepper(value: $days[dayIndex].items[itemIndex].repMin, in: 1...30)
                        Text("-")
                            .font(NeoFont.bodyLarge)
                            .foregroundStyle(NeoColors.text(for: colorScheme))
                        NeoCompactStepper(value: $days[dayIndex].items[itemIndex].repMax, in: 1...30)
                    }

                    NeoTextField("RPE note (e.g. RPE 8)", text: Binding(
                        get: { days[dayIndex].items[itemIndex].rpeNote ?? "" },
                        set: { days[dayIndex].items[itemIndex].rpeNote = $0.isEmpty ? nil : $0 }
                    ))
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
    }

    // MARK: - Actions

    private func setupInitialState() {
        if let routine = editingRoutine {
            name = routine.name
            selectedGym = routine.gym
            days = routine.days.map { RoutineDayDraft(from: $0) }
        } else if days.isEmpty {
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
            existing.name = name
            existing.gym = selectedGym
            existing.days = routineDays
        } else {
            let routine = Routine(name: name, gym: selectedGym, days: routineDays)
            ctx.insert(routine)
        }

        do {
            try ctx.save()
            saveSuccessPulse.toggle()
            dismiss()
        } catch {
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
    init(container: ModelContainer) {
        self.container = container
        self.editingRoutine = nil
    }

    init(container: ModelContainer, editing routine: Routine) {
        self.container = container
        self.editingRoutine = routine
    }

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

#Preview("Routine Builder - Light") {
    RoutineBuilderView(container: try! ModelContainer(for: Routine.self, Exercise.self, Gym.self))
        .preferredColorScheme(.light)
}

#Preview("Routine Builder - Dark") {
    RoutineBuilderView(container: try! ModelContainer(for: Routine.self, Exercise.self, Gym.self))
        .preferredColorScheme(.dark)
}
