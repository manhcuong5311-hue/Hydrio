import SwiftUI
import StoreKit
import SafariServices
import Combine
import UserNotifications
// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var vm: HydrationViewModel
    @EnvironmentObject var store: StoreManager
    @EnvironmentObject var notificationWindow: NotificationWindowManager
    @ObservedObject private var ads = AdsManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true

    @State private var weight: Double            = 70
    @State private var gender: Gender            = .male
    @State private var activityLevel: ActivityLevel = .moderatelyActive
    @State private var goalML: Double            = 2300
    @State private var reminderInterval: ReminderInterval = .oneHour

    @State private var showResetAlert            = false
    @State private var showRemoveAdsSheet        = false
    @State private var showPrivacySheet          = false
    @State private var showFAQSheet              = false
    @State private var showEULASheet             = false
    @State private var showWHOSheet              = false
    @State private var showRestoreResult         = false
    @State private var restoreMessage            = ""
    @State private var notificationsEnabled      = false
    @State private var authStatus: UNAuthorizationStatus = .notDetermined
    private let privacyURL = URL(string: "https://manhcuong5311-hue.github.io/Hydrio/")!
    private let eulaURL    = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private let whoURL     = URL(string: "https://www.who.int/news-room/fact-sheets/detail/drinking-water")!

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.lg) {

                    // MARK: Header
                    HStack {
                        Text("Settings")
                            .font(.displaySmall).foregroundStyle(.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)

                    // MARK: Remove Ads
                    RemoveAdsCard(isAdFree: store.isAdFree,
                                  price: store.product?.displayPrice) {
                        showRemoveAdsSheet = true
                    }
                    .padding(.horizontal, Spacing.md)

                    // MARK: Profile
                    SettingsSection(title: "Profile", icon: "person.fill") {
                        VStack(spacing: Spacing.md) {
                            SettingsField(label: "Gender") {
                                Picker("Gender", selection: $gender) {
                                    ForEach(Gender.allCases, id: \.self) { Text($0.displayName).tag($0) }
                                }
                                .pickerStyle(.segmented)
                            }
                            SettingsDivider()
                            SettingsField(label: "Weight") {
                                HStack {
                                    Slider(value: $weight, in: 40...150, step: 1).tint(.hydrationBlue)
                                    Text("\(Int(weight)) kg")
                                        .font(.titleSmall).foregroundStyle(.hydrationBlue).frame(width: 56)
                                }
                            }
                            SettingsDivider()
                            SettingsField(label: "Activity") {
                                Picker("Activity", selection: $activityLevel) {
                                    ForEach(ActivityLevel.allCases, id: \.self) { Text($0.displayName).tag($0) }
                                }
                                .pickerStyle(.menu).tint(.hydrationBlue)
                            }
                        }
                    }

                    // MARK: Goal
                    SettingsSection(title: "Hydration Goal", icon: "drop.fill") {
                        VStack(spacing: Spacing.md) {
                            SettingsField(label: "Daily Goal") {
                                HStack {
                                    Slider(value: $goalML, in: 1000...5000, step: 100).tint(.hydrationBlue)
                                    Text(goalML >= 1000 ? String(format: "%.1fL", goalML/1000) : "\(Int(goalML))ml")
                                        .font(.titleSmall).foregroundStyle(.hydrationBlue).frame(width: 52)
                                }
                            }
                            SettingsDivider()
                            let suggested = UserProfile(weight: weight, gender: gender,
                                                         activityLevel: activityLevel).recommendedDailyIntakeML
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Suggested for you").font(.bodySmall).foregroundStyle(.textSecondary)
                                    Text(String(format: "%.1fL", suggested / 1000))
                                        .font(.titleSmall).foregroundStyle(.hydrationBlue)
                                }
                                Spacer()
                                Button { withAnimation { goalML = suggested } } label: {
                                    Text("Use This")
                                        .font(.captionLarge).fontWeight(.semibold)
                                        .foregroundStyle(Color(hex: "0B0B0B"))
                                        .padding(.horizontal, Spacing.md).padding(.vertical, Spacing.xs)
                                        .background(LinearGradient.goldGradient).clipShape(Capsule())
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }

                    // MARK: Notifications
                    NotificationsSection(
                        enabled: $notificationsEnabled,
                        interval: $reminderInterval,
                        authStatus: authStatus,
                        onToggle: { enabled in
                            Task { await handleNotificationToggle(enabled) }
                        },
                        onIntervalChange: { interval in
                            withAnimation(.spring(response: 0.3)) { reminderInterval = interval }
                            if notificationsEnabled {
                                NotificationManager.shared.scheduleReminders(
                                    interval: interval,
                                    window: notificationWindow
                                )
                            }
                        }
                    )

                    // MARK: Notification Window
                    NotificationWindowSection(
                        window: notificationWindow,
                        isEnabled: notificationsEnabled,
                        onWindowChange: {
                            notificationWindow.save()
                            if notificationsEnabled {
                                NotificationManager.shared.scheduleReminders(
                                    interval: reminderInterval,
                                    window: notificationWindow
                                )
                            }
                        }
                    )

                    // MARK: Pet
                    SettingsSection(title: "Pet", icon: "pawprint.fill") {
                        VStack(spacing: Spacing.md) {
                            HStack(spacing: Spacing.md) {
                                PetCharacterView(pet: vm.pet, size: 60)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(vm.pet.name).font(.titleSmall).foregroundStyle(.textPrimary)
                                    Text("Stage: \(vm.pet.stageEmoji) \(vm.pet.stageName)")
                                        .font(.bodySmall).foregroundStyle(.textSecondary)
                                    Text(vm.pet.stageDescription)
                                        .font(.captionLarge).foregroundStyle(.textTertiary)
                                }
                                Spacer()
                            }

                            Divider().background(Color.white.opacity(0.1))

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Choose Your Pet")
                                    .font(.bodySmall).foregroundStyle(.textSecondary)
                                HStack(spacing: Spacing.sm) {
                                    ForEach(PetType.allCases, id: \.self) { type in
                                        let selected = vm.pet.type == type
                                        Button {
                                            vm.changePetType(type)
                                        } label: {
                                            VStack(spacing: 4) {
                                                Image(systemName: type.icon)
                                                    .font(.system(size: 20))
                                                Text(type.displayName)
                                                    .font(.captionLarge)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                selected
                                                    ? Color.hydrationBlue.opacity(0.25)
                                                    : Color.white.opacity(0.05)
                                            )
                                            .foregroundStyle(selected ? Color.hydrationBlue : Color.textSecondary)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(selected ? Color.hydrationBlue.opacity(0.6) : Color.clear,
                                                            lineWidth: 1.5)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }

                    // MARK: App Support
                    SettingsSection(title: "App Support", icon: "questionmark.circle.fill") {
                        VStack(spacing: 0) {
                            SupportRow(icon: "questionmark.circle.fill", iconColor: .hydrationBlue,
                                       title: "FAQ") {
                                showFAQSheet = true
                            }
                            SettingsDivider()
                            SupportRow(icon: "lock.shield.fill", iconColor: Color(hex: "4CAF50"),
                                       title: "Privacy Policy") {
                                showPrivacySheet = true
                            }
                            SettingsDivider()
                            SupportRow(icon: "doc.text.fill", iconColor: Color(hex: "FF9800"),
                                       title: "Terms of Use & EULA") {
                                showEULASheet = true
                            }
                            SettingsDivider()
                            // Restore Purchases row
                            Button {
                                Task {
                                    await store.restore()
                                    if store.isAdFree {
                                        restoreMessage = "Your purchase has been restored — ads are removed."
                                    } else {
                                        restoreMessage = store.purchaseState.errorMessage
                                            ?? "No previous purchases found for this Apple ID."
                                    }
                                    store.resetState()
                                    showRestoreResult = true
                                }
                            } label: {
                                HStack(spacing: Spacing.md) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(Color.goldPrimary.opacity(0.15))
                                            .frame(width: 32, height: 32)
                                        if store.purchaseState == .restoring {
                                            ProgressView().tint(.goldPrimary).scaleEffect(0.75)
                                        } else {
                                            Image(systemName: "arrow.clockwise.circle.fill")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(.goldPrimary)
                                        }
                                    }
                                    Text("Restore Purchases")
                                        .font(.bodyMedium).foregroundStyle(.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.captionSmall).foregroundStyle(.textTertiary)
                                }
                                .padding(.vertical, Spacing.sm)
                            }
                            .buttonStyle(.plain)
                            .disabled(store.purchaseState.isLoading)
                            // Required by Google for EEA/UK users: let them change ad consent.
                            if ads.adsEnabled && ads.privacyOptionsRequired {
                                SettingsDivider()
                                SupportRow(icon: "hand.raised.fill", iconColor: Color(hex: "26A69A"),
                                           title: "Ad privacy choices") {
                                    ads.presentPrivacyOptions()
                                }
                            }
                            SettingsDivider()
                            RateAppRow()
                        }
                    }

                    // MARK: Data
                    SettingsSection(title: "Data", icon: "externaldrive.fill") {
                        Button { showResetAlert = true } label: {
                            HStack {
                                Image(systemName: "trash.fill").foregroundStyle(.errorRed)
                                Text("Reset All Data").font(.bodyMedium).foregroundStyle(.errorRed)
                                Spacer()
                                Image(systemName: "chevron.right").font(.captionSmall).foregroundStyle(.textTertiary)
                            }
                            .padding(.vertical, Spacing.sm)
                        }
                        .buttonStyle(.plain)
                    }

                    // MARK: Health Disclaimer
                    GlassCard(padding: Spacing.md) {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color(hex: "FF9800"))
                                Text("Health Disclaimer")
                                    .font(.titleSmall).foregroundStyle(.textPrimary)
                            }
                            Text("Hydrio provides general hydration guidance only and is not a substitute for professional medical advice, diagnosis, or treatment. Always consult a qualified healthcare provider regarding any health concerns.")
                                .font(.captionLarge).foregroundStyle(.textSecondary)
                                .lineSpacing(3)
                            Button { showWHOSheet = true } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "link")
                                        .font(.captionLarge)
                                    Text("WHO Drinking Water Guidelines")
                                        .font(.captionLarge).fontWeight(.semibold)
                                }
                                .foregroundStyle(.hydrationBlue)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, Spacing.md)

                    // Footer
                    VStack(spacing: Spacing.xs) {
                        Text("Version \(appVersion)").font(.captionSmall).foregroundStyle(.textTertiary)
                        Text("Made with 💧 for your health").font(.captionSmall).foregroundStyle(.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.lg)

                    Spacer(minLength: 160)
                }
            }
        }
        .task {
            authStatus = await NotificationManager.shared.authorizationStatus()
        }
        .onAppear { loadSettings() }
       
        .alert("Reset All Data?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) { resetData() }
        } message: {
            Text("This will delete all your drink logs, streaks, and achievements. This cannot be undone.")
        }
        .sheet(isPresented: $showRemoveAdsSheet) {
            RemoveAdsSheet().environmentObject(store)
        }
        .sheet(isPresented: $showPrivacySheet) { SafariSheet(url: privacyURL) }
        .sheet(isPresented: $showFAQSheet)     { FAQSheet() }
        .sheet(isPresented: $showEULASheet)    { SafariSheet(url: eulaURL) }
        .sheet(isPresented: $showWHOSheet)     { SafariSheet(url: whoURL) }
        .alert("Restore Purchases", isPresented: $showRestoreResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(restoreMessage)
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    private func loadSettings() {
        weight             = vm.profile.weight
        gender             = vm.profile.gender
        activityLevel      = vm.profile.activityLevel
        goalML             = vm.goal.dailyGoalML
        reminderInterval   = vm.goal.reminderInterval
        notificationsEnabled = vm.goal.reminderInterval != .never
    }

    private func handleNotificationToggle(_ enabled: Bool) async {
        if enabled {
            let status = await NotificationManager.shared.authorizationStatus()
            authStatus = status
            switch status {
            case .notDetermined:
                let granted = await NotificationManager.shared.requestPermission()
                authStatus = granted ? .authorized : .denied
                if granted {
                    notificationsEnabled = true
                    NotificationManager.shared.scheduleReminders(interval: reminderInterval, window: notificationWindow)
                } else {
                    notificationsEnabled = false
                }
            case .authorized, .provisional, .ephemeral:
                notificationsEnabled = true
                NotificationManager.shared.scheduleReminders(interval: reminderInterval, window: notificationWindow)
            case .denied:
                notificationsEnabled = false
            @unknown default:
                notificationsEnabled = false
            }
        } else {
            notificationsEnabled = false
            NotificationManager.shared.cancelAll()
            // persist .never immediately
            var goal = vm.goal
            goal.reminderInterval = .never
            vm.updateGoal(goal)
        }
    }

    private func persistSettings() {
        var profile = vm.profile
        profile.weight = weight
        profile.gender = gender; profile.activityLevel = activityLevel
        vm.updateProfile(profile)
        var goal = vm.goal
        goal.dailyGoalML = goalML
        goal.reminderInterval = notificationsEnabled ? reminderInterval : .never
        vm.updateGoal(goal)
    }

    private func resetData() {
        ["aquaflow_entries","aquaflow_profile","aquaflow_goal",
         "aquaflow_achievements","aquaflow_pet","hasCompletedOnboarding"]
            .forEach { UserDefaults.standard.removeObject(forKey: $0) }
        hasCompletedOnboarding = false
    }
}

