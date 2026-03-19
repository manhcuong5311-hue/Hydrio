import SwiftUI

struct HomeView: View {
    @EnvironmentObject var vm: HydrationViewModel
    @EnvironmentObject var premiumManager: PremiumManager
    @State private var showGoalBanner = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient.backgroundGradient.ignoresSafeArea()

            // Subtle radial glow at top
            RadialGradient(
                colors: [Color.hydrationBlue.opacity(0.08), Color.clear],
                center: .top, startRadius: 0, endRadius: 350
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.lg) {

                    // MARK: Header
                    HomeHeaderView()

                    // MARK: Hydration Ring + Pet
                    HStack(alignment: .center, spacing: Spacing.lg) {
                        HydrationRing(
                            progress: vm.todayProgress,
                            currentML: vm.todayTotal,
                            goalML: vm.goal.dailyGoalML,
                            size: 200,
                            lineWidth: 18
                        )

                        // Pet companion
                        VStack(spacing: Spacing.sm) {
                            PetCharacterView(pet: vm.pet, size: 90)
                            Text(vm.pet.name)
                                .font(.captionLarge).fontWeight(.semibold)
                                .foregroundStyle(.textPrimary)
                            Text(vm.pet.happinessEmoji + " " + vm.pet.happinessDescription)
                                .font(.captionSmall)
                                .foregroundStyle(.textSecondary)
                            // Pet XP bar
                            VStack(spacing: 2) {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.white.opacity(0.08)).frame(height: 4)
                                        Capsule()
                                            .fill(LinearGradient(
                                                colors: [Color(hex: "4CAF50"), Color(hex: "81C784")],
                                                startPoint: .leading, endPoint: .trailing))
                                            .frame(width: geo.size.width * vm.pet.stageProgress, height: 4)
                                    }
                                }
                                .frame(height: 4)
                                Text(vm.pet.stageName)
                                    .font(.captionSmall).foregroundStyle(.textTertiary)
                            }
                            .frame(width: 80)
                        }
                    }
                    .padding(.vertical, Spacing.sm)

                    // MARK: Coach Insight
                    CoachInsightCard()

                    // MARK: Quick Add
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Quick Add")
                            .font(.titleSmall).foregroundStyle(.textPrimary)
                            .padding(.horizontal, Spacing.md)

                        HStack(spacing: Spacing.sm) {
                            ForEach([100, 250, 500], id: \.self) { amount in
                                QuickAddButton(amount: amount) {
                                    vm.addDrink(amountML: Double(amount))
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.md)

                        // Custom add row
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.sm) {
                                ForEach(DrinkType.allCases) { type in
                                    DrinkTypeChip(type: type) {
                                        vm.addDrink(amountML: 250, type: type)
                                    }
                                }
                            }
                            .padding(.horizontal, Spacing.md)
                        }
                    }

                    // MARK: Today's Timeline
                    TodayTimelineView()

                    Spacer(minLength: 160) // room for FAB + undo toast
                }
                .padding(.top, Spacing.sm)
            }

            // Goal reached banner
            if showGoalBanner {
                VStack {
                    GoalReachedBanner { withAnimation { showGoalBanner = false } }
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .onAppear {
            // Trigger the daily premium wall when the user opens the home screen.
            // This fires once per day for free users (after a meaningful screen view).
            premiumManager.triggerWallIfNeeded()
        }
        .onChange(of: vm.showGoalReached) { _, reached in
            if reached {
                withAnimation(.spring()) { showGoalBanner = true }
                vm.showGoalReached = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    withAnimation { showGoalBanner = false }
                }
            }
        }
    }
}

// MARK: - Header

struct HomeHeaderView: View {
    @EnvironmentObject var vm: HydrationViewModel

    var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        let base: String
        switch h {
        case 5..<12: base = "Good morning"
        case 12..<17: base = "Good afternoon"
        default:      base = "Good evening"
        }
        if vm.profile.name.isEmpty { return base }
        return "\(base), \(vm.profile.name)"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Stay hydrated today")
                    .font(.bodyMedium).foregroundStyle(.textSecondary)
                Text(greeting)
                    .font(.displaySmall).foregroundStyle(.textPrimary)
            }
            Spacer()
            // Streak badge
            if vm.stats.currentStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.bodyMedium).foregroundStyle(.orange)
                    Text("\(vm.stats.currentStreak)")
                        .font(.titleSmall).foregroundStyle(.textPrimary)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(
                    Capsule().fill(Color.orange.opacity(0.12))
                        .overlay(Capsule().strokeBorder(Color.orange.opacity(0.3), lineWidth: 1))
                )
            }
        }
        .padding(.horizontal, Spacing.md)
    }
}

