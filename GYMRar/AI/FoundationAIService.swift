//
//  FoundationAIService.swift
//  GYMRar
//
//  Created by Alejandro Gonzalez on 10/11/25.
//

import Combine
import SwiftUI
import SwiftData

#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26, *)
@Generable
struct RoutineDraft: Codable {
    @Guide(description: "Nombre de la rutina, p. ej. 'UL 4x'") var name: String
    @Guide(description: "Días en orden; etiqueta + lista de ejercicios") var days: [Day]

    @Generable
    struct Day: Codable {
        @Guide(description: "Etiqueta del día, p. ej. 'Upper' o 'Lower'") var label: String
        @Guide(description: "Ejercicios del día") var items: [Item]
    }
    @Generable
    struct Item: Codable {
        @Guide(description: "Nombre exacto del ejercicio en tu catálogo") var exerciseName: String
        @Guide(description: "Número de sets") var sets: Int
        @Guide(description: "Reps mínimas") var repMin: Int
        @Guide(description: "Reps máximas") var repMax: Int
        @Guide(description: "Unidad: 'kg' o 'lb' (opcional)") var unit: String?
    }
}

@available(iOS 26, *)
@MainActor
final class FoundationAIService: ObservableObject {
    @Published var liveDraft: RoutineDraft?
    private var session: LanguageModelSession

    init(tools: [any Tool] = []) {
        let instructions = """
        Eres un coach de fuerza. Genera rutinas Upper/Lower para hipertrofia/fuerza.

        REGLAS:
        - Devuelve SIEMPRE el tipo Swift 'RoutineDraft' (guided generation).
        - Prioriza básicos compuestos; volumen sensato por sesión.
        - Usa SOLO los nombres de ejercicios provistos por la app (o vía tool).
        - Si corresponde, incluye unidad 'kg' o 'lb' por ejercicio.
        - Responde en español.
        """
        self.session = LanguageModelSession(tools: tools, instructions: instructions)
    }

    func generateRoutine(daysPerWeek: Int,
                         availableExercises: [String],
                         routineNameHint: String? = nil) async throws -> RoutineDraft {

        let prompt = """
        Contexto usuario:
        - Split: UL alternado.
        - Días por semana: \(daysPerWeek).
        - Ejercicios disponibles: \(availableExercises.joined(separator: ", ")).
        - Nombre sugerido: \(routineNameHint ?? "Ninguno").

        Devuelve RoutineDraft válida.
        """

        // Streaming de snapshots tipados
        let stream = session.streamResponse(to: prompt, generating: RoutineDraft.self)
        var lastDraft: RoutineDraft?
        for try await snapshot in stream {
            let name = snapshot.content.name ?? ""

            let daysSource = snapshot.content.days ?? []
            var daysMapped: [RoutineDraft.Day] = []
            daysMapped.reserveCapacity(daysSource.count)

            for d in daysSource {
                let itemsSource = d.items ?? []
                var itemsMapped: [RoutineDraft.Item] = []
                itemsMapped.reserveCapacity(itemsSource.count)

                for it in itemsSource {
                    let item = RoutineDraft.Item(
                        exerciseName: it.exerciseName ?? "",
                        sets: it.sets ?? 0,
                        repMin: it.repMin ?? 0,
                        repMax: it.repMax ?? 0,
                        unit: it.unit
                    )
                    itemsMapped.append(item)
                }

                let day = RoutineDraft.Day(
                    label: d.label ?? "",
                    items: itemsMapped
                )
                daysMapped.append(day)
            }

            let mapped = RoutineDraft(name: name, days: daysMapped)
            self.liveDraft = mapped
            lastDraft = mapped
        }
        return lastDraft ?? RoutineDraft(name: "UL \(daysPerWeek)x", days: [])
    }
}

// Mapper a modelos SwiftData
@available(iOS 26, *)
extension RoutineDraft {
    func toRoutine(for gym: Gym?) -> Routine {
        func parseUnit(_ unit: String?) -> WeightUnit? {
            guard let u = unit?.lowercased() else { return nil }
            switch u {
            case "lb": return .lb
            case "kg": return .kg
            default: return nil
            }
        }

        var dayModels: [RoutineDay] = []
        dayModels.reserveCapacity(days.count)

        for d in days {
            var items: [RoutineItem] = []
            items.reserveCapacity(d.items.count)

            for it in d.items {
                let scheme = SetScheme(sets: it.sets, repMin: it.repMin, repMax: it.repMax, rpeNote: nil)
                let unitOverride = parseUnit(it.unit)
                let item = RoutineItem(
                    exerciseName: it.exerciseName,
                    setScheme: scheme,
                    progression: .doubleProgression,
                    unitOverride: unitOverride
                )
                items.append(item)
            }

            let day = RoutineDay(label: d.label, items: items)
            dayModels.append(day)
        }

        let routineName = name.isEmpty ? "UL \(days.count)x" : name
        return Routine(name: routineName, gym: gym, days: dayModels)
    }
}

