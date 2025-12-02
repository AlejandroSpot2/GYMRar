//
//  HistoryView.swift
//  GYMRar
//
//  Created by Alejandro Gonzalez on 10/11/25.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var ctx
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @State private var showClearConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if workouts.isEmpty {
                        NeoCard(color: NeoColors.surface(for: colorScheme)) {
                            VStack(spacing: 12) {
                                Image(systemName: "clock.badge.questionmark")
                                    .font(.system(size: 40))
                                    .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.4))
                                Text("No workouts yet")
                                    .font(NeoFont.bodyMedium)
                                    .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        }
                    } else {
                        ForEach(workouts, id: \.id) { workout in
                            NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                                NeoCard(color: NeoColors.surface(for: colorScheme)) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(workout.date.formatted(date: .abbreviated, time: .omitted))
                                                .font(NeoFont.headlineMedium)
                                            if let gym = workout.gym {
                                                Text(gym.name)
                                                    .font(NeoFont.bodySmall)
                                                    .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.6))
                                            }
                                            Text("\(workout.entries.count) sets")
                                                .font(NeoFont.labelSmall)
                                                .foregroundStyle(NeoColors.info)
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

                        // Clear history button at bottom
                        NeoButton(
                            "Clear History",
                            icon: "trash",
                            variant: .outline,
                            color: NeoColors.danger,
                            fullWidth: true
                        ) {
                            showClearConfirm = true
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
            }
            .neoBackground()
            .navigationTitle("History")
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

// MARK: - Workout Detail View

private struct WorkoutDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    let workout: Workout

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if workout.entries.isEmpty {
                    NeoCard(color: NeoColors.surface(for: colorScheme)) {
                        Text("Sin sets registrados")
                            .font(NeoFont.bodyMedium)
                            .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                } else {
                    NeoSection("Workout Summary", color: NeoColors.info) {
                        VStack(spacing: 0) {
                            ForEach(workout.entries) { entry in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(entry.exerciseName)
                                            .font(NeoFont.headlineMedium)
                                        Spacer()
                                        Text("\(entry.reps) reps")
                                            .font(NeoFont.numericSmall)
                                    }

                                    HStack {
                                        Text("\(entry.weightValue, specifier: "%.1f") \(entry.weightUnit.symbol)")
                                            .font(NeoFont.bodyMedium)
                                            .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.7))

                                        if let alias = entry.calibrationAlias {
                                            Spacer()
                                            Text("Machine: \(alias)")
                                                .font(NeoFont.labelSmall)
                                                .foregroundStyle(NeoColors.accent)
                                        }
                                    }
                                }
                                .padding(12)
                                .foregroundStyle(NeoColors.text(for: colorScheme))

                                if entry.id != workout.entries.last?.id {
                                    NeoSectionDivider()
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .neoBackground()
        .navigationTitle(workout.date.formatted(date: .abbreviated, time: .omitted))
    }
}

#Preview("History - Light") {
    HistoryView()
        .modelContainer(for: [Workout.self, Gym.self])
        .preferredColorScheme(.light)
}

#Preview("History - Dark") {
    HistoryView()
        .modelContainer(for: [Workout.self, Gym.self])
        .preferredColorScheme(.dark)
}
