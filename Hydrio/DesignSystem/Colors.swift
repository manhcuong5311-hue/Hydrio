import SwiftUI

extension Color {
    static let appBackground    = Color(hex: "0B0B0B")
    static let cardBackground   = Color(hex: "1A1A1A")
    static let surfaceCard      = Color(hex: "141414")
    static let goldPrimary      = Color(hex: "D4AF37")
    static let goldSecondary    = Color(hex: "FFD700")
    static let hydrationBlue    = Color(hex: "4DA6FF")
    static let hydrationBlueDim = Color(hex: "2D7ACC")
    static let textPrimary      = Color.white
    static let textSecondary    = Color(hex: "A0A0A0")
    static let textTertiary     = Color(hex: "505050")
    static let successGreen     = Color(hex: "4CAF50")
    static let warningOrange    = Color(hex: "FF9800")
    static let errorRed         = Color(hex: "FF5252")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

extension LinearGradient {
    static let goldGradient = LinearGradient(
        colors: [.goldPrimary, .goldSecondary],
        startPoint: .leading, endPoint: .trailing
    )
    static let goldGradientVertical = LinearGradient(
        colors: [.goldPrimary, .goldSecondary],
        startPoint: .top, endPoint: .bottom
    )
    static let blueGradient = LinearGradient(
        colors: [Color(hex: "4DA6FF"), Color(hex: "2D7ACC")],
        startPoint: .top, endPoint: .bottom
    )
    static let darkCardGradient = LinearGradient(
        colors: [Color(hex: "1E1E1E"), Color(hex: "111111")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let backgroundGradient = LinearGradient(
        colors: [Color(hex: "0B0B0B"), Color(hex: "0F0F14")],
        startPoint: .top, endPoint: .bottom
    )
}

// MARK: - ShapeStyle Extensions
extension ShapeStyle where Self == Color {
 
    static var textTertiary:     Color { Color(hex: "505050") }
    static var successGreen:     Color { Color(hex: "4CAF50") }
    static var warningOrange:    Color { Color(hex: "FF9800") }
    static var errorRed:         Color { Color(hex: "FF5252") }
    static var hydrationBlue:    Color { Color(hex: "4DA6FF") }
    static var hydrationBlueDim: Color { Color(hex: "2D7ACC") }
    static var goldPrimary:      Color { Color(hex: "D4AF37") }
    static var goldSecondary:    Color { Color(hex: "FFD700") }
    static var appBackground:    Color { Color(hex: "0B0B0B") }
    static var cardBackground:   Color { Color(hex: "1A1A1A") }
    static var surfaceCard:      Color { Color(hex: "141414") }
}
