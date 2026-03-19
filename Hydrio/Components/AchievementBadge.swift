import SwiftUI

struct AchievementBadge: View {
    let achievement: Achievement
    var size: CGFloat = 72

    @State private var shimmer = false

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                // Outer glow
                if achievement.isUnlocked {
                    Circle()
                        .fill(achievement.category.color.opacity(0.2))
                        .frame(width: size + 16, height: size + 16)
                        .blur(radius: 8)
                }

                // Badge background
                Circle()
                    .fill(achievement.isUnlocked
                        ? LinearGradient(
                            colors: [achievement.category.color, achievement.category.color.opacity(0.6)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          )
                        : LinearGradient(
                            colors: [Color.white.opacity(0.06), Color.white.opacity(0.03)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          )
                    )
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                achievement.isUnlocked
                                    ? achievement.category.color.opacity(0.4)
                                    : Color.white.opacity(0.1),
                                lineWidth: 1.5
                            )
                    )

                // Shimmer for unlocked
                if achievement.isUnlocked {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(shimmer ? 0.3 : 0), Color.clear],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size, height: size)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                                shimmer = true
                            }
                        }
                }

                // Icon
                Image(systemName: achievement.icon)
                    .font(.system(size: size * 0.35, weight: .semibold))
                    .foregroundStyle(achievement.isUnlocked ? .white : Color.white.opacity(0.25))
            }

            VStack(spacing: 2) {
                Text(achievement.title)
                    .font(.captionLarge)
                    .fontWeight(.semibold)
                    .foregroundStyle(achievement.isUnlocked ? .textPrimary : .textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if !achievement.isUnlocked {
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.1))
                            RoundedRectangle(cornerRadius: 2)
                                .fill(achievement.category.color.opacity(0.6))
                                .frame(width: geo.size.width * achievement.progress)
                        }
                    }
                    .frame(height: 3)
                    .padding(.horizontal, 4)

                    Text("\(achievement.current)/\(achievement.target)")
                        .font(.captionSmall)
                        .foregroundStyle(.textTertiary)
                }
            }
            .frame(width: size + 8)
        }
    }
}

struct AchievementToast: View {
    let achievement: Achievement
    @Binding var isShowing: Bool

    var body: some View {
        if isShowing {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle().fill(achievement.category.color.opacity(0.2)).frame(width: 48, height: 48)
                    Image(systemName: achievement.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(achievement.category.color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Achievement Unlocked!")
                        .font(.captionLarge).foregroundStyle(.goldPrimary).fontWeight(.bold)
                    Text(achievement.title)
                        .font(.titleSmall).foregroundStyle(.textPrimary)
                    Text(achievement.description)
                        .font(.captionSmall).foregroundStyle(.textSecondary)
                }
                Spacer()
                Button { withAnimation { isShowing = false } } label: {
                    Image(systemName: "xmark").font(.captionLarge).foregroundStyle(.textSecondary)
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .fill(Color(hex: "1A1A1A"))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                            .strokeBorder(Color.goldPrimary.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 20)
            )
            .padding(.horizontal, Spacing.md)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
