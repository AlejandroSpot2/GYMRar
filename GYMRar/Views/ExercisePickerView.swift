import SwiftUI
import SwiftData

/// Vista de selección de ejercicios con búsqueda y agrupación por músculo
struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var catalog: [Exercise]

    @State private var searchText: String = ""
    let onSelect: (Exercise) -> Void

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
            List {
                if groupedExercises.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ForEach(groupedExercises, id: \.0) { group, exercises in
                        Section(group.displayName) {
                            ForEach(exercises) { exercise in
                                Button {
                                    onSelect(exercise)
                                    dismiss()
                                } label: {
                                    HStack {
                                        Text(exercise.name)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if exercise.isBodyweight {
                                            Text("BW")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
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

#Preview {
    ExercisePickerView { exercise in
        print("Selected: \(exercise.name)")
    }
    .modelContainer(for: Exercise.self, inMemory: true)
}
