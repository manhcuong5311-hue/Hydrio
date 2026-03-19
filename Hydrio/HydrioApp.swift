import SwiftUI

@main
struct HydrioApp: App {

    // Store must be created first so PremiumManager can observe it.
    @StateObject private var store: StoreManager
    @StateObject private var premiumManager: PremiumManager
    @StateObject private var hydrationVM = HydrationViewModel()
    @StateObject private var notificationWindow = NotificationWindowManager.shared

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        let store = StoreManager()
        _store = StateObject(wrappedValue: store)
        _premiumManager = StateObject(wrappedValue: PremiumManager(store: store))
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                        .environmentObject(hydrationVM)
                        .environmentObject(store)
                        .environmentObject(premiumManager)
                        .environmentObject(notificationWindow)
                } else {
                    OnboardingView()
                        .environmentObject(hydrationVM)
                        .environmentObject(store)
                        .environmentObject(premiumManager)
                        .environmentObject(notificationWindow)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