// MARK: - Coach Insight

struct CoachInsightCard: View {
    @EnvironmentObject var vm: HydrationViewModel

    var body: some View {
        GoldCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack(spacing: Spacing.sm) {
                    ZStack {
                        Circle().fill(Color.hydrationBlue.opacity(0.15)).frame(width: 36, height: 36)
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.hydrationBlue)
                    }
                    Text("AI Coach").font(.captionLarge).fontWeight(.semibold)
                        .foregroundStyle(.goldPrimary).textCase(.uppercase)
                    Spacer()
                    // Progress pill
                    Text("\(Int(vm.todayProgress * 100))%")
                        .font(.captionLarge).fontWeight(.bold)
                        .foregroundStyle(vm.todayProgress >= 1 ? .goldPrimary : .hydrationBlue)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(
                            Capsule().fill(vm.todayProgress >= 1
                                ? Color.goldPrimary.opacity(0.15)
                                : Color.hydrationBlue.opacity(0.15))
                        )
                }

                // Main message
                Text(vm.coachMessage)
                    .font(.bodyMedium).foregroundStyle(.textPrimary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Divider().background(Color.white.opacity(0.08))

                // Contextual tip
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.textSecondary)
                        .padding(.top, 2)
                    Text(vm.coachTip)
                        .font(.bodySmall).foregroundStyle(.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }
}

// MARK: - Drink Type Chip

