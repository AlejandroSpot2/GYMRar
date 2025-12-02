//
//  ExercisePickerView.swift
//  GYMRar
//
//  Exercise selection view with search and muscle group grouping
//

import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var catalog: [Exercise]

    @State private var searchText: String = ""
    let onSelect: (Exercise) -> Void

    private let muscleGroupColors: [MuscleGroup: Color] = [
        .chest: NeoColors.danger,
        .back: NeoColors.info,
        .shoulders: NeoColors.warning,
        .biceps: NeoColors.secondary,
        .triceps: NeoColors.accent,
        .legs: NeoColors.primary,
        .core: NeoColors.success,
        .fullBody: NeoColors.info
    ]

    private var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return catalog
        }
        return catalog.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var groupedExercises: [(MuscleGroup, [Exercise])] {
        let grouped = Dictionary(grouping: filteredExercises) { $0.group }
        return MuscleGroup.sortOrder.compactMap { group in
            guard let exercises = grouped[group], !exercises.isEmpty else { return nil }
            return (group, exercises.sorted { $0.name < $1.name })
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                NeoTextField("Search exercises", text: $searchText, icon: "magnifyingglass")
                    .padding()

                ScrollView {
                    VStack(spacing: 12) {
                        if groupedExercises.isEmpty {
                            NeoCard(color: NeoColors.surface(for: colorScheme)) {
                                VStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 40))
                                        .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.4))
                                    Text("No exercises found for \"\(searchText)\"")
                                        .font(NeoFont.bodyMedium)
                                        .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.6))
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 32)
                            }
                        } else {
                            ForEach(groupedExercises, id: \.0) { group, exercises in
                                NeoSection(group.displayName, color: muscleGroupColors[group] ?? NeoColors.primary) {
                                    VStack(spacing: 0) {
                                        ForEach(exercises) { exercise in
                                            Button {
                                                onSelect(exercise)
                                                dismiss()
                                            } label: {
                                                HStack {
                                                    Text(exercise.name)
                                                        .font(NeoFont.bodyLarge)
                                                    Spacer()
                                                    if exercise.isBodyweight {
                                                        Text("BW")
                                                            .font(NeoFont.labelSmall)
                                                            .foregroundStyle(NeoColors.accent)
                                                    }
                                                    Image(systemName: "plus.circle")
                                                        .font(.system(size: 16, weight: .bold))
                                                        .foregroundStyle(muscleGroupColors[group] ?? NeoColors.primary)
                                                }
                                                .foregroundStyle(NeoColors.text(for: colorScheme))
                                                .padding(12)
                                                .contentShape(Rectangle())
                                            }

                                            if exercise.id != exercises.last?.id {
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
            }
            .neoBackground()
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview("Exercise Picker - Light") {
    ExercisePickerView { exercise in
        print("Selected: \(exercise.name)")
    }
    .modelContainer(for: Exercise.self, inMemory: true)
    .preferredColorScheme(.light)
}

#Preview("Exercise Picker - Dark") {
    ExercisePickerView { exercise in
        print("Selected: \(exercise.name)")
    }
    .modelContainer(for: Exercise.self, inMemory: true)
    .preferredColorScheme(.dark)
}
