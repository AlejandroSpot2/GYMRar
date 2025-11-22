//
//  AIPreviewOverlay.swift
//  GYMRar
//
//  Created by Alejandro Gonzalez on 10/11/25.
//


import SwiftUI

@available(iOS 26, *)
struct AIPreviewOverlay: View {
    let draft: RoutineDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview IA").font(.headline)
            if !draft.name.isEmpty { Text(draft.name).font(.subheadline) }

            ForEach(Array(draft.days.enumerated()), id: \.offset) { idx, day in
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.label.isEmpty ? "Día \(idx+1)" : day.label)
                        .font(.subheadline)
                    ForEach(Array(day.items.enumerated()), id: \.offset) { _, it in
                        HStack {
                            Text("• \(it.exerciseName.isEmpty ? "…" : it.exerciseName)")
                            Spacer()
                            let scheme = (it.sets > 0 && it.repMin > 0 && it.repMax >= it.repMin)
                            Text(scheme ? "\(it.sets)x\(it.repMin)-\(it.repMax)" : "…")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.vertical, 6)
    }
}
