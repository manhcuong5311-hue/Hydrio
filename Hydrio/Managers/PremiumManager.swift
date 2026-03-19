import SwiftUI
import Combine

// MARK: - Premium Manager

/// Centralised observable layer for premium access control and daily premium wall logic.
/// Wraps StoreManager and exposes feature-gate APIs consumed by views and services.
@MainActor
final class PremiumManager: ObservableObject {

    // MARK: - Published

    @Published private(set) var isPremium: Bool = false
    /// Setting this to true presents the premium wall from MainTabView.
    @Published var showPremiumWall: Bool = false

    // MARK: - Private

    private let store: StoreManager
    private var cancellables = Set<AnyCancellable>()
    private let wallDateKey = "hydrio_last_wall_date"

    // MARK: - Init

    init(store: StoreManager) {
        self.store = store
        self.isPremium = store.isPremium

        // Mirror StoreManager.isPremium reactively
        store.$isPremium
            .receive(on: DispatchQueue.main)
            .sink { [weak self] premium in
                self?.isPremium = premium
                // Auto-dismiss the wall the moment the user upgrades
                if premium { self?.showPremiumWall = false }
            }
            .store(in: &cancellables)
    }

    // MARK: - Feature Gates

    /// Returns true when the given pet type is locked for the current user.
    /// Pet 1 (plant) is always free; Dragon and Cloud require premium.
    func isPetLocked(_ type: PetType) -> Bool {
        guard !isPremium else { return false }
        return type != .plant
    }

    /// Advanced notification window customisation is a premium feature.
    var canCustomizeNotificationWindow: Bool { isPremium }

    // MARK: - Daily Premium Wall

    /// True when the premium wall should be shown:
    /// the user is free AND the wall has not been shown today.
    var shouldShowDailyWall: Bool {
        guard !isPremium else { return false }
        guard let last = UserDefaults.standard.object(forKey: wallDateKey) as? Date else {
            return true // Never shown before
        }
        return !Calendar.current.isDateInToday(last)
    }

    /// Persist today's date so the wall won't appear again until tomorrow.
    func recordWallShown() {
        UserDefaults.standard.set(Date(), forKey: wallDateKey)
    }

    /// Shows the premium wall if the user is free and it hasn't been shown today.
    /// Call this after meaningful user actions (e.g. opening dashboard, logging a drink).
    func triggerWallIfNeeded() {
        guard shouldShowDailyWall else { return }
        recordWallShown()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            showPremiumWall = true
        }
    }
}
