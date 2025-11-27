//
//  AIPromptSheet.swift
//  GYMRar
//
//  Created by Alejandro Gonzalez on 27/11/25.
//

import SwiftUI

#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26, *)
struct AIPromptSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var aiService: FoundationAIService

    let currentRoutine: CurrentRoutineContext
    let exercises: [String]
    let onApply: (RoutineDraft) -> Void

    @State private var userPrompt: String = ""
    @State private var generatedDraft: RoutineDraft?
    @State private var errorMessage: String?
    @FocusState private var isPromptFocused: Bool

    private let examplePrompts = [
        "Create a 3-day full body routine",
        "I only have dumbbells",
        "Add more back exercises",
        "Focus on strength (lower reps)",
        "Remove machine exercises",
        "Make it a PPL split"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    promptSection
                    examplesSection

                    if aiService.isGenerating || generatedDraft != nil {
                        previewSection
                    }

                    if let error = errorMessage {
                        errorSection(error)
                    }
                }
                .padding()
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        if let draft = generatedDraft {
                            onApply(draft)
                            dismiss()
                        }
                    }
                    .disabled(generatedDraft == nil || aiService.isGenerating)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Prompt Input Section

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What would you like?")
                .font(.headline)

            if !currentRoutine.isEmpty {
                Text("Current routine: \(currentRoutine.name) (\(currentRoutine.days.count) days)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            TextField("Describe your ideal routine or changes...", text: $userPrompt, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                .lineLimit(3...6)
                .focused($isPromptFocused)

            Button {
                Task { await generate() }
            } label: {
                HStack {
                    if aiService.isGenerating {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Generating...")
                    } else {
                        Image(systemName: "sparkles")
                        Text("Generate")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .disabled(userPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiService.isGenerating)
        }
    }

    // MARK: - Example Prompts

    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Examples")
                .font(.caption)
                .foregroundStyle(.secondary)

            FlowLayout(spacing: 8) {
                ForEach(examplePrompts, id: \.self) { example in
                    Button {
                        userPrompt = example
                        isPromptFocused = false
                    } label: {
                        Text(example)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)
                    .tint(.secondary)
                }
            }
        }
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Preview")
                    .font(.headline)
                Spacer()
                if aiService.isGenerating {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }

            if let draft = aiService.liveDraft ?? generatedDraft {
                AIPreviewOverlay(draft: draft)
            }
        }
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Error Section

    private func errorSection(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Actions

    private func generate() async {
        errorMessage = nil
        isPromptFocused = false

        do {
            let draft = try await aiService.generateRoutine(
                userPrompt: userPrompt,
                currentRoutine: currentRoutine,
                availableExercises: exercises,
                routineNameHint: currentRoutine.name.isEmpty ? nil : currentRoutine.name
            )
            generatedDraft = draft
        } catch {
            errorMessage = "Could not generate routine. Please try again."
            print("AI generation error: \(error)")
        }
    }
}

// MARK: - Flow Layout for Example Chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth, currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}