// MARK: - Support Row

struct SupportRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
                Text(title)
                    .font(.bodyMedium).foregroundStyle(.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.captionSmall).foregroundStyle(.textTertiary)
            }
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Rate App Row

struct RateAppRow: View {
    @Environment(\.openURL) private var openURL
    private let appStoreURL = URL(string: "https://apps.apple.com/app/id6760774934?action=write-review")!

    var body: some View {
        Button {
            openURL(appStoreURL)
        } label: {
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.goldPrimary.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "star.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.goldPrimary)
                }
                Text("Rate Hydrio")
                    .font(.bodyMedium).foregroundStyle(.textPrimary)
                Spacer()
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.goldPrimary)
                    }
                }
            }
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FAQ Sheet

struct FAQSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var expandedIndex: Int? = nil

    let items: [(q: String, a: String)] = [
        ("How is my daily goal calculated?",
         "Your goal is based on your body weight (35ml per kg), adjusted for your gender and activity level. You can always fine-tune it manually in Settings."),
        ("What counts toward my hydration goal?",
         "All drinks count, but with different hydration factors. Water = 100%, herbal tea = 95%, sports drink = 95%, juice = 85%, tea = 90%, coffee = 80%. This reflects their actual hydration contribution."),
        ("How do I earn pet XP?",
         "Every drink you log earns your pet XP. Larger amounts earn more — roughly 1 XP per 50ml. Hit your daily goal consistently to help your pet grow from a Seed all the way to a Blooming Tree."),
        ("What are streaks?",
         "A streak is the number of consecutive days you've met your hydration goal. Your streak resets if you miss a day. Maintain streaks to unlock achievements like Week Warrior and Hydration Master."),
        ("Can I delete a drink entry?",
         "Yes! Swipe left on any entry in Today's Log on the Home screen to reveal the delete button. You can also tap the Undo button that appears immediately after logging a drink."),
        ("How do reminders work?",
         "Hydrio sends local notifications at your chosen interval (30 min, 1 hr, 2 hrs, or 3 hrs). Notifications must be allowed in your iPhone Settings for reminders to work."),
        ("Can I change my daily goal?",
         "Absolutely. Go to Settings → Hydration Goal and drag the slider, or tap 'Use This' to apply the goal calculated from your current profile."),
        ("How do I unlock achievements?",
         "Achievements unlock automatically as you reach milestones — logging your first drink, maintaining streaks, hitting goal targets, and more. Check the Achievements tab to see your progress."),
    ]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header bar
                HStack {
                    Text("FAQ")
                        .font(.displaySmall).foregroundStyle(.textPrimary)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(Color.white.opacity(0.25))
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.md)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.sm) {
                        ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                            FAQItem(question: item.q, answer: item.a,
                                    isExpanded: expandedIndex == idx) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                    expandedIndex = expandedIndex == idx ? nil : idx
                                }
                            }
                        }
                        Spacer(minLength: Spacing.xxl)
                    }
                    .padding(.horizontal, Spacing.md)
                }
            }
        }
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    let isExpanded: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            VStack(spacing: 0) {
                HStack(spacing: Spacing.md) {
                    // Number / dot
                    ZStack {
                        Circle()
                            .fill(isExpanded ? Color.hydrationBlue.opacity(0.2) : Color.white.opacity(0.05))
                            .frame(width: 32, height: 32)
                        Image(systemName: isExpanded ? "minus" : "plus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(isExpanded ? .hydrationBlue : .textSecondary)
                    }

                    Text(question)
                        .font(.titleSmall)
                        .foregroundStyle(.textPrimary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.down")
                        .font(.captionLarge)
                        .foregroundStyle(isExpanded ? .hydrationBlue : .textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(Spacing.md)

                if isExpanded {
                    Text(answer)
                        .font(.bodyMedium)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.md)
                        .padding(.bottom, Spacing.md)
                        .padding(.leading, 44) // align under question text
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(isExpanded ? Color.hydrationBlue.opacity(0.06) : Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .strokeBorder(
                                isExpanded ? Color.hydrationBlue.opacity(0.25) : Color.white.opacity(0.07),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Privacy Policy Sheet

struct PrivacyPolicySheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Privacy Policy")
                            .font(.displaySmall).foregroundStyle(.textPrimary)
                        Text("Last updated: March 2026")
                            .font(.captionLarge).foregroundStyle(.textSecondary)
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(Color.white.opacity(0.25))
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.md)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.lg) {
                        ForEach(privacySections, id: \.title) { section in
                            PrivacySection(icon: section.icon, iconColor: section.color,
                                           title: section.title, text: section.text)
                        }
                        Spacer(minLength: Spacing.xxl)
                    }
                    .padding(.horizontal, Spacing.md)
                }
            }
        }
    }

    struct PolicySection { let icon: String; let color: Color; let title: String; let text: String }

    var privacySections: [PolicySection] { [
        PolicySection(icon: "info.circle.fill",    color: .hydrationBlue,
                      title: "What We Collect",
                      text: "Hydrio stores all data locally on your device only. This includes your hydration logs, profile information (weight, gender, activity level), pet progress, and achievement data. We do not collect or transmit any personal data to external servers."),

        PolicySection(icon: "lock.shield.fill",    color: Color(hex: "4CAF50"),
                      title: "Data Storage",
                      text: "All data is saved using Apple's UserDefaults and is stored exclusively on your iPhone. Your data is protected by your device's built-in security, including Face ID and Passcode encryption when your device is locked."),

        PolicySection(icon: "shareplay",           color: Color(hex: "9C27B0"),
                      title: "Third-Party Sharing",
                      text: "We do not sell, trade, or transfer your personal information to any third parties. Hydrio shows ads through Google AdMob unless you purchase Remove Ads; AdMob may use device identifiers to serve ads, subject to your consent and App Tracking Transparency choice."),

        PolicySection(icon: "heart.fill",          color: Color(hex: "FF5252"),
                      title: "Apple Health",
                      text: "If you grant permission, Hydrio can read and write water intake data to Apple Health. This integration is entirely optional. You can revoke access at any time via iPhone Settings → Privacy & Security → Health → Hydrio."),

        PolicySection(icon: "bell.fill",           color: Color(hex: "FF9800"),
                      title: "Notifications",
                      text: "Hydration reminders are sent as local notifications — they are generated on-device and do not require an internet connection. No notification data is sent to our servers."),

        PolicySection(icon: "envelope.fill",       color: .goldPrimary,
                      title: "Contact Us",
                      text: "If you have any questions or concerns about this Privacy Policy, please contact us at Manhcuong531@gmail.com. We are committed to addressing your concerns promptly."),
    ] }
}

