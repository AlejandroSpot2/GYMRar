import SwiftUI

struct PressFeedbackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light, intensity: 0.65), trigger: configuration.isPressed)
    }
}

#Preview("Press Feedback Style") {
    VStack(spacing: 16) {
        Button("Plain Button") {}
        Button(role: .destructive) { } label: { Text("Destructive") }
        Button { } label: { Label("With Icon", systemImage: "plus") }
            .buttonStyle(.bordered)
        Button("Prominent") {}
            .buttonStyle(.borderedProminent)
    }
    .buttonStyle(PressFeedbackButtonStyle())
    .padding()
}
