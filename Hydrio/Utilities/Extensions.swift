import SwiftUI

// MARK: - View Modifiers

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.15), .clear],
                        startPoint: UnitPoint(x: phase, y: 0.5),
                        endPoint: UnitPoint(x: phase + 0.5, y: 0.5)
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: -geo.size.width)
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}

extension View {
    func shimmer() -> some View { modifier(ShimmerModifier()) }

    func cardShadow() -> some View {
        self.shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 8)
    }

    func glowEffect(color: Color, radius: CGFloat = 12) -> some View {
        self.shadow(color: color.opacity(0.4), radius: radius, x: 0, y: 0)
    }
}

// MARK: - Date helpers

extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
    var isToday: Bool    { Calendar.current.isDateInToday(self) }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
}

// MARK: - Double helpers

extension Double {
    var formattedML: String {
        self >= 1000 ? String(format: "%.1fL", self / 1000) : "\(Int(self))ml"
    }

    var percentage: String { "\(Int(self * 100))%" }
}
