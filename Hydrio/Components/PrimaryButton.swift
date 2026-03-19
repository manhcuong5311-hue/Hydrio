import SwiftUI

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isFullWidth: Bool = true

    init(_ title: String, icon: String? = nil, isFullWidth: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isFullWidth = isFullWidth
        self.action = action
    }

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: Spacing.sm) {
                if let icon { Image(systemName: icon).font(.bodyLarge) }
                Text(title).font(.titleSmall)
            }
            .foregroundStyle(Color(hex: "0B0B0B"))
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: 56)
            .padding(.horizontal, isFullWidth ? 0 : Spacing.lg)
            .background(LinearGradient.goldGradient)
            .clipShape(RoundedRectangle(cornerRadius: Radius.full, style: .continuous))
            .shadow(color: Color.goldPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title; self.icon = icon; self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if let icon { Image(systemName: icon).font(.bodyMedium) }
                Text(title).font(.titleSmall)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity).frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: Radius.full, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 1.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