struct PrivacySection: View {
    let icon: String
    let iconColor: Color
    let title: String
    let text: String

    var body: some View {
        GlassCard(padding: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(iconColor.opacity(0.15))
                            .frame(width: 34, height: 34)
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(iconColor)
                    }
                    Text(title)
                        .font(.titleSmall).foregroundStyle(.textPrimary)
                }
                Text(text)
                    .font(.bodySmall).foregroundStyle(.textSecondary)
                    .lineSpacing(4)
            }
        }
    }
}

// MARK: - Safari Sheet (in-app browser)

struct SafariSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let vc = SFSafariViewController(url: url)
        vc.preferredControlTintColor = UIColor(Color.goldPrimary)
        vc.preferredBarTintColor = UIColor(Color(hex: "0B0B0B"))
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - Shared Helpers

struct SettingsDivider: View {
    var body: some View {
        Divider().background(Color.white.opacity(0.07))
    }
}

// MARK: - Notifications Section

// MARK: - Notification Window Section

struct NotificationWindowSection: View {
    @ObservedObject var window: NotificationWindowManager
    let isEnabled: Bool
    let onWindowChange: () -> Void

    // Bindings that read/write NotificationWindowManager via Date
    private var morningBinding: Binding<Date> {
        Binding(
            get: { window.morningDate },
            set: { date in
                let cal = Calendar.current
                window.morningHour   = cal.component(.hour,   from: date)
                window.morningMinute = cal.component(.minute, from: date)
                // Ensure morning doesn't exceed evening
                if window.morningHour * 60 + window.morningMinute >
                   window.eveningHour * 60 + window.eveningMinute {
                    window.morningHour   = window.eveningHour
                    window.morningMinute = window.eveningMinute
                }
                onWindowChange()
            }
        )
    }

