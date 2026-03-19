import SwiftUI

struct GlassCard<Content: View>: View {
    let content: () -> Content
    var padding: CGFloat = Spacing.md
    var cornerRadius: CGFloat = Radius.lg

    init(padding: CGFloat = Spacing.md,
         cornerRadius: CGFloat = Radius.lg,
         @ViewBuilder content: @escaping () -> Content) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.15), Color.white.opacity(0.03)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
    }
}

struct GoldCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(Spacing.md)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color.goldPrimary.opacity(0.15), Color.goldSecondary.opacity(0.08)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                    RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.goldPrimary.opacity(0.6), Color.goldSecondary.opacity(0.2)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
    }
}
