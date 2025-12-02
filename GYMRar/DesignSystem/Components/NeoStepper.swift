//
//  NeoStepper.swift
//  GYMRar
//
//  Neobrutalism styled stepper component
//

import SwiftUI

struct NeoStepper: View {
    @Environment(\.colorScheme) private var colorScheme

    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int

    init(
        _ label: String,
        value: Binding<Int>,
        in range: ClosedRange<Int>,
        step: Int = 1
    ) {
        self.label = label
        self._value = value
        self.range = range
        self.step = step
    }

    var body: some View {
        HStack {
            Text(label)
                .font(NeoFont.bodyLarge)
                .foregroundStyle(NeoColors.text(for: colorScheme))

            Spacer()

            HStack(spacing: 0) {
                // Minus button
                Button {
                    if value - step >= range.lowerBound {
                        value -= step
                    }
                } label: {
                    Text("-")
                        .font(NeoFont.headlineLarge)
                        .foregroundStyle(NeoColors.text(for: .light))
                        .frame(width: 44, height: 44)
                        .background(NeoColors.danger)
                }
                .disabled(value <= range.lowerBound)
                .opacity(value <= range.lowerBound ? 0.5 : 1)

                // Value display
                Text("\(value)")
                    .font(NeoFont.numeric)
                    .foregroundStyle(NeoColors.text(for: colorScheme))
                    .frame(width: 56, height: 44)
                    .background(NeoColors.surface(for: colorScheme))

                // Plus button
                Button {
                    if value + step <= range.upperBound {
                        value += step
                    }
                } label: {
                    Text("+")
                        .font(NeoFont.headlineLarge)
                        .foregroundStyle(NeoColors.text(for: .light))
                        .frame(width: 44, height: 44)
                        .background(NeoColors.success)
                }
                .disabled(value >= range.upperBound)
                .opacity(value >= range.upperBound ? 0.5 : 1)
            }
            .overlay(
                Rectangle()
                    .stroke(NeoColors.border(for: colorScheme), lineWidth: 2)
            )
            .sensoryFeedback(.selection, trigger: value)
        }
    }
}

// MARK: - Compact Stepper (No label)

struct NeoCompactStepper: View {
    @Environment(\.colorScheme) private var colorScheme

    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int

    init(
        value: Binding<Int>,
        in range: ClosedRange<Int>,
        step: Int = 1
    ) {
        self._value = value
        self.range = range
        self.step = step
    }

    var body: some View {
        HStack(spacing: 0) {
            Button {
                if value - step >= range.lowerBound {
                    value -= step
                }
            } label: {
                Text("-")
                    .font(NeoFont.headlineSmall)
                    .foregroundStyle(NeoColors.text(for: .light))
                    .frame(width: 32, height: 32)
                    .background(NeoColors.danger)
            }
            .disabled(value <= range.lowerBound)
            .opacity(value <= range.lowerBound ? 0.5 : 1)

            Text("\(value)")
                .font(NeoFont.numericSmall)
                .foregroundStyle(NeoColors.text(for: colorScheme))
                .frame(width: 44, height: 32)
                .background(NeoColors.surface(for: colorScheme))

            Button {
                if value + step <= range.upperBound {
                    value += step
                }
            } label: {
                Text("+")
                    .font(NeoFont.headlineSmall)
                    .foregroundStyle(NeoColors.text(for: .light))
                    .frame(width: 32, height: 32)
                    .background(NeoColors.success)
            }
            .disabled(value >= range.upperBound)
            .opacity(value >= range.upperBound ? 0.5 : 1)
        }
        .overlay(
            Rectangle()
                .stroke(NeoColors.border(for: colorScheme), lineWidth: 2)
        )
        .sensoryFeedback(.selection, trigger: value)
    }
}

// MARK: - Decimal Stepper

struct NeoDecimalStepper: View {
    @Environment(\.colorScheme) private var colorScheme

    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: String

    init(
        _ label: String,
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double = 0.5,
        format: String = "%.1f"
    ) {
        self.label = label
        self._value = value
        self.range = range
        self.step = step
        self.format = format
    }

    var body: some View {
        HStack {
            Text(label)
                .font(NeoFont.bodyLarge)
                .foregroundStyle(NeoColors.text(for: colorScheme))

            Spacer()

            HStack(spacing: 0) {
                Button {
                    if value - step >= range.lowerBound {
                        value -= step
                    }
                } label: {
                    Text("-")
                        .font(NeoFont.headlineLarge)
                        .foregroundStyle(NeoColors.text(for: .light))
                        .frame(width: 44, height: 44)
                        .background(NeoColors.danger)
                }
                .disabled(value <= range.lowerBound)
                .opacity(value <= range.lowerBound ? 0.5 : 1)

                Text(String(format: format, value))
                    .font(NeoFont.numeric)
                    .foregroundStyle(NeoColors.text(for: colorScheme))
                    .frame(width: 72, height: 44)
                    .background(NeoColors.surface(for: colorScheme))

                Button {
                    if value + step <= range.upperBound {
                        value += step
                    }
                } label: {
                    Text("+")
                        .font(NeoFont.headlineLarge)
                        .foregroundStyle(NeoColors.text(for: .light))
                        .frame(width: 44, height: 44)
                        .background(NeoColors.success)
                }
                .disabled(value >= range.upperBound)
                .opacity(value >= range.upperBound ? 0.5 : 1)
            }
            .overlay(
                Rectangle()
                    .stroke(NeoColors.border(for: colorScheme), lineWidth: 2)
            )
            .sensoryFeedback(.selection, trigger: value)
        }
    }
}

// MARK: - Preview

#Preview("Neo Stepper - Light") {
    NeoStepperPreview()
        .preferredColorScheme(.light)
}

#Preview("Neo Stepper - Dark") {
    NeoStepperPreview()
        .preferredColorScheme(.dark)
}

private struct NeoStepperPreview: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var sets = 3
    @State private var reps = 10
    @State private var weight = 50.0

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("STEPPERS")
                    .font(NeoFont.headlineLarge)
                    .foregroundStyle(NeoColors.text(for: colorScheme))

                VStack(alignment: .leading, spacing: 16) {
                    Text("WITH LABEL")
                        .font(NeoFont.labelMedium)
                        .foregroundStyle(NeoColors.text(for: colorScheme))

                    NeoStepper("Sets", value: $sets, in: 1...10)
                    NeoStepper("Reps", value: $reps, in: 1...30)
                }

                Divider()

                VStack(alignment: .leading, spacing: 16) {
                    Text("COMPACT")
                        .font(NeoFont.labelMedium)
                        .foregroundStyle(NeoColors.text(for: colorScheme))

                    HStack {
                        Text("Quantity:")
                            .font(NeoFont.bodyLarge)
                            .foregroundStyle(NeoColors.text(for: colorScheme))
                        Spacer()
                        NeoCompactStepper(value: $sets, in: 1...10)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 16) {
                    Text("DECIMAL")
                        .font(NeoFont.labelMedium)
                        .foregroundStyle(NeoColors.text(for: colorScheme))

                    NeoDecimalStepper("Weight (kg)", value: $weight, in: 0...500, step: 2.5)
                }
            }
            .padding()
        }
        .neoBackground()
    }
}
