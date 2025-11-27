//
//  RoutineListView.swift
//  GYMRar
//
//  Created by Alejandro Gonzalez on 10/11/25.
//

import SwiftUI
import SwiftData

struct RoutineListView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \Routine.name) private var routines: [Routine]

    @State private var showNewRoutineOptions = false
    @State private var showTemplateSelector = false
    @State private var showCustomBuilder = false
    @State private var selectedTemplate: SplitType?

    var body: some View {
        NavigationStack {
            Group {
                if routines.isEmpty {
                    emptyStateView
                } else {
                    routinesList
                }
            }
            .navigationTitle("Routines")
            .toolbar {
                Button {
                    showNewRoutineOptions = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .confirmationDialog("New Routine", isPresented: $showNewRoutineOptions, titleVisibility: .visible) {
                Button("From Template") {
                    showTemplateSelector = true
                }
                Button("Custom") {
                    showCustomBuilder = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Choose how to create your routine")
            }
            .sheet(isPresented: $showTemplateSelector) {
                TemplateSelectorView { template in
                    selectedTemplate = template
                }
            }
            .sheet(isPresented: $showCustomBuilder) {
                RoutineBuilderView(container: ctx.container)
            }
            .sheet(item: $selectedTemplate) { template in
                RoutineBuilderView(container: ctx.container, template: template)
            }
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Routines", systemImage: "dumbbell")
        } description: {
            Text("Create your first routine to get started")
        } actions: {
            Button("Create Routine") {
                showNewRoutineOptions = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var routinesList: some View {
        List {
            ForEach(routines, id: \.id) { routine in
                NavigationLink {
                    RoutineDetailView(routine: routine, container: ctx.container)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(routine.name)
                            .font(.headline)
                        Text("\(routine.days.count) days • \(routine.days.flatMap { $0.items }.count) exercises")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete { idx in
                idx.map { routines[$0] }.forEach { ctx.delete($0) }
                try? ctx.save()
            }
        }
    }
}

// MARK: - Template Selector

struct TemplateSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (SplitType) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(SplitType.allCases.filter { $0 != .custom }) { split in
                        Button {
                            onSelect(split)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(split.rawValue)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(split.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Days: \(split.defaultDayLabels.joined(separator: ", "))")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Choose a template")
                } footer: {
                    Text("Templates provide a starting point. You can customize the routine after creation.")
                }
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Routine Detail View

private struct RoutineDetailView: View {
    @Bindable var routine: Routine
    let container: ModelContainer
    @State private var showEditor = false

    var body: some View {
        List {
            Section("Overview") {
                LabeledContent("Days", value: "\(routine.days.count)")
                LabeledContent("Exercises", value: "\(routine.days.flatMap { $0.items }.count)")
                if let gym = routine.gym {
                    LabeledContent("Gym", value: gym.name)
                }
            }

            ForEach(routine.days) { day in
                Section(day.label) {
                    if day.items.isEmpty {
                        Text("No exercises")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(day.items) { item in
                            HStack {
                                Text(item.exerciseName)
                                Spacer()
                                Text("\(item.setScheme.sets)x\(item.setScheme.repMin)-\(item.setScheme.repMax)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(routine.name)
        .toolbar {
            Button("Edit") {
                showEditor = true
            }
        }
        .sheet(isPresented: $showEditor) {
            RoutineBuilderView(container: container, editing: routine)
        }
    }
}

