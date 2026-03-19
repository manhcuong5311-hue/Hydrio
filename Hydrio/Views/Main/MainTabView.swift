import SwiftUI

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var vm: HydrationViewModel
    @EnvironmentObject var store: StoreManager
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var notificationWindow: NotificationWindowManager
    @State private var selectedTab = 0
    @State private var showAddSheet = false
    @State private var showAchievementToast = false
    @State private var toastAchievement: Achievement? = nil

    var body: some View {
        ZStack(alignment: .bottom) {

            // MARK: Page Content
            Color.appBackground.ignoresSafeArea()

            Group {
                switch selectedTab {
                case 0: HomeView()
                case 1: HistoryView()
                case 2: StatsView()
                case 3: AchievementsView()
                default: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
            .environmentObject(vm)
            .environmentObject(store)
            .environmentObject(premiumManager)
            .environmentObject(notificationWindow)

            // MARK: Undo Toast — slides up from above the bar
            if vm.showUndoToast, let entry = vm.lastAddedEntry {
                VStack(spacing: 0) {
                    Spacer()
                    UndoToast(entry: entry)
                        .padding(.horizontal, Spacing.md)
                        .padding(.bottom, 108)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.showUndoToast)
                .zIndex(50)
            }

            // MARK: Achievement Toast — slides down from top
            if showAchievementToast, let ach = toastAchievement {
                VStack {
                    AchievementToast(achievement: ach, isShowing: $showAchievementToast)
                        .padding(.top, Spacing.lg)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(100)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        withAnimation { showAchievementToast = false }
                    }
                }
            }

            // MARK: Custom Bottom Bar — compact tab bar + plus button on the same row
            HStack(spacing: 10) {
                CompactTabBar(selectedTab: $selectedTab)
                AddPlusButton { showAddSheet = true }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
            .zIndex(10)
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showAddSheet) {
            CustomAddView().environmentObject(vm)
        }
        // Daily premium wall — shown max once per day for free users
        .sheet(isPresented: $premiumManager.showPremiumWall) {
            PremiumSheet()
                .environmentObject(store)
                .environmentObject(premiumManager)
        }
        .onChange(of: selectedTab) { _, newTab in
            // Trigger the daily wall when the user opens the Home or Stats tab
            if newTab == 0 || newTab == 2 {
                premiumManager.triggerWallIfNeeded()
            }
        }
        .onChange(of: vm.newlyUnlocked) { _, unlocked in
            guard let first = unlocked.first else { return }
            toastAchievement = first
            withAnimation(.spring()) { showAchievementToast = true }
            vm.newlyUnlocked = []
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Compact Tab Bar Pill

struct CompactTabBar: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var store: StoreManager
    @EnvironmentObject var premiumManager: PremiumManager
    @State private var showStatsPaywall = false
    @Namespace private var indicator

    private struct TabItem {
        let icon: String
        let active: String
    }
    private let items: [TabItem] = [
        .init(icon: "house",      active: "house.fill"),
        .init(icon: "calendar",   active: "calendar.badge.clock"),
        .init(icon: "chart.bar",  active: "chart.bar.fill"),
        .init(icon: "trophy",     active: "trophy.fill"),
        .init(icon: "gearshape",  active: "gearshape.fill"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<items.count, id: \.self) { i in
                Button {
                    // Stats tab (index 2) locked for free users
                    if i == 2 && !store.isPremium {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        showStatsPaywall = true
                        return
                    }
                    guard selectedTab != i else { return }
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        selectedTab = i
                    }
                } label: {
                    ZStack {
                        // Sliding pill indicator
                        if selectedTab == i {
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .fill(Color.goldPrimary.opacity(0.18))
                                .matchedGeometryEffect(id: "tab_pill", in: indicator)
                                .padding(4)
                        }

                        Image(systemName: selectedTab == i ? items[i].active : items[i].icon)
                            .font(.system(size: 17, weight: selectedTab == i ? .semibold : .regular))
                            .foregroundStyle(selectedTab == i
                                ? AnyShapeStyle(LinearGradient.goldGradient)
                                : AnyShapeStyle(Color.white.opacity(0.4)))
                            .scaleEffect(selectedTab == i ? 1.08 : 1.0)

                        // Lock badge on Stats for free users
                        if i == 2 && !store.isPremium {
                            VStack {
                                HStack {
                                    Spacer()
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.goldPrimary)
                                        .padding(3)
                                        .background(Circle().fill(Color(hex: "161616")))
                                        .offset(x: 4, y: -4)
                                }
                                Spacer()
                            }
                            .frame(width: 28, height: 28)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showStatsPaywall) {
            PremiumSheet()
                .environmentObject(store)
                .environmentObject(premiumManager)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(hex: "161616"))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.55), radius: 24, x: 0, y: 8)
        )
    }
}

// MARK: - Plus Button (same height as tab bar)

struct AddPlusButton: View {
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            ZStack {
                // Glow
                Circle()
                    .fill(Color.goldPrimary.opacity(0.25))
                    .frame(width: 66, height: 66)
                    .blur(radius: 8)

                // Button face
                Circle()
                    .fill(LinearGradient.goldGradient)
                    .frame(width: 52, height: 52)
                    .shadow(color: Color.goldPrimary.opacity(0.55), radius: 12, x: 0, y: 6)

                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color(hex: "0B0B0B"))
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .frame(width: 52, height: 52)
    }
}

// MARK: - Undo Toast

struct UndoToast: View {
    @EnvironmentObject var vm: HydrationViewModel
    let entry: DrinkEntry

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle().fill(entry.drinkType.color.opacity(0.18)).frame(width: 36, height: 36)
                Image(systemName: entry.drinkType.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(entry.drinkType.color)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("Added \(entry.displayAmount)")
                    .font(.titleSmall).foregroundStyle(.textPrimary)
                Text(entry.drinkType.displayName)
                    .font(.captionLarge).foregroundStyle(.textSecondary)
            }

            Spacer()

            Button { vm.undoLastDrink() } label: {
                Text("Undo")
                    .font(.titleSmall).foregroundStyle(.goldPrimary)
                    .padding(.horizontal, Spacing.md).padding(.vertical, Spacing.xs + 2)
                    .background(
                        Capsule().fill(Color.goldPrimary.opacity(0.12))
                            .overlay(Capsule().strokeBorder(Color.goldPrimary.opacity(0.35), lineWidth: 1))
                    )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm + 2)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .fill(Color(hex: "1C1C1E"))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.45), radius: 20, x: 0, y: 8)
        )
    }
}