    private var eveningBinding: Binding<Date> {
        Binding(
            get: { window.eveningDate },
            set: { date in
                let cal = Calendar.current
                window.eveningHour   = cal.component(.hour,   from: date)
                window.eveningMinute = cal.component(.minute, from: date)
                // Ensure evening doesn't precede morning
                if window.eveningHour * 60 + window.eveningMinute <
                   window.morningHour * 60 + window.morningMinute {
                    window.eveningHour   = window.morningHour
                    window.eveningMinute = window.morningMinute
                }
                onWindowChange()
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Section header
            HStack(spacing: Spacing.sm) {
                Image(systemName: "clock.badge.fill")
                    .font(.captionLarge).foregroundStyle(.goldPrimary)
                Text("NOTIFICATION SCHEDULE")
                    .font(.captionLarge).fontWeight(.semibold).foregroundStyle(.textSecondary)
            }
            .padding(.horizontal, Spacing.md)

            GlassCard(padding: Spacing.md) {
                VStack(spacing: 0) {
                    // Description
                    HStack(alignment: .top, spacing: Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.hydrationBlue.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: "moon.zzz.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.hydrationBlue)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Safe Delivery Window")
                                .font(.bodyMedium).foregroundStyle(.textPrimary)
                            Text("Reminders only fire between your start and end times. No night-time interruptions.")
                                .font(.captionLarge).foregroundStyle(.textSecondary)
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    SettingsDivider().padding(.vertical, Spacing.sm)

                    // Morning Start
                    windowRow(
                        icon: "sunrise.fill",
                        iconColor: Color(hex: "FF9500"),
                        label: "Morning Start",
                        binding: morningBinding
                    )

                    SettingsDivider().padding(.vertical, Spacing.xs)

                    // Evening End
                    windowRow(
                        icon: "moon.fill",
                        iconColor: Color(hex: "5E5CE6"),
                        label: "Evening End",
                        binding: eveningBinding
                    )
                }
            }
            .padding(.horizontal, Spacing.md)
        }
    }

    @ViewBuilder
    private func windowRow(
        icon: String,
        iconColor: Color,
        label: String,
        binding: Binding<Date>
    ) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            Text(label)
                .font(.bodyMedium).foregroundStyle(.textPrimary)
            Spacer()

            DatePicker("", selection: binding, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(.goldPrimary)
                .colorScheme(.dark)
        }
    }
}

