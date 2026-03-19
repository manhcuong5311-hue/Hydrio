import Foundation

enum ReminderInterval: String, CaseIterable, Codable {
    case thirtyMinutes = "30_min"
    case oneHour       = "1_hour"
    case twoHours      = "2_hours"
    case threeHours    = "3_hours"
    case never         = "never"

    var displayName: String {
        switch self {
        case .thirtyMinutes: return "Every 30 min"
        case .oneHour:       return "Every hour"
        case .twoHours:      return "Every 2 hours"
        case .threeHours:    return "Every 3 hours"
        case .never:         return "Never"
        }
    }

    var minutes: Int {
        switch self {
        case .thirtyMinutes: return 30
        case .oneHour:       return 60
        case .twoHours:      return 120
        case .threeHours:    return 180
        case .never:         return 0
        }
    }
}

struct HydrationGoal: Codable {
    var dailyGoalML: Double       = 2300
    var reminderInterval: ReminderInterval = .oneHour

    var displayGoal: String {
        dailyGoalML >= 1000
            ? String(format: "%.1fL", dailyGoalML / 1000)
            : "\(Int(dailyGoalML))ml"
    }
}
