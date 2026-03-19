import SwiftUI

enum DrinkType: String, CaseIterable, Codable, Identifiable {
    case water       = "water"
    case tea         = "tea"
    case coffee      = "coffee"
    case juice       = "juice"
    case sportsDrink = "sports_drink"
    case herbalTea   = "herbal_tea"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .water:       return "Water"
        case .tea:         return "Tea"
        case .coffee:      return "Coffee"
        case .juice:       return "Juice"
        case .sportsDrink: return "Sports"
        case .herbalTea:   return "Herbal Tea"
        }
    }

    var icon: String {
        switch self {
        case .water:       return "drop.fill"
        case .tea:         return "cup.and.saucer.fill"
        case .coffee:      return "cup.and.saucer"
        case .juice:       return "wineglass.fill"
        case .sportsDrink: return "bolt.fill"
        case .herbalTea:   return "leaf.fill"
        }
    }

    var color: Color {
        switch self {
        case .water:       return .hydrationBlue
        case .tea:         return Color(hex: "C8A96E")
        case .coffee:      return Color(hex: "8B5E3C")
        case .juice:       return Color(hex: "FF8C42")
        case .sportsDrink: return Color(hex: "00CED1")
        case .herbalTea:   return Color(hex: "4CAF50")
        }
    }

    var hydrationFactor: Double {
        switch self {
        case .water:       return 1.00
        case .tea:         return 0.90
        case .coffee:      return 0.80
        case .juice:       return 0.85
        case .sportsDrink: return 0.95
        case .herbalTea:   return 0.95
        }
    }
}
