import SwiftUI

struct HydrationRing: View {
    let progress: Double          // 0.0 – 1.0
    let currentML: Double
    let goalML: Double
    var size: CGFloat = 220
    var lineWidth: CGFloat = 18

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.white.opacity(0.07), lineWidth: lineWidth)
                .frame(width: size, height: size)

            // Glow outer
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: [Color.hydrationBlue.opacity(0.2), Color.hydrationBlue.opacity(0)],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth + 12, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            // Main ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: animatedProgress >= 1.0
                            ? [Color.goldPrimary, Color.goldSecondary]
                            : [Color.hydrationBlue, Color(hex: "7DC4FF")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .shadow(
                    color: (animatedProgress >= 1.0 ? Color.goldPrimary : Color.hydrationBlue).opacity(0.5),
                    radius: 8, x: 0, y: 0
                )

            // Center content
            VStack(spacing: 4) {
                Text(formatML(currentML))
                    .font(.numberLarge)
                    .foregroundStyle(
                        animatedProgress >= 1.0
                            ? LinearGradient.goldGradient
                            : LinearGradient(colors: [.white], startPoint: .leading, endPoint: .trailing)
                    )
                Text("of \(formatML(goalML))")
                    .font(.captionLarge)
                    .foregroundStyle(.textSecondary)
                Text("\(Int(min(animatedProgress, 1.0) * 100))%")
                    .font(.titleSmall)
                    .foregroundStyle(animatedProgress >= 1.0 ? .goldPrimary : .hydrationBlue)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animatedProgress = min(progress, 1.0)
            }
        }
        .onChange(of: progress) { _, newVal in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                animatedProgress = min(newVal, 1.0)
            }
        }
    }

    private func formatML(_ ml: Double) -> String {
        ml >= 1000 ? String(format: "%.1fL", ml / 1000) : "\(Int(ml))ml"
    }
}

struct ProgressRing: View {
    let progress: Double
    var size: CGFloat      = 48
    var lineWidth: CGFloat = 5
    var color: Color       = .hydrationBlue

    @State private var animated: Double = 0

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.1), lineWidth: lineWidth).frame(width: size, height: size)
            Circle()
                .trim(from: 0, to: animated)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.4), radius: 4)
        }
        .onAppear { withAnimation(.easeOut(duration: 0.8)) { animated = min(progress, 1.0) } }
        .onChange(of: progress) { _, v in withAnimation(.spring()) { animated = min(v, 1.0) } }
    }
}
