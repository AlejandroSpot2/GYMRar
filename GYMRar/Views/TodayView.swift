//
//  TodayView.swift
//  GYMRar
//
//  Created by Alejandro Gonzalez on 10/11/25.
//


import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(sort: \Routine.name) private var routines: [Routine]
    @State private var selectedRoutine: Routine?
    @State private var navigateLog = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("Routine", selection: $selectedRoutine) {
                    Text("— Selecciona —").tag(Routine?.none) // <- evita warning de selección nil
                    ForEach(routines, id: \.id) { r in
                        Text(r.name).tag(Routine?.some(r))
                    }
                }.pickerStyle(.menu)

                if let day = selectedRoutine?.days.first {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Plan de hoy: \(day.label)").font(.headline)
                        ForEach(day.items, id: \.id) { it in
                            Text("• \(it.exerciseName) \(it.setScheme.sets)x\(it.setScheme.repMin)-\(it.setScheme.repMax)")
                                .foregroundStyle(.secondary)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("Crea o selecciona una rutina").foregroundStyle(.secondary)
                }

                Button {
                    navigateLog = true
                } label: {
                    Label("Start Workout", systemImage: "play.fill").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedRoutine == nil)

                Spacer()
            }
            .padding()
            .navigationTitle("Today")
            .navigationDestination(isPresented: $navigateLog) {
                LogWorkoutView(routine: selectedRoutine)
            }
        }
    }
}
