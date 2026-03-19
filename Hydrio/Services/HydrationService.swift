import Foundation

final class HydrationService {

    private let entriesKey      = "aquaflow_entries"
    private let profileKey      = "aquaflow_profile"
    private let goalKey         = "aquaflow_goal"
    private let achievementsKey = "aquaflow_achievements"
    private let petKey          = "aquaflow_pet"

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    // MARK: - Entries

    func saveEntries(_ entries: [DrinkEntry]) {
        if let data = try? encoder.encode(entries) {
            UserDefaults.standard.set(data, forKey: entriesKey)
        }
    }

    func loadEntries() -> [DrinkEntry] {
        guard let data = UserDefaults.standard.data(forKey: entriesKey),
              let entries = try? decoder.decode([DrinkEntry].self, from: data)
        else { return [] }
        return entries
    }

    // MARK: - Profile

    func saveProfile(_ profile: UserProfile) {
        if let data = try? encoder.encode(profile) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
    }

    func loadProfile() -> UserProfile {
        guard let data = UserDefaults.standard.data(forKey: profileKey),
              let profile = try? decoder.decode(UserProfile.self, from: data)
        else { return UserProfile() }
        return profile
    }

    // MARK: - Goal

    func saveGoal(_ goal: HydrationGoal) {
        if let data = try? encoder.encode(goal) {
            UserDefaults.standard.set(data, forKey: goalKey)
        }
    }

    func loadGoal() -> HydrationGoal {
        guard let data = UserDefaults.standard.data(forKey: goalKey),
              let goal = try? decoder.decode(HydrationGoal.self, from: data)
        else { return HydrationGoal() }
        return goal
    }

    // MARK: - Achievements

    func saveAchievements(_ achievements: [Achievement]) {
        if let data = try? encoder.encode(achievements) {
            UserDefaults.standard.set(data, forKey: achievementsKey)
        }
    }

    func loadAchievements() -> [Achievement] {
        guard let data = UserDefaults.standard.data(forKey: achievementsKey),
              let saved = try? decoder.decode([Achievement].self, from: data)
        else { return Achievement.defaults }
        // Merge defaults with saved (handles new achievements added in updates)
        var merged = Achievement.defaults
        for i in merged.indices {
            if let match = saved.first(where: { $0.id == merged[i].id }) {
                merged[i] = match
            }
        }
        return merged
    }

    // MARK: - Pet

    func savePet(_ pet: Pet) {
        if let data = try? encoder.encode(pet) {
            UserDefaults.standard.set(data, forKey: petKey)
        }
    }

    func loadPet() -> Pet {
        guard let data = UserDefaults.standard.data(forKey: petKey),
              let pet = try? decoder.decode(Pet.self, from: data)
        else { return Pet() }
        return pet
    }

    // MARK: - Calculations

    func totalIntakeML(for entries: [DrinkEntry], on date: Date) -> Double {
        let dayEntries = entries.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
        return dayEntries.reduce(0) { $0 + $1.effectiveML }
    }

    func calculateStreak(entries: [DrinkEntry], goal: Double) -> (current: Int, longest: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get all unique days with entries
        var dayTotals: [Date: Double] = [:]
        for entry in entries {
            let day = calendar.startOfDay(for: entry.date)
            dayTotals[day, default: 0] += entry.effectiveML
        }

        // Current streak (going backwards from today)
        var currentStreak = 0
        var checkDate = today
        while true {
            let total = dayTotals[checkDate] ?? 0
            if total >= goal {
                currentStreak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }

        // Longest streak
        let sortedDays = dayTotals.keys.sorted()
        var longest = 0
        var current = 0
        var prevDay: Date? = nil
        for day in sortedDays {
            if let total = dayTotals[day], total >= goal {
                if let prev = prevDay,
                   calendar.dateComponents([.day], from: prev, to: day).day == 1 {
                    current += 1
                } else {
                    current = 1
                }
                longest = max(longest, current)
            } else {
                current = 0
            }
            prevDay = day
        }

        return (currentStreak, longest)
    }

    func calculateStats(entries: [DrinkEntry], goal: HydrationGoal) -> HydrationStats {
        var stats = HydrationStats()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Weekly data (last 7 days)
        var weeklyData: [DayData] = []
        for i in (0..<7).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let total = totalIntakeML(for: entries, on: day)
            weeklyData.append(DayData(date: day, amountML: total, goalML: goal.dailyGoalML))
        }
        stats.weeklyData = weeklyData

        // Monthly data (last 30 days)
        var monthlyData: [DayData] = []
        for i in (0..<30).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let total = totalIntakeML(for: entries, on: day)
            monthlyData.append(DayData(date: day, amountML: total, goalML: goal.dailyGoalML))
        }
        stats.monthlyData = monthlyData

        // Weekly average (non-zero days)
        let nonZero = weeklyData.filter { $0.amountML > 0 }
        stats.weeklyAverage = nonZero.isEmpty ? 0 : nonZero.reduce(0) { $0 + $1.amountML } / Double(nonZero.count)

        // Best day
        stats.bestDay = monthlyData.max(by: { $0.amountML < $1.amountML })?.amountML ?? 0

        // Streak
        let (current, longest) = calculateStreak(entries: entries, goal: goal.dailyGoalML)
        stats.currentStreak = current
        stats.longestStreak  = longest

        // Total days tracked
        let uniqueDays = Set(entries.map { calendar.startOfDay(for: $0.date) })
        stats.totalDaysTracked = uniqueDays.count

        return stats
    }

    func updateAchievements(
        achievements: inout [Achievement],
        entries: [DrinkEntry],
        stats: HydrationStats,
        goal: HydrationGoal
    ) -> [Achievement] {
        var newlyUnlocked: [Achievement] = []
        let totalEntries = entries.count
        let todayTotal   = totalIntakeML(for: entries, on: Date())

        for i in achievements.indices {
            guard !achievements[i].isUnlocked else { continue }
            var unlock = false

            switch achievements[i].id {
            case .firstDrink:
                achievements[i].current = min(totalEntries, 1)
                unlock = totalEntries >= 1
            case .streak3:
                achievements[i].current = min(stats.currentStreak, 3)
                unlock = stats.currentStreak >= 3
            case .streak7:
                achievements[i].current = min(stats.currentStreak, 7)
                unlock = stats.currentStreak >= 7
            case .streak14:
                achievements[i].current = min(stats.currentStreak, 14)
                unlock = stats.currentStreak >= 14
            case .streak30:
                achievements[i].current = min(stats.currentStreak, 30)
                unlock = stats.currentStreak >= 30
            case .perfectWeek:
                let metGoal = stats.weeklyData.filter { $0.isGoalMet }.count
                achievements[i].current = min(metGoal, 7)
                unlock = metGoal >= 7
            case .hydrationHero:
                achievements[i].current = min(totalEntries, 100)
                unlock = totalEntries >= 100
            case .earlyBird:
                let hasEarly = entries.contains { $0.hour < 8 }
                achievements[i].current = hasEarly ? 1 : 0
                unlock = hasEarly
            case .nightOwl:
                let hasLate = entries.contains { $0.hour >= 22 }
                achievements[i].current = hasLate ? 1 : 0
                unlock = hasLate
            case .goalCrusher:
                let exceeded = todayTotal >= goal.dailyGoalML * 1.5
                achievements[i].current = exceeded ? 1 : 0
                unlock = exceeded
            }

            if unlock {
                achievements[i].isUnlocked  = true
                achievements[i].unlockedDate = Date()
                newlyUnlocked.append(achievements[i])
            }
        }

        return newlyUnlocked
    }
}
