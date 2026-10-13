import SwiftUI

@main
struct HydrioApp: App {

    @StateObject private var store: StoreManager
    @StateObject private var hydrationVM = HydrationViewModel()
    @StateObject private var notificationWindow = NotificationWindowManager.shared

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        let store = StoreManager()
        _store = StateObject(wrappedValue: store)
        // Ads run only while the user hasn't bought "Remove Ads".
        AdsManager.shared.bind(isAdFree: store.$isAdFree)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                        .environmentObject(hydrationVM)
                        .environmentObject(store)
                        .environmentObject(notificationWindow)
                        // Consent form / ATT prompt only once the main UI is up — never during onboarding.
                        .onAppear { AdsManager.shared.activate() }
                } else {
                    OnboardingView()
                        .environmentObject(hydrationVM)
                        .environmentObject(notificationWindow)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
