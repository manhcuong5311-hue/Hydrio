import SwiftUI
import Combine

final class HydrationViewModel: ObservableObject {

    // MARK: - Published State
    @Published var entries:         [DrinkEntry]   = []
    @Published var profile:         UserProfile    = UserProfile()
    @Published var goal:            HydrationGoal  = HydrationGoal()
    @Published var achievements:    [Achievement]  = Achievement.defaults
    @Published var pet:             Pet            = Pet()
    @Published var stats:           HydrationStats = HydrationStats()
    @Published var todayTotal:      Double         = 0
    @Published var showGoalReached: Bool           = false
    @Published var newlyUnlocked:   [Achievement]  = []
    @Published var isAnimatingDrop: Bool           = false
    @Published var showUndoToast:   Bool           = false
    @Published var lastAddedEntry:  DrinkEntry?    = nil
    var isPremium: Bool { UserDefaults.standard.bool(forKey: "isPremium") }

    private let service = HydrationService()
    private var wasGoalReached = false
    private var undoWorkItem: DispatchWorkItem?

    // MARK: - Computed
    var todayProgress: Double {
        goal.dailyGoalML > 0 ? min(todayTotal / goal.dailyGoalML, 1.0) : 0
    }

    var todayEntries: [DrinkEntry] {
        entries
            .filter { Calendar.current.isDateInToday($0.date) }
            .sorted { $0.date > $1.date }
    }

    var remainingML: Double { max(goal.dailyGoalML - todayTotal, 0) }

    var coachMessage: String {
        let pct = todayProgress
        switch pct {
        case 0..<0.25:
            return "Start your day with a glass of water! Your body loses water overnight through breathing and sweating — rehydrating first thing in the morning jumpstarts your metabolism and sharpens focus."
        case 0.25..<0.5:
            return "You're \(Int(pct * 100))% there — great start! Consistent small sips throughout the day are more effective than drinking large amounts at once. Try keeping a bottle nearby as a visual reminder."
        case 0.5..<0.75:
            return "Halfway through your goal! You need \(formattedML(remainingML)) more today. Staying above 50% hydration helps maintain energy levels and reduces afternoon fatigue. Keep that rhythm going!"
        case 0.75..<1.0:
            return "Almost done — just \(formattedML(remainingML)) left! You're in the home stretch. Proper hydration at this level supports kidney function, skin health, and keeps your concentration sharp through the rest of the day."
        default:
            return "Goal crushed! 🎉 You've hit your full hydration target for today. Well-hydrated cells recover faster, your joints stay lubricated, and your body detoxifies more efficiently. Your streak is looking strong — keep it going tomorrow!"
        }
    }

