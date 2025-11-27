//
//  DataSeeder.swift
//  GYMRar
//
//  Created by Alejandro Gonzalez on 10/11/25.
//

import Foundation
import SwiftData

enum DataSeeder {
    static func seedIfNeeded(container: ModelContainer) {
        let ctx = ModelContext(container)
        let existing = try? ctx.fetch(FetchDescriptor<Gym>())
        if let e = existing, !e.isEmpty { return }

        let gymA = Gym(name: "Gym A", defaultUnit: .kg)
        let gymB = Gym(name: "Gym B", defaultUnit: .lb)

        let catalog: [Exercise] = [
            // Chest
            Exercise(name: "Bench Press", group: .chest),
            Exercise(name: "Incline Dumbbell Press", group: .chest),
            Exercise(name: "Dumbbell Press", group: .chest),
            Exercise(name: "Cable Fly", group: .chest),
            Exercise(name: "Dips", group: .chest),
            // Back
            Exercise(name: "Row (Barbell)", group: .back),
            Exercise(name: "Lat Pulldown", group: .back),
            Exercise(name: "Cable Row", group: .back),
            Exercise(name: "Face Pull", group: .back),
            Exercise(name: "Shrugs", group: .back),
            // Shoulders
            Exercise(name: "Overhead Press", group: .shoulders),
            Exercise(name: "Lateral Raise", group: .shoulders),
            Exercise(name: "Rear Delt Fly", group: .shoulders),
            // Biceps
            Exercise(name: "Dumbbell Curl", group: .biceps),
            Exercise(name: "Hammer Curl", group: .biceps),
            // Triceps
            Exercise(name: "Triceps Pushdown", group: .triceps),
            Exercise(name: "Skull Crushers", group: .triceps),
            // Legs
            Exercise(name: "Back Squat", group: .quads),
            Exercise(name: "Leg Press", group: .quads),
            Exercise(name: "Romanian Deadlift", group: .hamstrings),
            Exercise(name: "Leg Curl", group: .hamstrings),
            Exercise(name: "Calf Raise", group: .calves),
            // Core
            Exercise(name: "Plank", group: .core),
            Exercise(name: "Cable Crunch", group: .core)
        ]

        let cal1 = Calibration(gym: gymA, baseExerciseName: "Leg Press", alias: "Prensa A (Trineo 35kg)", a: 1.0, b: 35.0, machineUnit: .kg)
        let cal2 = Calibration(gym: gymB, baseExerciseName: "Lat Pulldown", alias: "Lat Pulldown B (0.5x)", a: 0.5, b: 0.0, machineUnit: .lb)

        let routine = LocalRulesEngine.makeUL(days: 4)
        routine.gym = gymA

        [gymA, gymB].forEach { ctx.insert($0) }
        catalog.forEach { ctx.insert($0) }
        [cal1, cal2].forEach { ctx.insert($0) }
        ctx.insert(routine)

        try? ctx.save()
    }
}