// MARK: - Notifications Section

struct NotificationsSection: View {
    @Binding var enabled: Bool
    @Binding var interval: ReminderInterval
    let authStatus: UNAuthorizationStatus
    let onToggle: (Bool) -> Void
    let onIntervalChange: (ReminderInterval) -> Void

    private let intervals: [ReminderInterval] = [.thirtyMinutes, .oneHour, .twoHours, .threeHours]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Section header
            HStack(spacing: Spacing.sm) {
                Image(systemName: "bell.badge.fill")
                    .font(.captionLarge).foregroundStyle(.goldPrimary)
                Text("NOTIFICATIONS")
                    .font(.captionLarge).fontWeight(.semibold).foregroundStyle(.textSecondary)
            }
            .padding(.horizontal, Spacing.md)

            GlassCard(padding: Spacing.md) {
                VStack(spacing: 0) {
                    // Master toggle
                    HStack(spacing: Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(enabled ? Color.goldPrimary.opacity(0.15) : Color.white.opacity(0.07))
                                .frame(width: 36, height: 36)
                            Image(systemName: enabled ? "bell.fill" : "bell.slash.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(enabled ? .goldPrimary : .textSecondary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hydration Reminders")
                                .font(.bodyMedium).foregroundStyle(.textPrimary)
                            Text(enabled ? "Reminders are active" : "No reminders scheduled")
                                .font(.captionLarge).foregroundStyle(.textSecondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { enabled },
                            set: { onToggle($0) }
                        ))
                        .labelsHidden()
                        .tint(.goldPrimary)
                    }

                    // Permission denied warning
                    if authStatus == .denied {
                        SettingsDivider().padding(.vertical, Spacing.xs)
                        HStack(spacing: Spacing.md) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Notifications Blocked")
                                    .font(.titleSmall).foregroundStyle(.textPrimary)
                                Text("Enable notifications for Hydrio in iOS Settings.")
                                    .font(.captionLarge).foregroundStyle(.textSecondary)
                            }
                            Spacer()
                            Button {
                                NotificationManager.shared.openSystemSettings()
                            } label: {
                                Text("Open Settings")
                                    .font(.captionLarge).fontWeight(.semibold)
                                    .foregroundStyle(Color(hex: "0B0B0B"))
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, 6)
                                    .background(LinearGradient.goldGradient)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.vertical, Spacing.xs)
                        .padding(Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.sm).fill(Color.orange.opacity(0.08))
                                .overlay(RoundedRectangle(cornerRadius: Radius.sm)
                                    .strokeBorder(Color.orange.opacity(0.25), lineWidth: 1))
                        )
                    }

                    // Interval picker — only when enabled + authorized
                    if enabled && authStatus != .denied {
                        SettingsDivider().padding(.vertical, Spacing.xs)

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack(spacing: 6) {
                                Image(systemName: "clock.fill")
                                    .font(.captionLarge).foregroundStyle(.textSecondary)
                                Text("REMIND ME EVERY")
                                    .font(.captionLarge).fontWeight(.semibold).foregroundStyle(.textSecondary)
                            }

                            VStack(spacing: Spacing.xs) {
                                ForEach(intervals, id: \.self) { item in
                                    Button { onIntervalChange(item) } label: {
                                        HStack(spacing: Spacing.md) {
                                            ZStack {
                                                Circle()
                                                    .stroke(interval == item ? Color.goldPrimary : Color.white.opacity(0.2), lineWidth: 1.5)
                                                    .frame(width: 20, height: 20)
                                                if interval == item {
                                                    Circle().fill(Color.goldPrimary).frame(width: 11, height: 11)
                                                }
                                            }
                                            Text(item.displayName)
                                                .font(.bodyMedium)
                                                .foregroundStyle(interval == item ? .textPrimary : .textSecondary)
                                            Spacer()
                                            if interval == item {
                                                Text("Active")
                                                    .font(.captionSmall).fontWeight(.semibold)
                                                    .foregroundStyle(.goldPrimary)
                                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                                    .background(Color.goldPrimary.opacity(0.12))
                                                    .clipShape(Capsule())
                                            }
                                        }
                                        .padding(.vertical, Spacing.sm)
                                        .padding(.horizontal, Spacing.sm)
                                        .background(
                                            RoundedRectangle(cornerRadius: Radius.sm)
                                                .fill(interval == item
                                                      ? Color.goldPrimary.opacity(0.07)
                                                      : Color.clear)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .animation(.spring(response: 0.38, dampingFraction: 0.82), value: enabled)
            .animation(.spring(response: 0.38, dampingFraction: 0.82), value: authStatus)
        }
    }
}

// MARK: - Settings Components

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content

    init(title: String, icon: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title; self.icon = icon; self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.captionLarge).foregroundStyle(.goldPrimary)
                Text(title.uppercased())
                    .font(.captionLarge).fontWeight(.semibold).foregroundStyle(.textSecondary)
            }
            .padding(.horizontal, Spacing.md)

            GlassCard(padding: Spacing.md) { content() }
                .padding(.horizontal, Spacing.md)
        }
    }
}

// MARK: - Settings Field

struct SettingsField<Content: View>: View {
    let label: String
    let content: () -> Content

    init(label: String, @ViewBuilder content: @escaping () -> Content) {
        self.label = label; self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label).font(.captionLarge).foregroundStyle(.textSecondary)
            content()
        }
    }
}
