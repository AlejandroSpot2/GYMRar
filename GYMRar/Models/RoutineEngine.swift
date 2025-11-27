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

    // MARK: - Factory Method

    /// Crea una rutina basada en el tipo de split seleccionado
    static func makeRoutine(for split: SplitType, gym: Gym? = nil) -> Routine {
        switch split {
        case .upperLower:
            return makeUL(gym: gym)
        case .pushPullLegs:
            return makePPL(gym: gym)
        case .fullBody:
            return makeFullBody(gym: gym)
        case .broSplit:
            return makeBroSplit(gym: gym)
        case .custom:
            return Routine(name: "Custom Routine", gym: gym, days: [
                RoutineDay(label: "Day 1", items: [])
            ])
        }
    }

    // MARK: - Template Generators

    static func makeUL(gym: Gym? = nil) -> Routine {
        let upper = RoutineDay(label: "Upper", items: [
            makeItem("Bench Press", sets: 4, repMin: 6, repMax: 10, rpe: "RPE 8"),
            makeItem("Row (Barbell)", sets: 4, repMin: 8, repMax: 12),
            makeItem("Overhead Press", sets: 3, repMin: 6, repMax: 10),
            makeItem("Lat Pulldown", sets: 3, repMin: 8, repMax: 12),
            makeItem("Dumbbell Curl", sets: 3, repMin: 10, repMax: 15),
            makeItem("Triceps Pushdown", sets: 3, repMin: 10, repMax: 15)
        ])
        let lower = RoutineDay(label: "Lower", items: [
            makeItem("Back Squat", sets: 4, repMin: 5, repMax: 8, rpe: "RPE 8"),
            makeItem("Romanian Deadlift", sets: 3, repMin: 6, repMax: 10),
            makeItem("Leg Press", sets: 3, repMin: 10, repMax: 15),
            makeItem("Leg Curl", sets: 3, repMin: 10, repMax: 15),
            makeItem("Calf Raise", sets: 3, repMin: 12, repMax: 20)
        ])
        return Routine(name: "Upper/Lower", gym: gym, days: [upper, lower])
    }

    static func makePPL(gym: Gym? = nil) -> Routine {
        let push = RoutineDay(label: "Push", items: [
            makeItem("Bench Press", sets: 4, repMin: 6, repMax: 10, rpe: "RPE 8"),
            makeItem("Overhead Press", sets: 3, repMin: 6, repMax: 10),
            makeItem("Incline Dumbbell Press", sets: 3, repMin: 8, repMax: 12),
            makeItem("Triceps Pushdown", sets: 3, repMin: 10, repMax: 15),
            makeItem("Lateral Raise", sets: 3, repMin: 12, repMax: 15)
        ])
        let pull = RoutineDay(label: "Pull", items: [
            makeItem("Row (Barbell)", sets: 4, repMin: 6, repMax: 10, rpe: "RPE 8"),
            makeItem("Lat Pulldown", sets: 3, repMin: 8, repMax: 12),
            makeItem("Face Pull", sets: 3, repMin: 12, repMax: 15),
            makeItem("Dumbbell Curl", sets: 3, repMin: 10, repMax: 15),
            makeItem("Hammer Curl", sets: 3, repMin: 10, repMax: 15)
        ])
        let legs = RoutineDay(label: "Legs", items: [
            makeItem("Back Squat", sets: 4, repMin: 5, repMax: 8, rpe: "RPE 8"),
            makeItem("Romanian Deadlift", sets: 3, repMin: 6, repMax: 10),
            makeItem("Leg Press", sets: 3, repMin: 10, repMax: 15),
            makeItem("Leg Curl", sets: 3, repMin: 10, repMax: 15),
            makeItem("Calf Raise", sets: 4, repMin: 12, repMax: 20)
        ])
        return Routine(name: "Push/Pull/Legs", gym: gym, days: [push, pull, legs])
    }

    static func makeFullBody(gym: Gym? = nil) -> Routine {
        let dayA = RoutineDay(label: "Full Body A", items: [
            makeItem("Back Squat", sets: 3, repMin: 5, repMax: 8, rpe: "RPE 8"),
            makeItem("Bench Press", sets: 3, repMin: 6, repMax: 10),
            makeItem("Row (Barbell)", sets: 3, repMin: 8, repMax: 12),
            makeItem("Overhead Press", sets: 2, repMin: 8, repMax: 12),
            makeItem("Dumbbell Curl", sets: 2, repMin: 10, repMax: 15)
        ])
        let dayB = RoutineDay(label: "Full Body B", items: [
            makeItem("Romanian Deadlift", sets: 3, repMin: 6, repMax: 10, rpe: "RPE 8"),
            makeItem("Incline Dumbbell Press", sets: 3, repMin: 8, repMax: 12),
            makeItem("Lat Pulldown", sets: 3, repMin: 8, repMax: 12),
            makeItem("Leg Press", sets: 3, repMin: 10, repMax: 15),
            makeItem("Triceps Pushdown", sets: 2, repMin: 10, repMax: 15)
        ])
        let dayC = RoutineDay(label: "Full Body C", items: [
            makeItem("Leg Press", sets: 3, repMin: 8, repMax: 12),
            makeItem("Dumbbell Press", sets: 3, repMin: 8, repMax: 12),
            makeItem("Cable Row", sets: 3, repMin: 10, repMax: 12),
            makeItem("Lateral Raise", sets: 3, repMin: 12, repMax: 15),
            makeItem("Calf Raise", sets: 3, repMin: 12, repMax: 20)
        ])
        return Routine(name: "Full Body", gym: gym, days: [dayA, dayB, dayC])
    }

    static func makeBroSplit(gym: Gym? = nil) -> Routine {
        let chest = RoutineDay(label: "Chest", items: [
            makeItem("Bench Press", sets: 4, repMin: 6, repMax: 10, rpe: "RPE 8"),
            makeItem("Incline Dumbbell Press", sets: 3, repMin: 8, repMax: 12),
            makeItem("Cable Fly", sets: 3, repMin: 10, repMax: 15),
            makeItem("Dips", sets: 3, repMin: 8, repMax: 12)
        ])
        let back = RoutineDay(label: "Back", items: [
            makeItem("Row (Barbell)", sets: 4, repMin: 6, repMax: 10, rpe: "RPE 8"),
            makeItem("Lat Pulldown", sets: 3, repMin: 8, repMax: 12),
            makeItem("Cable Row", sets: 3, repMin: 10, repMax: 12),
            makeItem("Face Pull", sets: 3, repMin: 12, repMax: 15)
        ])
        let shoulders = RoutineDay(label: "Shoulders", items: [
            makeItem("Overhead Press", sets: 4, repMin: 6, repMax: 10, rpe: "RPE 8"),
            makeItem("Lateral Raise", sets: 4, repMin: 12, repMax: 15),
            makeItem("Rear Delt Fly", sets: 3, repMin: 12, repMax: 15),
            makeItem("Shrugs", sets: 3, repMin: 10, repMax: 15)
        ])
        let arms = RoutineDay(label: "Arms", items: [
            makeItem("Dumbbell Curl", sets: 3, repMin: 8, repMax: 12),
            makeItem("Hammer Curl", sets: 3, repMin: 10, repMax: 15),
            makeItem("Triceps Pushdown", sets: 3, repMin: 10, repMax: 15),
            makeItem("Skull Crushers", sets: 3, repMin: 8, repMax: 12)
        ])
        let legs = RoutineDay(label: "Legs", items: [
            makeItem("Back Squat", sets: 4, repMin: 5, repMax: 8, rpe: "RPE 8"),
            makeItem("Romanian Deadlift", sets: 3, repMin: 6, repMax: 10),
            makeItem("Leg Press", sets: 3, repMin: 10, repMax: 15),
            makeItem("Leg Curl", sets: 3, repMin: 10, repMax: 15),
            makeItem("Calf Raise", sets: 4, repMin: 12, repMax: 20)
        ])
        return Routine(name: "Bro Split", gym: gym, days: [chest, back, shoulders, arms, legs])
    }

    // MARK: - Legacy API (for backwards compatibility)

    static func makeUL(days: Int) -> Routine {
        let routine = makeUL()
        // Replicate days if needed for legacy behavior
        if days > 2 {
            var allDays: [RoutineDay] = []
            for i in 0..<days {
                let sourceDay = routine.days[i % 2]
                allDays.append(RoutineDay(label: sourceDay.label, items: sourceDay.items))
            }
            return Routine(name: "UL \(days)x", days: allDays)
        }
        return routine
    }

    // MARK: - Progression Logic

    static func nextLoad(current: Double, achievedReps: Int, scheme: SetScheme) -> Double {
        if achievedReps >= scheme.repMax { return (current * 1.025).rounded(.toNearestOrAwayFromZero) }
        if achievedReps < scheme.repMin { return (current * 0.975).rounded(.toNearestOrAwayFromZero) }
        return current
    }

    // MARK: - Helper

    private static func makeItem(_ name: String, sets: Int, repMin: Int, repMax: Int, rpe: String? = nil) -> RoutineItem {
        RoutineItem(
            exerciseName: name,
            setScheme: .init(sets: sets, repMin: repMin, repMax: repMax, rpeNote: rpe)
        )
    }
}
