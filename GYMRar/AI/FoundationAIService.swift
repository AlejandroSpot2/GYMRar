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

// MARK: - Context for AI

struct CurrentRoutineContext {
    var name: String
    var days: [DayContext]

    struct DayContext {
        var label: String
        var exercises: [String]
    }

    var isEmpty: Bool {
        days.isEmpty || days.allSatisfy { $0.exercises.isEmpty }
    }

    func toPromptString() -> String {
        if isEmpty { return "No hay rutina creada todavía." }
        var result = "Rutina actual '\(name)':\n"
        for day in days {
            if day.exercises.isEmpty {
                result += "- \(day.label): (vacío)\n"
            } else {
                result += "- \(day.label): \(day.exercises.joined(separator: ", "))\n"
            }
        }
        return result
    }
}

// MARK: - AI Generated Routine Draft

@available(iOS 26, *)
@Generable
struct RoutineDraft: Codable {
    @Guide(description: "Nombre de la rutina, p. ej. 'UL 4x'") var name: String
    @Guide(description: "Días en orden; etiqueta + lista de ejercicios") var days: [Day]

    @Generable
    struct Day: Codable {
        @Guide(description: "Etiqueta del día, p. ej. 'Day 1', 'Chest & Shoulders', 'Push'") var label: String
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
    @Published var isGenerating = false
    private var session: LanguageModelSession

    init(tools: [any Tool] = []) {
        let instructions = """
        Eres un coach de fuerza experto. Ayudas a crear y modificar rutinas de entrenamiento.

        CAPACIDADES:
        - Crear rutinas desde cero basándote en las preferencias del usuario
        - Modificar rutinas existentes (agregar, quitar, reemplazar ejercicios)
        - Adaptar rutinas a equipamiento disponible (solo mancuernas, solo barra, etc.)
        - Ajustar volumen, frecuencia y enfoque muscular según solicitud

        REGLAS:
        - Devuelve SIEMPRE el tipo Swift 'RoutineDraft' (guided generation).
        - Usa SOLO los nombres de ejercicios provistos en la lista de ejercicios disponibles.
        - Si el usuario pide modificar, mantén la estructura de días existente cuando sea posible.
        - Si el usuario tiene restricciones de equipo, selecciona solo ejercicios apropiados.
        - Prioriza ejercicios compuestos básicos; volumen sensato por sesión.
        - IMPORTANTE: Por defecto crea UN SOLO día, a menos que el usuario pida explícitamente más días.
        - Usa etiquetas de día descriptivas basadas en el contenido (ej: 'Chest & Shoulders', 'Legs', 'Full Body') o genéricas ('Day 1', 'Day 2') si no hay enfoque específico.
        - NO uses 'Upper'/'Lower' a menos que el usuario pida específicamente un split Upper/Lower.
        - Responde en español.
        """
        self.session = LanguageModelSession(tools: tools, instructions: instructions)
    }

    // MARK: - New Prompt-Based Generation

    func generateRoutine(
        userPrompt: String,
        currentRoutine: CurrentRoutineContext,
        availableExercises: [String],
        routineNameHint: String? = nil
    ) async throws -> RoutineDraft {
        isGenerating = true
        liveDraft = nil

        defer { isGenerating = false }

        let contextSection: String
        if currentRoutine.isEmpty {
            contextSection = "Crear una nueva rutina desde cero."
        } else {
            contextSection = """
            Rutina actual a modificar:
            \(currentRoutine.toPromptString())
            """
        }

        let prompt = """
        Solicitud del usuario: \(userPrompt)

        \(contextSection)

        Ejercicios disponibles: \(availableExercises.joined(separator: ", "))
        \(routineNameHint.map { "Nombre sugerido: \($0)" } ?? "")

        IMPORTANTE: Crea exactamente el número de días que el usuario solicite. Si no especifica, crea UN SOLO día.
        Genera o modifica la rutina según la solicitud. Devuelve una RoutineDraft completa.
        """

        return try await streamRoutine(prompt: prompt, fallbackName: routineNameHint ?? "Mi Rutina")
    }

    // MARK: - Legacy Split-Based Generation (kept for compatibility)

    func generateRoutine(
        splitType: SplitType,
        daysPerWeek: Int,
        availableExercises: [String],
        routineNameHint: String? = nil
    ) async throws -> RoutineDraft {
        isGenerating = true
        liveDraft = nil

        defer { isGenerating = false }

        let splitDescription = splitDescriptionFor(splitType)
        let dayLabels = splitType.defaultDayLabels.joined(separator: ", ")

        let prompt = """
        Contexto usuario:
        - Tipo de split: \(splitType.rawValue)
        - Descripción: \(splitDescription)
        - Días recomendados: \(dayLabels)
        - Días por semana: \(daysPerWeek)
        - Ejercicios disponibles: \(availableExercises.joined(separator: ", "))
        - Nombre sugerido: \(routineNameHint ?? "Ninguno")

        Genera una RoutineDraft con la estructura de días apropiada para este split.
        """

        return try await streamRoutine(prompt: prompt, fallbackName: splitType.rawValue)
    }

    // MARK: - Private Helpers

    private func streamRoutine(prompt: String, fallbackName: String) async throws -> RoutineDraft {
        let stream = session.streamResponse(to: prompt, generating: RoutineDraft.self)
        var lastDraft: RoutineDraft?

        for try await snapshot in stream {
            let mapped = mapSnapshot(snapshot)
            self.liveDraft = mapped
            lastDraft = mapped
        }

        return lastDraft ?? RoutineDraft(name: fallbackName, days: [])
    }

    private func mapSnapshot(_ snapshot: LanguageModelSession.ResponseStream<RoutineDraft>.Element) -> RoutineDraft {
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

        return RoutineDraft(name: name, days: daysMapped)
    }

    private func splitDescriptionFor(_ split: SplitType) -> String {
        switch split {
        case .upperLower:
            return "Upper/Lower alternado. Upper: pecho, espalda, hombros, bíceps, tríceps. Lower: cuádriceps, isquios, glúteos, pantorrillas."
        case .pushPullLegs:
            return "Push/Pull/Legs. Push: pecho, hombros, tríceps. Pull: espalda, bíceps. Legs: cuádriceps, isquios, glúteos, pantorrillas."
        case .fullBody:
            return "Full Body. Cada día entrena todos los grupos musculares principales con ejercicios compuestos."
        case .broSplit:
            return "Bro Split clásico. Un día por grupo muscular: Chest, Back, Shoulders, Arms, Legs."
        case .custom:
            return "Custom. Estructura de días flexible según preferencia del usuario."
        }
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

