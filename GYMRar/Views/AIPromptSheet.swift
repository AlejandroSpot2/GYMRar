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
    @Environment(\.colorScheme) private var colorScheme
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
            .neoBackground()
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
        NeoSection("What would you like?", color: NeoColors.info) {
            VStack(alignment: .leading, spacing: 12) {
                if !currentRoutine.isEmpty {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("Current: \(currentRoutine.name) (\(currentRoutine.days.count) days)")
                    }
                    .font(NeoFont.labelSmall)
                    .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.6))
                }

                NeoTextEditor("Describe your ideal routine or changes...", text: $userPrompt, minHeight: 80)
                    .focused($isPromptFocused)

                NeoButton(
                    aiService.isGenerating ? "Generating..." : "Generate",
                    icon: aiService.isGenerating ? nil : "sparkles",
                    size: .large,
                    color: NeoColors.info,
                    fullWidth: true
                ) {
                    Task { await generate() }
                }
                .disabled(userPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiService.isGenerating)
                .overlay {
                    if aiService.isGenerating {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(NeoColors.text(for: .light))
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: - Example Prompts

    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("EXAMPLES")
                .font(NeoFont.labelSmall)
                .foregroundStyle(NeoColors.text(for: colorScheme).opacity(0.6))

            FlowLayout(spacing: 8) {
                ForEach(examplePrompts, id: \.self) { example in
                    Button {
                        userPrompt = example
                        isPromptFocused = false
                    } label: {
                        Text(example)
                            .font(NeoFont.labelSmall)
                            .foregroundStyle(NeoColors.text(for: colorScheme))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(NeoColors.surface(for: colorScheme))
                            .neoBorder(width: 2)
                    }
                }
            }
        }
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        NeoSection("Preview", color: NeoColors.success) {
            VStack(alignment: .leading, spacing: 12) {
                if aiService.isGenerating {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Generating your routine...")
                            .font(NeoFont.bodyMedium)
                    }
                    .foregroundStyle(NeoColors.text(for: colorScheme))
                    .frame(maxWidth: .infinity)
                    .padding(16)
                }

                if let draft = aiService.liveDraft ?? generatedDraft {
                    AIPreviewOverlay(draft: draft)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Error Section

    private func errorSection(_ message: String) -> some View {
        NeoCard(color: NeoColors.warning.opacity(0.3)) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(NeoColors.warning)
                Text(message)
                    .font(NeoFont.bodyMedium)
                    .foregroundStyle(NeoColors.text(for: colorScheme))
            }
        }
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
