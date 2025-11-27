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

    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .shoulders: return "Shoulders"
        case .biceps: return "Biceps"
        case .triceps: return "Triceps"
        case .quads: return "Quads"
        case .hamstrings: return "Hamstrings"
        case .glutes: return "Glutes"
        case .calves: return "Calves"
        case .core: return "Core"
        case .other: return "Other"
        }
    }

    /// Ordenado de arriba a abajo del cuerpo para UI
    static var sortOrder: [MuscleGroup] {
        [.chest, .back, .shoulders, .biceps, .triceps, .quads, .hamstrings, .glutes, .calves, .core, .other]
    }
}

enum SplitType: String, Codable, CaseIterable, Identifiable {
    case upperLower = "Upper/Lower"
    case pushPullLegs = "Push/Pull/Legs"
    case fullBody = "Full Body"
    case broSplit = "Bro Split"
    case custom = "Custom"

    var id: String { rawValue }

    var defaultDayLabels: [String] {
        switch self {
        case .upperLower: return ["Upper", "Lower"]
        case .pushPullLegs: return ["Push", "Pull", "Legs"]
        case .fullBody: return ["Day A", "Day B", "Day C"]
        case .broSplit: return ["Chest", "Back", "Shoulders", "Arms", "Legs"]
        case .custom: return []
        }
    }

    var description: String {
        switch self {
        case .upperLower: return "4-6 days/week, alternating upper and lower body"
        case .pushPullLegs: return "3-6 days/week, push/pull/legs rotation"
        case .fullBody: return "3-4 days/week, full body each session"
        case .broSplit: return "5 days/week, one muscle group per day"
        case .custom: return "Create your own structure"
        }
    }
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

struct SetScheme: Codable, Hashable, Sendable {
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
    var sets: Int
    var repMin: Int
    var repMax: Int
    var rpeNote: String?
    var progressionRaw: String
    var unitOverride: WeightUnit?

    var setScheme: SetScheme {
        get { SetScheme(sets: sets, repMin: repMin, repMax: repMax, rpeNote: rpeNote) }
        set {
            sets = newValue.sets
            repMin = newValue.repMin
            repMax = newValue.repMax
            rpeNote = newValue.rpeNote
        }
    }
    var progression: ProgressionRule {
        get { ProgressionRule(rawValue: progressionRaw) ?? .doubleProgression }
        set { progressionRaw = newValue.rawValue }
    }

    init(id: UUID = UUID(), exerciseName: String, setScheme: SetScheme,
         progression: ProgressionRule = .doubleProgression, unitOverride: WeightUnit? = nil) {
        self.id = id
        self.exerciseName = exerciseName
        self.sets = setScheme.sets
        self.repMin = setScheme.repMin
        self.repMax = setScheme.repMax
        self.rpeNote = setScheme.rpeNote
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
