//
//  RoutineEngine.swift
//  GYMRar
//
//  Created by Alejandro Gonzalez on 10/11/25.
//

import Foundation

struct RoutineSpec: Codable {
    var name: String
    var daysPerWeek: Int
    var split: String // "UL"
    var preferences: [String]
    var availableExercises: [String]
    var gymName: String?
}

enum LocalRulesEngine {
    static func makeUL(days: Int) -> Routine {
        let u = RoutineDay(label: "Upper", items: [
            RoutineItem(exerciseName: "Bench Press", setScheme: .init(sets: 4, repMin: 6, repMax: 10, rpeNote: "RPE 8")),
            RoutineItem(exerciseName: "Row (Barbell)", setScheme: .init(sets: 4, repMin: 8, repMax: 12, rpeNote: nil)),
            RoutineItem(exerciseName: "Overhead Press", setScheme: .init(sets: 3, repMin: 6, repMax: 10, rpeNote: nil)),
            RoutineItem(exerciseName: "Lat Pulldown", setScheme: .init(sets: 3, repMin: 8, repMax: 12, rpeNote: nil)),
            RoutineItem(exerciseName: "Dumbbell Curl", setScheme: .init(sets: 3, repMin: 10, repMax: 15, rpeNote: nil)),
            RoutineItem(exerciseName: "Triceps Pushdown", setScheme: .init(sets: 3, repMin: 10, repMax: 15, rpeNote: nil))
        ])
        let l = RoutineDay(label: "Lower", items: [
            RoutineItem(exerciseName: "Back Squat", setScheme: .init(sets: 4, repMin: 5, repMax: 8, rpeNote: "RPE 8")),
            RoutineItem(exerciseName: "Romanian Deadlift", setScheme: .init(sets: 3, repMin: 6, repMax: 10, rpeNote: nil)),
            RoutineItem(exerciseName: "Leg Press", setScheme: .init(sets: 3, repMin: 10, repMax: 15, rpeNote: nil)),
            RoutineItem(exerciseName: "Leg Curl", setScheme: .init(sets: 3, repMin: 10, repMax: 15, rpeNote: nil)),
            RoutineItem(exerciseName: "Calf Raise", setScheme: .init(sets: 3, repMin: 12, repMax: 20, rpeNote: nil))
        ])
        var daysArr: [RoutineDay] = []
        for i in 0..<max(2, days) { daysArr.append(i % 2 == 0 ? u : l) }
        return Routine(name: "UL \(days)x", days: daysArr)
    }

    static func nextLoad(current: Double, achievedReps: Int, scheme: SetScheme) -> Double {
        if achievedReps >= scheme.repMax { return (current * 1.025).rounded(.toNearestOrAwayFromZero) }
        if achievedReps < scheme.repMin { return (current * 0.975).rounded(.toNearestOrAwayFromZero) }
        return current
    }
}
