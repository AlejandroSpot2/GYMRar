//
//  GYMRarApp.swift
//  GYMRar
//
//  Created by Alejandro Gonzalez on 10/11/25.
//

import SwiftUI
import SwiftData

@main
struct GYMRarApp: App {

    // Creamos explícitamente la carpeta Application Support y fijamos URL del store
    private static func makeContainer() -> ModelContainer {
        let schema = Schema([
            Gym.self, Calibration.self, Exercise.self,
            Routine.self, RoutineDay.self, RoutineItem.self,
            Workout.self, WorkoutSet.self
        ])

        let fm = FileManager.default
        let supportURL = try! fm.url(for: .applicationSupportDirectory,
                                     in: .userDomainMask,
                                     appropriateFor: nil,
                                     create: true)
        let storeURL = supportURL.appendingPathComponent("default.store")

        let config = ModelConfiguration(url: storeURL)
        return try! ModelContainer(for: schema, configurations: [config])
    }

    var sharedModelContainer: ModelContainer = makeContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .buttonStyle(PressFeedbackButtonStyle())
                .modelContainer(sharedModelContainer)
                .onAppear {
                    DataSeeder.seedIfNeeded(container: sharedModelContainer)
                }
        }
    }
}
