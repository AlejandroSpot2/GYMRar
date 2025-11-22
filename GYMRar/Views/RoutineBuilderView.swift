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

struct RoutineBuilderView: View {
    @Environment(\.modelContext) private var ctx
    let container: ModelContainer
    @Query(sort: \Exercise.name) private var catalog: [Exercise]
    @Query private var gyms: [Gym]
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = "My UL"
    @State private var daysPerWeek: Int = 4
    @State private var selectedGym: Gym?

    @State private var upperItems: [RoutineItem] = []
    @State private var lowerItems: [RoutineItem] = []

    // IA Apple
    @StateObject private var aiServiceHolder = AIHolder()

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Routine name", text: $name)
                    Picker("Gym (optional)", selection: $selectedGym) {
                        Text("None").tag(Gym?.none)
                        ForEach(gyms) { g in Text(g.name).tag(Gym?.some(g)) }
                    }
                    Stepper("Days per week: \(daysPerWeek)", value: $daysPerWeek, in: 2...6)
                }

                Section("Upper") { exercisePicker(list: $upperItems) }
                Section("Lower") { exercisePicker(list: $lowerItems) }

                if #available(iOS 26, *) {
                    Section("AI (Apple)") {
                        Button {
                            Task {
                                await generateWithAppleAI()
                            }
                        } label: { Label("Generar con IA (Apple)", systemImage: "sparkles") }

                        #if canImport(FoundationModels)
                        if let draft = aiServiceHolder.service?.liveDraft {
                            AIPreviewOverlay(draft: draft)
                        }
                        #endif
                    }
                } else {
                    Text("Foundation Models requiere iOS 26.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Section {
                    Button("Save Routine") {
                        let r = Routine(name: name, gym: selectedGym, days: [
                            RoutineDay(label: "Upper", items: upperItems),
                            RoutineDay(label: "Lower", items: lowerItems)
                        ])
                        ctx.insert(r); try? ctx.save(); dismiss()
                    }
                    .disabled(upperItems.isEmpty || lowerItems.isEmpty)
                }
            }
            .navigationTitle("Routine Builder")
            .onAppear {
                if #available(iOS 26, *) {
                    // Creamos sesión IA con tool del inventario
                    if aiServiceHolder.service == nil {
                        aiServiceHolder.bootstrap(container: container)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func exercisePicker(list: Binding<[RoutineItem]>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(list.wrappedValue) { item in
                HStack {
                    Text(item.exerciseName)
                    Spacer()
                    Text("\(item.setScheme.sets)x\(item.setScheme.repMin)-\(item.setScheme.repMax)")
                        .foregroundStyle(.secondary)
                }
            }
            Menu("Add exercise") {
                ForEach(catalog) { ex in
                    Button(ex.name) {
                        list.wrappedValue.append(
                            RoutineItem(exerciseName: ex.name,
                                        setScheme: .init(sets: 3, repMin: 8, repMax: 12, rpeNote: nil),
                                        progression: .doubleProgression,
                                        unitOverride: ex.defaultUnit)
                        )
                    }
                }
            }
        }
    }

    // MARK: - IA Apple

    private func generateWithAppleAI() async {
        #if canImport(FoundationModels)
        guard #available(iOS 26, *) else { return }
        guard let service = aiServiceHolder.service else { return }

        let names = catalog.map { $0.name }
        do {
            let draft = try await service.generateRoutine(daysPerWeek: daysPerWeek,
                                                          availableExercises: names,
                                                          routineNameHint: name)
            let routine = draft.toRoutine(for: selectedGym)
            self.name = routine.name
            if let u = routine.days.first(where: { $0.label.lowercased().contains("upper") }) { self.upperItems = u.items }
            if let l = routine.days.first(where: { $0.label.lowercased().contains("lower") }) { self.lowerItems = l.items }
        } catch {
            print("AI error: \(error)")
        }
        #else
        return
        #endif
    }
}

// Holder para no inicializar sesión IA si no es iOS 26
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
            #else
            // Tool protocol not available; skip AI setup
            #endif
        }
    }
}
