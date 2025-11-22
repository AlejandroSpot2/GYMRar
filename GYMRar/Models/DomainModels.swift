import Foundation
import SwiftData

// MARK: - Unidades y grupos

enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case kg, lb
    var id: String { rawValue }
    var symbol: String { self == .kg ? "kg" : "lb" }
}

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest, back, shoulders, biceps, triceps, quads, hamstrings, glutes, calves, core, other
    var id: String { rawValue }
}

// MARK: - Modelos SwiftData

@Model
final class Gym {
    @Attribute(.unique) var id: UUID
    var name: String
    var defaultUnit: WeightUnit
    var locationNote: String?

    init(id: UUID = UUID(), name: String, defaultUnit: WeightUnit = .kg, locationNote: String? = nil) {
        self.id = id
        self.name = name
        self.defaultUnit = defaultUnit
        self.locationNote = locationNote
    }
}

@Model
final class Calibration {
    @Attribute(.unique) var id: UUID
    var gym: Gym?
    var baseExerciseName: String
    var alias: String
    /// real = a * marcado + b   (en unidad de la máquina)
    var a: Double
    var b: Double
    var machineUnit: WeightUnit

    init(id: UUID = UUID(), gym: Gym?, baseExerciseName: String, alias: String,
         a: Double, b: Double, machineUnit: WeightUnit) {
        self.id = id
        self.gym = gym
        self.baseExerciseName = baseExerciseName
        self.alias = alias
        self.a = a
        self.b = b
        self.machineUnit = machineUnit
    }
}

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var group: MuscleGroup
    var defaultUnit: WeightUnit
    var isBodyweight: Bool

    init(id: UUID = UUID(), name: String, group: MuscleGroup, defaultUnit: WeightUnit = .kg, isBodyweight: Bool = false) {
        self.id = id
        self.name = name
        self.group = group
        self.defaultUnit = defaultUnit
        self.isBodyweight = isBodyweight
    }
}

@Model
final class Routine {
    @Attribute(.unique) var id: UUID
    var name: String
    var gym: Gym?
    var days: [RoutineDay] = []

    init(id: UUID = UUID(), name: String, gym: Gym? = nil, days: [RoutineDay] = []) {
        self.id = id
        self.name = name
        self.gym = gym
        self.days = days
    }
}

@Model
final class RoutineDay {
    @Attribute(.unique) var id: UUID
    var label: String
    var items: [RoutineItem] = []

    init(id: UUID = UUID(), label: String, items: [RoutineItem] = []) {
        self.id = id
        self.label = label
        self.items = items
    }
}

struct SetScheme: Codable, Hashable {
    var sets: Int
    var repMin: Int
    var repMax: Int
    var rpeNote: String?
}

enum ProgressionRule: String, Codable, CaseIterable {
    case doubleProgression
    case linearSmallLoad
}

@Model
final class RoutineItem {
    @Attribute(.unique) var id: UUID
    var exerciseName: String
    var setSchemeData: Data
    var progressionRaw: String
    var unitOverride: WeightUnit?

    var setScheme: SetScheme {
        get { (try? JSONDecoder().decode(SetScheme.self, from: setSchemeData)) ?? SetScheme(sets: 3, repMin: 8, repMax: 12, rpeNote: nil) }
        set { setSchemeData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
    var progression: ProgressionRule {
        get { ProgressionRule(rawValue: progressionRaw) ?? .doubleProgression }
        set { progressionRaw = newValue.rawValue }
    }

    init(id: UUID = UUID(), exerciseName: String, setScheme: SetScheme,
         progression: ProgressionRule = .doubleProgression, unitOverride: WeightUnit? = nil) {
        self.id = id
        self.exerciseName = exerciseName
        self.setSchemeData = (try! JSONEncoder().encode(setScheme))
        self.progressionRaw = progression.rawValue
        self.unitOverride = unitOverride
    }
}

@Model
final class Workout {
    @Attribute(.unique) var id: UUID
    var date: Date
    var gym: Gym?
    var entries: [WorkoutSet] = []

    init(id: UUID = UUID(), date: Date = .now, gym: Gym? = nil, entries: [WorkoutSet] = []) {
        self.id = id
        self.date = date
        self.gym = gym
        self.entries = entries
    }
}

@Model
final class WorkoutSet {
    @Attribute(.unique) var id: UUID
    var exerciseName: String
    var order: Int
    var reps: Int
    var weightValue: Double
    var weightUnitRaw: String
    var rpe: Double?
    var note: String?
    var calibrationAlias: String?

    var weightUnit: WeightUnit {
        get { WeightUnit(rawValue: weightUnitRaw) ?? .kg }
        set { weightUnitRaw = newValue.rawValue }
    }

    init(id: UUID = UUID(), exerciseName: String, order: Int,
         reps: Int, weightValue: Double, weightUnit: WeightUnit,
         rpe: Double? = nil, note: String? = nil, calibrationAlias: String? = nil) {
        self.id = id
        self.exerciseName = exerciseName
        self.order = order
        self.reps = reps
        self.weightValue = weightValue
        self.weightUnitRaw = weightUnit.rawValue
        self.rpe = rpe
        self.note = note
        self.calibrationAlias = calibrationAlias
    }
}
