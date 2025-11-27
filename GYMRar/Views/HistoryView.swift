//
//  HistoryView.swift
//  GYMRar
//
//  Created by Alejandro Gonzalez on 10/11/25.
//


import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @State private var showClearConfirm = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(workouts, id: \.id) { w in
                    NavigationLink(destination: WorkoutDetail(workout: w)) {
                        VStack(alignment: .leading) {
                            Text(w.date.formatted(date: .abbreviated, time: .omitted))
                            if let gym = w.gym { Text(gym.name).foregroundStyle(.secondary) }
                        }
                    }
                }
                .onDelete { idx in
                    idx.map { workouts[$0] }.forEach { ctx.delete($0) }
                    try? ctx.save()
                }
                if workouts.isEmpty {
                    Text("No workouts yet").foregroundStyle(.secondary)
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton().disabled(workouts.isEmpty)
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("Clear History", role: .destructive) { showClearConfirm = true }
                        .disabled(workouts.isEmpty)
                }
            }
            .confirmationDialog("Clear all history?", isPresented: $showClearConfirm, titleVisibility: .visible) {
                Button("Delete all workouts", role: .destructive) {
                    workouts.forEach { ctx.delete($0) }
                    try? ctx.save()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

private struct WorkoutDetail: View {
    var workout: Workout
    var body: some View {
        List {
            if workout.entries.isEmpty {
                Text("Sin sets registrados").foregroundStyle(.secondary)
            } else {
                ForEach(workout.entries) { s in
                    VStack(alignment: .leading) {
                        Text(s.exerciseName).font(.headline)
                        Text("\(s.reps) reps @ \(s.weightValue, specifier: "%.1f") \(s.weightUnit.symbol)")
                            .foregroundStyle(.secondary)
                        if let a = s.calibrationAlias {
                            Text("Machine: \(a)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(workout.date.formatted(date: .abbreviated, time: .omitted))
    }
}
