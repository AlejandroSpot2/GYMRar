//
//  UnitHelpers.swift
//  GYMRar
//
//  Created by Alejandro Gonzalez on 10/11/25.
//

import Foundation

enum UnitConv {
    static func toKg(_ value: Double, unit: WeightUnit) -> Double {
        switch unit {
        case .kg: return value
        case .lb: return value * 0.45359237
        }
    }
    static func toLb(_ value: Double, unit: WeightUnit) -> Double {
        switch unit {
        case .kg: return value / 0.45359237
        case .lb: return value
        }
    }
    static func convert(_ value: Double, from: WeightUnit, to: WeightUnit) -> Double {
        if from == to { return value }
        return (to == .kg) ? toKg(value, unit: from) : toLb(value, unit: from)
    }
}

/// Aplica calibración: real = a * marcado + b (ambos en unidad de la máquina),
/// luego convierte al unit destino (por ejemplo, kg globales).
struct CalibrationMath {
    static func realWeight(marked: Double,
                           machineUnit: WeightUnit,
                           a: Double, b: Double,
                           outputUnit: WeightUnit) -> Double {
        let realInMachineUnit = a * marked + b
        return UnitConv.convert(realInMachineUnit, from: machineUnit, to: outputUnit)
    }
}
