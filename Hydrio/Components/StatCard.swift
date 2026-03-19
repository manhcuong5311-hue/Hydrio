import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    var iconColor: Color = .hydrationBlue
    var accentColor: Color = .hydrationBlue

    init(title: String, value: String, subtitle: String? = nil,
         icon: String, iconColor: Color = .hydrationBlue, accentColor: Color = .hydrationBlue) {
        self.title = title; self.value = value; self.subtitle = subtitle
        self.icon = icon; self.iconColor = iconColor; self.accentColor = accentColor
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(iconColor)
                    }
                    Spacer()
                }
                Text(value)
                    .font(.numberMedium)
                    .foregroundStyle(.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(title)
                    .font(.captionLarge)
                    .foregroundStyle(.textSecondary)
                if let subtitle {
                    Text(subtitle)
                        .font(.captionSmall)
                        .foregroundStyle(accentColor)
                }
            }
        }
    }
}

extension ShapeStyle where Self == Color {
    static var textPrimary: Color { .white }
    static var textSecondary: Color { Color(hex: "A0A0A0") }
}
