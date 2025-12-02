//
//  RoutineListView.swift
//  GYMRar
//
//  Created by Alejandro Gonzalez on 10/11/25.
//

import SwiftUI
import SwiftData

struct RoutineListView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var ctx
    @Query(sort: \Routine.name) private var routines: [Routine]

    @State private var showNewRoutineOptions = false
    @State private var showTemplateSelector = false
    @State private var showCustomBuilder = false
    @State private var selectedTemplate: SplitType?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if routines.isEmpty {
                        emptyStateView
                    } else {
                        routinesList
                    }
                }
                .padding()
            }
            .neoBackground()
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showNewRoutineOptions = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                    }
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
        NeoCard(color: NeoColors.surface(for: colorScheme)) {
            VStack(spacing: 16) {
                Image(systemName: "dumbbell")
                    .font(.system(size: 50))
                    .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.4))

                Text("No Routines")
                    .font(NeoFont.headlineLarge)
                    .foregroundStyle(NeoColors.text(for: colorScheme))

                Text("Create your first routine to get started")
                    .font(NeoFont.bodyMedium)
                    .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.6))
                    .multilineTextAlignment(.center)

                NeoButton("Create Routine", icon: "plus", color: NeoColors.secondary) {
                    showNewRoutineOptions = true
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
    }

    private var routinesList: some View {
        VStack(spacing: 12) {
            ForEach(routines, id: \.id) { routine in
                NavigationLink {
                    RoutineDetailView(routine: routine, container: ctx.container)
                } label: {
                    NeoCard(color: NeoColors.surface(for: colorScheme)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(routine.name)
                                    .font(NeoFont.headlineMedium)
                                HStack(spacing: 8) {
                                    Label("\(routine.days.count) days", systemImage: "calendar")
                                    Label("\(routine.days.flatMap { $0.items }.count) exercises", systemImage: "figure.strengthtraining.traditional")
                                }
                                .font(NeoFont.labelSmall)
                                .foregroundStyle(NeoColors.secondary)
                            }
                            Spacer()
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

// MARK: - Template Selector

struct TemplateSelectorView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    let onSelect: (SplitType) -> Void

    private let templateColors: [SplitType: Color] = [
        .upperLower: NeoColors.primary,
        .pushPullLegs: NeoColors.secondary,
        .fullBody: NeoColors.accent,
        .broSplit: NeoColors.info
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    Text("Choose a template")
                        .font(NeoFont.labelMedium)
                        .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(SplitType.allCases.filter { $0 != .custom }) { split in
                        Button {
                            onSelect(split)
                            dismiss()
                        } label: {
                            NeoCard(color: templateColors[split] ?? NeoColors.primary) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(split.rawValue)
                                        .font(NeoFont.headlineMedium)
                                    Text(split.description)
                                        .font(NeoFont.bodySmall)
                                        .opacity(0.8)
                                    HStack {
                                        Image(systemName: "calendar")
                                        Text(split.defaultDayLabels.joined(separator: " • "))
                                            .font(NeoFont.labelSmall)
                                    }
                                    .opacity(0.7)
                                }
                                .foregroundStyle(NeoColors.text(for: .light))
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    Text("Templates provide a starting point. You can customize the routine after creation.")
                        .font(NeoFont.bodySmall)
                        .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.5))
                        .padding(.top, 8)
                }
                .padding()
            }
            .neoBackground()
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
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var routine: Routine
    let container: ModelContainer
    @State private var showEditor = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Overview section
                NeoSection("Overview", color: NeoColors.secondary) {
                    VStack(spacing: 0) {
                        HStack {
                            Text("Days")
                                .font(NeoFont.bodyLarge)
                            Spacer()
                            Text("\(routine.days.count)")
                                .font(NeoFont.numericSmall)
                        }
                        .padding(12)
                        .foregroundStyle(NeoColors.text(for: colorScheme))

                        NeoSectionDivider()

                        HStack {
                            Text("Exercises")
                                .font(NeoFont.bodyLarge)
                            Spacer()
                            Text("\(routine.days.flatMap { $0.items }.count)")
                                .font(NeoFont.numericSmall)
                        }
                        .padding(12)
                        .foregroundStyle(NeoColors.text(for: colorScheme))

                        if let gym = routine.gym {
                            NeoSectionDivider()
                            HStack {
                                Text("Gym")
                                    .font(NeoFont.bodyLarge)
                                Spacer()
                                Text(gym.name)
                                    .font(NeoFont.bodyMedium)
                                    .foregroundStyle(NeoColors.accent)
                            }
                            .padding(12)
                            .foregroundStyle(NeoColors.text(for: colorScheme))
                        }
                    }
                }

                // Days sections
                ForEach(routine.days) { day in
                    NeoSection(day.label, color: NeoColors.primary) {
                        VStack(spacing: 0) {
                            if day.items.isEmpty {
                                Text("No exercises")
                                    .font(NeoFont.bodyMedium)
                                    .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.6))
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                            } else {
                                ForEach(day.items) { item in
                                    HStack {
                                        Text(item.exerciseName)
                                            .font(NeoFont.bodyLarge)
                                        Spacer()
                                        Text("\(item.setScheme.sets)x\(item.setScheme.repMin)-\(item.setScheme.repMax)")
                                            .font(NeoFont.numericSmall)
                                            .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.7))
                                    }
                                    .padding(12)
                                    .foregroundStyle(NeoColors.text(for: colorScheme))

                                    if item.id != day.items.last?.id {
                                        NeoSectionDivider()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .neoBackground()
        .navigationTitle(routine.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showEditor = true
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            RoutineBuilderView(container: container, editing: routine)
        }
    }
}

#Preview("Routine List - Light") {
    RoutineListView()
        .modelContainer(for: [Routine.self, Gym.self])
        .preferredColorScheme(.light)
}

#Preview("Routine List - Dark") {
    RoutineListView()
        .modelContainer(for: [Routine.self, Gym.self])
        .preferredColorScheme(.dark)
}
