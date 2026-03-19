import SwiftUI

enum AchievementID: String, CaseIterable, Codable {
    case firstDrink     = "first_drink"
    case streak3        = "streak_3"
    case streak7        = "streak_7"
    case streak14       = "streak_14"
    case streak30       = "streak_30"
    case perfectWeek    = "perfect_week"
    case hydrationHero  = "hydration_hero"
    case earlyBird      = "early_bird"
    case nightOwl       = "night_owl"
    case goalCrusher    = "goal_crusher"
}

enum AchievementCategory: String, Codable {
    case beginner = "beginner"
    case streak   = "streak"
    case goal     = "goal"
    case habit    = "habit"

    var displayName: String {
        switch self {
        case .beginner: return "Getting Started"
        case .streak:   return "Streaks"
        case .goal:     return "Goals"
        case .habit:    return "Habits"
        }
    }

    var color: Color {
        switch self {
        case .beginner: return .hydrationBlue
        case .streak:   return Color(hex: "FF6B35")
        case .goal:     return .goldPrimary
        case .habit:    return Color(hex: "4CAF50")
        }
    }
}

struct Achievement: Identifiable, Codable, Equatable {
    let id: AchievementID
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let target: Int
    var isUnlocked: Bool      = false
    var unlockedDate: Date?   = nil
    var current: Int          = 0

    var progress: Double { target > 0 ? min(Double(current) / Double(target), 1.0) : 0 }

    static let defaults: [Achievement] = [
        Achievement(id: .firstDrink,    title: "First Sip",       description: "Log your very first drink",             icon: "drop.fill",              category: .beginner, target: 1),
        Achievement(id: .streak3,       title: "3 Day Streak",    description: "Stay hydrated 3 days in a row",         icon: "flame.fill",             category: .streak,   target: 3),
        Achievement(id: .streak7,       title: "Week Warrior",    description: "7-day hydration streak",               icon: "star.fill",              category: .streak,   target: 7),
        Achievement(id: .streak14,      title: "Fortnight Flow",  description: "14-day hydration streak",              icon: "bolt.fill",              category: .streak,   target: 14),
        Achievement(id: .streak30,      title: "Monthly Master",  description: "30-day hydration streak",              icon: "crown.fill",             category: .streak,   target: 30),
        Achievement(id: .perfectWeek,   title: "Perfect Week",    description: "Hit your goal every day for a week",   icon: "checkmark.seal.fill",    category: .goal,     target: 7),
        Achievement(id: .hydrationHero, title: "Hydration Hero",  description: "Log 100 drinks total",                 icon: "trophy.fill",            category: .goal,     target: 100),
        Achievement(id: .earlyBird,     title: "Early Bird",      description: "Log water before 8am",                 icon: "sunrise.fill",           category: .habit,    target: 1),
        Achievement(id: .nightOwl,      title: "Night Owl",       description: "Log water after 10pm",                 icon: "moon.stars.fill",        category: .habit,    target: 1),
        Achievement(id: .goalCrusher,   title: "Goal Crusher",    description: "Exceed your daily goal by 50%",        icon: "arrow.up.circle.fill",   category: .goal,     target: 1),
    ]
}
