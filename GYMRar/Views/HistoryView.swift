//
//  HistoryView.swift
//  GYMRar
//
//  Created by Alejandro Gonzalez on 10/11/25.
//


import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]

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
            }
            .navigationTitle("History")
        }
    }
}

private struct WorkoutDetail: View {
    var workout: Workout
    var body: some View {
        List {
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
        .navigationTitle(workout.date.formatted(date: .abbreviated, time: .omitted))
    }
}
