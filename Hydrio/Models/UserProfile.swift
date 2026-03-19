import Foundation

enum Gender: String, CaseIterable, Codable {
    case male   = "male"
    case female = "female"
    case other  = "other"

    var displayName: String {
        switch self {
        case .male:   return "Male"
        case .female: return "Female"
        case .other:  return "Other"
        }
    }
    var icon: String {
        switch self {
        case .male:   return "person.fill"
        case .female: return "person.fill"
        case .other:  return "person.2.fill"
        }
    }
}

enum ActivityLevel: String, CaseIterable, Codable {
    case sedentary        = "sedentary"
    case lightlyActive    = "lightly_active"
    case moderatelyActive = "moderately_active"
    case veryActive       = "very_active"
    case extraActive      = "extra_active"

    var displayName: String {
        switch self {
        case .sedentary:        return "Sedentary"
        case .lightlyActive:    return "Lightly Active"
        case .moderatelyActive: return "Moderately Active"
        case .veryActive:       return "Very Active"
        case .extraActive:      return "Extra Active"
        }
    }

    var description: String {
        switch self {
        case .sedentary:        return "Little or no exercise"
        case .lightlyActive:    return "Light exercise 1–3 days/week"
        case .moderatelyActive: return "Moderate exercise 3–5 days/week"
        case .veryActive:       return "Hard exercise 6–7 days/week"
        case .extraActive:      return "Very hard exercise & physical job"
        }
    }

    var icon: String {
        switch self {
        case .sedentary:        return "sofa.fill"
        case .lightlyActive:    return "figure.walk"
        case .moderatelyActive: return "figure.run"
        case .veryActive:       return "figure.strengthtraining.traditional"
        case .extraActive:      return "flame.fill"
        }
    }

    var multiplier: Double {
        switch self {
        case .sedentary:        return 1.00
        case .lightlyActive:    return 1.10
        case .moderatelyActive: return 1.20
        case .veryActive:       return 1.35
        case .extraActive:      return 1.50
        }
    }
}

struct UserProfile: Codable {
    var name: String        = ""
    var weight: Double      = 70
    var gender: Gender      = .male
    var activityLevel: ActivityLevel = .moderatelyActive
    var age: Int            = 25

    var recommendedDailyIntakeML: Double {
        let base     = weight * 35
        let adjusted = base * activityLevel.multiplier
        let genAdj   = gender == .male ? adjusted * 1.05 : adjusted
        return max(1500, min(genAdj, 5000))
    }
}
