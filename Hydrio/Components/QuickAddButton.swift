import SwiftUI

struct QuickAddButton: View {
    let amount: Int
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation { isPressed = false }
            }
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.hydrationBlue)
                Text("+\(amount)ml")
                    .font(.captionLarge)
                    .foregroundStyle(.textPrimary)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .fill(Color.hydrationBlue.opacity(isPressed ? 0.2 : 0.08))
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .strokeBorder(Color.hydrationBlue.opacity(isPressed ? 0.6 : 0.2), lineWidth: 1)
                }
            )
            .scaleEffect(isPressed ? 0.93 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

struct FloatingAddButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(LinearGradient.goldGradient)
                    .frame(width: 64, height: 64)
                    .shadow(color: Color.goldPrimary.opacity(0.5), radius: 16, x: 0, y: 8)
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color(hex: "0B0B0B"))
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
