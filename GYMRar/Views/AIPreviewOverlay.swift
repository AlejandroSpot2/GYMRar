//
//  AIPreviewOverlay.swift
//  GYMRar
//
//  Created by Alejandro Gonzalez on 10/11/25.
//

import SwiftUI

@available(iOS 26, *)
struct AIPreviewOverlay: View {
    @Environment(\.colorScheme) private var colorScheme
    let draft: RoutineDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !draft.name.isEmpty {
                Text(draft.name)
                    .font(NeoFont.headlineMedium)
                    .foregroundStyle(NeoColors.text(for: colorScheme))
            }

            ForEach(Array(draft.days.enumerated()), id: \.offset) { idx, day in
                NeoCard(color: NeoColors.surface(for: colorScheme), padding: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(day.label.isEmpty ? "Day \(idx + 1)" : day.label)
                            .font(NeoFont.labelMedium)
                            .foregroundStyle(NeoColors.info)

                        ForEach(Array(day.items.enumerated()), id: \.offset) { _, item in
                            HStack {
                                Text(item.exerciseName.isEmpty ? "..." : item.exerciseName)
                                    .font(NeoFont.bodyMedium)
                                Spacer()
                                let hasScheme = item.sets > 0 && item.repMin > 0 && item.repMax >= item.repMin
                                Text(hasScheme ? "\(item.sets)x\(item.repMin)-\(item.repMax)" : "...")
                                    .font(NeoFont.numericSmall)
                                    .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.6))
                            }
                        }
                    }
                    .foregroundStyle(NeoColors.text(for: colorScheme))
                }
            }
        }
    }
}