    var coachTip: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let streak = stats.currentStreak
        switch true {
        case streak >= 7:
            return "💪 \(streak)-day streak! Long-term consistent hydration improves kidney health and reduces the risk of urinary tract infections."
        case todayTotal == 0 && hour >= 10:
            return "⚠️ You haven't logged any water yet today. Even mild dehydration (1–2%) can impair memory and cause headaches."
        case hour >= 14 && hour <= 16 && todayProgress < 0.5:
            return "😴 Afternoon slump? It's often dehydration, not tiredness. A glass of water now can restore alertness within 20 minutes."
        case hour >= 20:
            return "🌙 Avoid drinking large amounts right before bed. Space out your last \(formattedML(remainingML)) over the next hour to sleep comfortably."
        case profile.activityLevel == .veryActive || profile.activityLevel == .extraActive:
            return "🏃 Active lifestyle detected. You may need extra hydration on workout days — drink an additional 500ml for every hour of intense exercise."
        default:
            return "💡 Drinking water before meals can reduce calorie intake and improve digestion. Try a glass 30 minutes before your next meal."
        }
    }

    // MARK: - Init

    init() {
        loadAll()
    }

    // MARK: - Actions

    func addDrink(amountML: Double, type: DrinkType = .water) {
        let entry = DrinkEntry(amountML: amountML, drinkType: type)
        entries.insert(entry, at: 0)
        service.saveEntries(entries)

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isAnimatingDrop = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.isAnimatingDrop = false
        }

        // Pet XP — free tier capped at stage 2 (.plant)
        let xpGained = max(5, Int(amountML / 50))
        if isPremium || pet.growthStage.rawValue < PetGrowthStage.plant.rawValue {
            pet.addXP(xpGained)
        }
        pet.happiness = min(1.0, pet.happiness + 0.05)
        service.savePet(pet)

        recalculate()

        // Goal reached check
        let nowReached = todayTotal >= goal.dailyGoalML
        if nowReached && !wasGoalReached {
            wasGoalReached = true
            showGoalReached = true
            NotificationManager.shared.sendGoalReachedNotification()
        }

        // Undo toast — replace any pending timer
        lastAddedEntry = entry
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showUndoToast = true
        }
        undoWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            withAnimation(.easeInOut(duration: 0.3)) { self?.showUndoToast = false }
        }
        undoWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: work)
    }

    func undoLastDrink() {
        guard let entry = lastAddedEntry else { return }
        undoWorkItem?.cancel()
        removeDrink(entry)
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.warning)
        withAnimation(.easeInOut(duration: 0.3)) { showUndoToast = false }
        lastAddedEntry = nil
    }

    func removeDrink(_ entry: DrinkEntry) {
        entries.removeAll { $0.id == entry.id }
        service.saveEntries(entries)
        recalculate()
    }

    func editDrink(_ entry: DrinkEntry, newAmountML: Double) {
        guard let idx = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[idx] = DrinkEntry(id: entry.id, amountML: newAmountML,
                                  date: entry.date, drinkType: entry.drinkType, note: entry.note)
        service.saveEntries(entries)
        recalculate()
    }

    func updateGoal(_ newGoal: HydrationGoal) {
        goal = newGoal
        service.saveGoal(goal)
        recalculate()
        // Use the shared window manager so the clamping window is always respected
        NotificationManager.shared.scheduleReminders(
            interval: goal.reminderInterval,
            window: NotificationWindowManager.shared
        )
    }

    func updateProfile(_ newProfile: UserProfile) {
        profile = newProfile
        service.saveProfile(profile)
        goal.dailyGoalML = profile.recommendedDailyIntakeML
        service.saveGoal(goal)
        recalculate()
    }

    // MARK: - Private

    private func loadAll() {
        entries      = service.loadEntries()
        profile      = service.loadProfile()
        goal         = service.loadGoal()
        achievements = service.loadAchievements()
        pet          = service.loadPet()
        recalculate()
    }

    private func recalculate() {
        todayTotal = service.totalIntakeML(for: entries, on: Date())
        stats      = service.calculateStats(entries: entries, goal: goal)
        wasGoalReached = todayTotal >= goal.dailyGoalML

        // Update pet happiness with daily reset logic
        pet.updateHappiness(todayProgress: todayProgress)
        service.savePet(pet)

        let unlocked = service.updateAchievements(
            achievements: &achievements,
            entries: entries,
            stats: stats,
            goal: goal
        )
        if !unlocked.isEmpty {
            newlyUnlocked = unlocked
            service.saveAchievements(achievements)
        }
    }

    // MARK: - Helpers

    func formattedML(_ ml: Double) -> String {
        ml >= 1000 ? String(format: "%.1fL", ml / 1000) : "\(Int(ml))ml"
    }

    func changePetType(_ type: PetType) {
        pet.type = type
        pet.name = type.defaultName
        service.savePet(pet)
    }

    func entriesFor(date: Date) -> [DrinkEntry] {
        entries.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date > $1.date }
    }

    func totalFor(date: Date) -> Double {
        service.totalIntakeML(for: entries, on: date)
    }
}
