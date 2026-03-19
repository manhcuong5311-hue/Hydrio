import Foundation

// MARK: - Pet Type

enum PetType: String, CaseIterable, Codable {
    case plant  = "plant"
    case dragon = "dragon"
    case cloud  = "cloud"

    var displayName: String {
        switch self {
        case .plant:  return "Plant"
        case .dragon: return "Dragon"
        case .cloud:  return "Cloud"
        }
    }

    var icon: String {
        switch self {
        case .plant:  return "leaf.fill"
        case .dragon: return "flame.fill"
        case .cloud:  return "cloud.fill"
        }
    }

    var defaultName: String {
        switch self {
        case .plant:  return "Sprout"
        case .dragon: return "Ember"
        case .cloud:  return "Nimbus"
        }
    }

    // MARK: Per-type stage display

    func stageName(_ stage: PetGrowthStage) -> String {
        switch self {
        case .plant:
            switch stage {
            case .seed:   return "Seed"
            case .sprout: return "Sprout"
            case .plant:  return "Young Plant"
            case .tree:   return "Tree"
            case .bloom:  return "Blooming"
            }
        case .dragon:
            switch stage {
            case .seed:   return "Egg"
            case .sprout: return "Hatchling"
            case .plant:  return "Baby Dragon"
            case .tree:   return "Dragon"
            case .bloom:  return "Ancient"
            }
        case .cloud:
            switch stage {
            case .seed:   return "Mist"
            case .sprout: return "Cloud"
            case .plant:  return "Rain Cloud"
            case .tree:   return "Storm"
            case .bloom:  return "Rainbow"
            }
        }
    }

    func stageEmoji(_ stage: PetGrowthStage) -> String {
        switch self {
        case .plant:
            switch stage {
            case .seed:   return "🌱"
            case .sprout: return "🌿"
            case .plant:  return "🪴"
            case .tree:   return "🌳"
            case .bloom:  return "🌺"
            }
        case .dragon:
            switch stage {
            case .seed:   return "🥚"
            case .sprout: return "🐣"
            case .plant:  return "🐲"
            case .tree:   return "🐉"
            case .bloom:  return "✨"
            }
        case .cloud:
            switch stage {
            case .seed:   return "🌫️"
            case .sprout: return "☁️"
            case .plant:  return "🌧️"
            case .tree:   return "⛈️"
            case .bloom:  return "🌈"
            }
        }
    }

    func stageDescription(_ stage: PetGrowthStage) -> String {
        switch self {
        case .plant:
            switch stage {
            case .seed:   return "Your journey begins..."
            case .sprout: return "Growing strong!"
            case .plant:  return "Looking healthy!"
            case .tree:   return "You're thriving!"
            case .bloom:  return "In full bloom!"
            }
        case .dragon:
            switch stage {
            case .seed:   return "Something stirs inside..."
            case .sprout: return "It's hatching!"
            case .plant:  return "Breathing tiny flames!"
            case .tree:   return "A mighty dragon rises!"
            case .bloom:  return "Legendary and ancient!"
            }
        case .cloud:
            switch stage {
            case .seed:   return "A wisp of moisture..."
            case .sprout: return "Fluffy and light!"
            case .plant:  return "Bringing gentle rain!"
            case .tree:   return "Charged with power!"
            case .bloom:  return "A promise after the storm!"
            }
        }
    }
}

// MARK: - Growth Stage

enum PetGrowthStage: Int, CaseIterable, Codable {
    case seed   = 0
    case sprout = 1
    case plant  = 2
    case tree   = 3
    case bloom  = 4

    var requiredXP: Int {
        switch self {
        case .seed:   return 0
        case .sprout: return 100
        case .plant:  return 300
        case .tree:   return 700
        case .bloom:  return 1500
        }
    }

    var next: PetGrowthStage? {
        PetGrowthStage(rawValue: rawValue + 1)
    }
}

// MARK: - Pet

struct Pet: Codable {
    var type: PetType                       = .plant
    var name: String                        = "Sprout"
    var xp: Int                             = 0
    var happiness: Double                   = 0.5
    var growthStage: PetGrowthStage         = .seed
    var lastHappinessResetDate: Date        = Date()

    // MARK: - Delegated display to PetType

    var stageName: String        { type.stageName(growthStage) }
    var stageEmoji: String       { type.stageEmoji(growthStage) }
    var stageDescription: String { type.stageDescription(growthStage) }

    // MARK: - Progress

    var stageProgress: Double {
        guard let next = growthStage.next else { return 1.0 }
        let current = growthStage.requiredXP
        let needed  = next.requiredXP - current
        let gained  = xp - current
        return needed > 0 ? min(Double(gained) / Double(needed), 1.0) : 1.0
    }

    // MARK: - Happiness display

    var happinessDescription: String {
        switch happiness {
        case 0..<0.3:   return "Thirsty"
        case 0.3..<0.6: return "Content"
        case 0.6..<0.8: return "Happy"
        default:        return "Thriving"
        }
    }

    var happinessEmoji: String {
        switch happiness {
        case 0..<0.3:   return "😢"
        case 0.3..<0.6: return "😐"
        case 0.6..<0.8: return "😊"
        default:        return "🥰"
        }
    }

    // MARK: - XP (fixed: while loop handles skipping multiple stages)

    mutating func addXP(_ amount: Int) {
        xp += amount
        while let next = growthStage.next, xp >= next.requiredXP {
            growthStage = next
        }
    }

    // MARK: - Daily happiness

    mutating func updateHappiness(todayProgress: Double) {
        let calendar = Calendar.current
        let isNewDay = !calendar.isDateInToday(lastHappinessResetDate)

        if isNewDay {
            // New day: reset to baseline — reward if they hit goal yesterday
            happiness = 0.3
            lastHappinessResetDate = Date()
        } else {
            if todayProgress < 0.5 {
                happiness = max(0.1, happiness - 0.01)
            }
        }
    }
}
