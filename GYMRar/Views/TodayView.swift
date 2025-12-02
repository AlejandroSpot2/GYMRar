//
//  TodayView.swift
//  GYMRar
//
//  Created by Alejandro Gonzalez on 10/11/25.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Routine.name) private var routines: [Routine]
    @State private var selectedRoutine: Routine?
    @State private var navigateLog = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Routine selector
                    NeoSection("Select Routine", color: NeoColors.primary) {
                        NeoPicker(selection: $selectedRoutine) {
                            Text("— Selecciona —").tag(Routine?.none)
                            ForEach(routines, id: \.id) { r in
                                Text(r.name).tag(Routine?.some(r))
                            }
                        }
                        .padding(16)
                    }

                    // Today's plan preview
                    if let day = selectedRoutine?.days.first {
                        NeoSection("Plan de hoy: \(day.label)", color: NeoColors.accent) {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(day.items, id: \.id) { item in
                                    HStack {
                                        Text(item.exerciseName)
                                            .font(NeoFont.bodyLarge)
                                        Spacer()
                                        Text("\(item.setScheme.sets)x\(item.setScheme.repMin)-\(item.setScheme.repMax)")
                                            .font(NeoFont.numericSmall)
                                            .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.7))
                                    }
                                    .padding(.vertical, 4)

                                    if item.id != day.items.last?.id {
                                        NeoSectionDivider()
                                    }
                                }
                            }
                            .padding(16)
                            .foregroundStyle(NeoColors.text(for: colorScheme))
                        }
                    } else {
                        NeoCard(color: NeoColors.surface(for: colorScheme)) {
                            VStack(spacing: 12) {
                                Image(systemName: "figure.run")
                                    .font(.system(size: 40))
                                    .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.4))
                                Text("Crea o selecciona una rutina")
                                    .font(NeoFont.bodyMedium)
                                    .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        }
                    }

                    Spacer(minLength: 20)

                    // Start workout button
                    NeoButton(
                        "Start Workout",
                        icon: "play.fill",
                        size: .large,
                        color: NeoColors.success,
                        fullWidth: true
                    ) {
                        navigateLog = true
                    }
                    .disabled(selectedRoutine == nil)
                }
                .padding()
            }
            .neoBackground()
            .navigationTitle("Today")
            .navigationDestination(isPresented: $navigateLog) {
                LogWorkoutView(routine: selectedRoutine)
            }
        }
    }
}

#Preview("Today - Light") {
    TodayView()
        .modelContainer(for: [Routine.self, Exercise.self])
        .preferredColorScheme(.light)
}

#Preview("Today - Dark") {
    TodayView()
        .modelContainer(for: [Routine.self, Exercise.self])
        .preferredColorScheme(.dark)
}
