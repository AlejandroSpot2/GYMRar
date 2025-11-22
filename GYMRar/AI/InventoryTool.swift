//
//  InventoryTool.swift
//  GYMRar
//
//  Created by Alejandro Gonzalez on 10/11/25.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif
import SwiftData

@available(iOS 26, *)
struct GymInventoryResult: Codable {
    struct CalibrationInfo: Codable {
        var alias: String
        var a: Double
        var b: Double
        var unit: String
    }
    struct CalibrationGroup: Codable {
        var baseExercise: String
        var items: [CalibrationInfo]
    }
    var exercises: [String]
    var calibrations: [CalibrationGroup]
}

#if canImport(FoundationModels)
@available(iOS 26, *)
struct InventoryTool {
    struct Arguments: Codable {
        var gymName: String?
    }

    let name = "getGymInventory"
    let description = "Devuelve ejercicios y calibraciones para un gimnasio"

    private let container: ModelContainer
    init(container: ModelContainer) { self.container = container }

    func call(arguments: Arguments) async throws -> String {
        let ctx = ModelContext(container)

        // Buscar gym
        let gyms = try (ctx.fetch(FetchDescriptor<Gym>()))
        let gym: Gym? = {
            if let n = arguments.gymName?.trimmingCharacters(in: .whitespacesAndNewlines), !n.isEmpty {
                return gyms.first(where: { $0.name.lowercased() == n.lowercased() })
            } else {
                return gyms.first
            }
        }()

        // Ejercicios (catálogo completo; opcionalmente filtrable por equipo real)
        let exercises = try ctx.fetch(FetchDescriptor<Exercise>()).map { $0.name }

        // Calibraciones del gym elegido
        let cals = try ctx.fetch(FetchDescriptor<Calibration>()).filter { $0.gym?.id == gym?.id }
        var map: [String: [GymInventoryResult.CalibrationInfo]] = [:]
        for c in cals {
            let key = c.baseExerciseName
            let info = GymInventoryResult.CalibrationInfo(alias: c.alias, a: c.a, b: c.b, unit: c.machineUnit.rawValue)
            map[key, default: []].append(info)
        }

        let groups: [GymInventoryResult.CalibrationGroup] = map.map { key, value in
            GymInventoryResult.CalibrationGroup(baseExercise: key, items: value)
        }.sorted { $0.baseExercise.localizedCaseInsensitiveCompare($1.baseExercise) == .orderedAscending }

        let result = GymInventoryResult(exercises: exercises, calibrations: groups)
        let jsonData = try JSONEncoder().encode(result)
        return String(decoding: jsonData, as: UTF8.self)
    }
}
#endif