struct DrinkTypeChip: View {
    let type: DrinkType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: type.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(type.color)
                Text(type.displayName)
                    .font(.captionLarge).foregroundStyle(.textPrimary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                Capsule().fill(type.color.opacity(0.1))
                    .overlay(Capsule().strokeBorder(type.color.opacity(0.3), lineWidth: 1))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Today Timeline

struct TodayTimelineView: View {
    @EnvironmentObject var vm: HydrationViewModel
    @State private var editingEntry: DrinkEntry? = nil
    @State private var showAll = false

    private var visibleEntries: [DrinkEntry] {
        showAll ? vm.todayEntries : Array(vm.todayEntries.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Today's Log")
                    .font(.titleSmall).foregroundStyle(.textPrimary)
                Spacer()
                Text("\(vm.todayEntries.count) entries")
                    .font(.captionLarge).foregroundStyle(.textSecondary)
            }
            .padding(.horizontal, Spacing.md)

            if vm.todayEntries.isEmpty {
                GlassCard {
                    HStack {
                        Spacer()
                        VStack(spacing: Spacing.sm) {
                            Image(systemName: "drop").font(.system(size: 32)).foregroundStyle(.textTertiary)
                            Text("No drinks logged today").font(.bodyMedium).foregroundStyle(.textSecondary)
                            Text("Tap + to log your first drink").font(.captionLarge).foregroundStyle(.textTertiary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, Spacing.lg)
                }
                .padding(.horizontal, Spacing.md)
            } else {
                VStack(spacing: Spacing.xs) {
                    ForEach(visibleEntries) { entry in
                        DrinkEntryRow(entry: entry)
                            .contentShape(Rectangle())
                            .onTapGesture { editingEntry = entry }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation { vm.removeDrink(entry) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding(.horizontal, Spacing.md)

                if vm.todayEntries.count > 5 {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showAll.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(showAll ? "Show less" : "Show \(vm.todayEntries.count - 5) more")
                                .font(.captionLarge)
                            Image(systemName: showAll ? "chevron.up" : "chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(.textSecondary)
                    }
                    .padding(.horizontal, Spacing.md)
                }
            }
        }
        .sheet(item: $editingEntry) { entry in
            EditDrinkSheet(entry: entry) { newAmount in
                vm.editDrink(entry, newAmountML: newAmount)
            }
        }
    }
}

struct DrinkEntryRow: View {
    let entry: DrinkEntry

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle().fill(entry.drinkType.color.opacity(0.15)).frame(width: 40, height: 40)
                Image(systemName: entry.drinkType.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(entry.drinkType.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.drinkType.displayName).font(.titleSmall).foregroundStyle(.textPrimary)
                Text(entry.timeString).font(.captionLarge).foregroundStyle(.textSecondary)
            }
            Spacer()
            Text(entry.displayAmount).font(.titleSmall).foregroundStyle(.hydrationBlue)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }
}

// MARK: - Edit Drink Sheet

struct EditDrinkSheet: View {
    let entry: DrinkEntry
    let onSave: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amountML: Double

    init(entry: DrinkEntry, onSave: @escaping (Double) -> Void) {
        self.entry = entry
        self.onSave = onSave
        _amountML = State(initialValue: entry.amountML)
    }

    private var displayAmount: String {
        amountML >= 1000
            ? String(format: "%.1fL", amountML / 1000)
            : "\(Int(amountML))ml"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: Spacing.xl) {
                    // Drink icon
                    ZStack {
                        Circle()
                            .fill(entry.drinkType.color.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: entry.drinkType.icon)
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(entry.drinkType.color)
                    }
                    .padding(.top, Spacing.lg)

                    // Amount display
                    VStack(spacing: Spacing.xs) {
                        Text(displayAmount)
                            .font(.numberLarge)
                            .foregroundStyle(.textPrimary)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3), value: amountML)
                        Text(entry.drinkType.displayName + " · " + entry.timeString)
                            .font(.bodyMedium)
                            .foregroundStyle(.textSecondary)
                    }

                    // Slider
                    VStack(spacing: Spacing.sm) {
                        Slider(value: $amountML, in: 50...1500, step: 10)
                            .tint(.hydrationBlue)
                            .padding(.horizontal, Spacing.md)

                        HStack {
                            Text("50ml").font(.captionSmall).foregroundStyle(.textTertiary)
                            Spacer()
                            Text("1500ml").font(.captionSmall).foregroundStyle(.textTertiary)
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                    .padding(Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.md).fill(Color.white.opacity(0.04))
                    )
                    .padding(.horizontal, Spacing.md)

                    // Quick presets
                    HStack(spacing: Spacing.sm) {
                        ForEach([150, 250, 330, 500], id: \.self) { preset in
                            Button {
                                withAnimation(.spring(response: 0.3)) { amountML = Double(preset) }
                            } label: {
                                Text("\(preset)ml")
                                    .font(.captionLarge).fontWeight(.semibold)
                                    .foregroundStyle(Int(amountML) == preset ? Color(hex: "0B0B0B") : .textSecondary)
                                    .padding(.horizontal, Spacing.md)
                                    .padding(.vertical, Spacing.sm)
                                    .background(
                                        Capsule().fill(Int(amountML) == preset
                                                       ? AnyShapeStyle(LinearGradient.goldGradient)
                                                       : AnyShapeStyle(Color.white.opacity(0.07)))
                                    )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }

                    Spacer()

                    // Save button
                    PrimaryButton("Save Changes", icon: "checkmark") {
                        onSave(amountML)
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        dismiss()
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.textSecondary)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Goal Reached Banner

struct GoalReachedBanner: View {
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            Text("🎉").font(.system(size: 32))
            VStack(alignment: .leading, spacing: 2) {
                Text("Goal Reached!").font(.titleMedium).foregroundStyle(.textPrimary)
                Text("Amazing work! You're fully hydrated.").font(.bodySmall).foregroundStyle(.textSecondary)
            }
            Spacer()
            Button(action: dismiss) {
                Image(systemName: "xmark.circle.fill").font(.titleMedium).foregroundStyle(.textSecondary)
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg)
                .fill(LinearGradient(colors: [Color.goldPrimary.opacity(0.2), Color.goldSecondary.opacity(0.1)],
                                     startPoint: .leading, endPoint: .trailing))
                .overlay(RoundedRectangle(cornerRadius: Radius.lg)
                    .strokeBorder(Color.goldPrimary.opacity(0.5), lineWidth: 1))
                .shadow(color: Color.goldPrimary.opacity(0.3), radius: 16)
        )
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
    }
}
