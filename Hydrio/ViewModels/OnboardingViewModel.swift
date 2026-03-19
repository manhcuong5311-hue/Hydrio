import SwiftUI
import Combine

final class OnboardingViewModel: ObservableObject {
    @Published var currentPage: Int        = 0
    @Published var name: String            = ""
    @Published var weight: Double          = 70
    @Published var gender: Gender          = .male
    @Published var activityLevel: ActivityLevel = .moderatelyActive
    @Published var reminderInterval: ReminderInterval = .oneHour
    @Published var selectedGoalML: Double  = 2300

    let totalPages = 6

    var profile: UserProfile {
        UserProfile(name: name, weight: weight, gender: gender,
                    activityLevel: activityLevel, age: 25)
    }

    var calculatedGoalML: Double { profile.recommendedDailyIntakeML }

    var displayGoal: String {
        String(format: "%.1fL", calculatedGoalML / 1000)
    }

    func next() {
        if currentPage == 2 { selectedGoalML = calculatedGoalML }
        if currentPage < totalPages - 1 {
            withAnimation(.easeInOut(duration: 0.35)) { currentPage += 1 }
        }
    }

    func back() {
        if currentPage > 0 {
            withAnimation(.easeInOut(duration: 0.35)) { currentPage -= 1 }
        }
    }

    func finish(hydrationVM: HydrationViewModel) {
        hydrationVM.updateProfile(profile)
        var newGoal = HydrationGoal()
        newGoal.dailyGoalML = selectedGoalML
        newGoal.reminderInterval = reminderInterval
        hydrationVM.updateGoal(newGoal)
        Task {
            let granted = await NotificationManager.shared.requestPermission()
            if granted {
                NotificationManager.shared.scheduleReminders(interval: reminderInterval)
            }
        }
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}
