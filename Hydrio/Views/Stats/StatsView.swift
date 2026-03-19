import SwiftUI

struct StatsView: View {
    @EnvironmentObject var vm: HydrationViewModel
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.lg) {

                    // Header
                    HStack {
                        Text("Statistics")
                            .font(.displaySmall).foregroundStyle(.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)

                    // Summary stat cards
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: Spacing.sm),
                                  GridItem(.flexible(), spacing: Spacing.sm)],
                        spacing: Spacing.sm
                    ) {
                        StatCard(
                            title: "Weekly Average",
                            value: vm.stats.weeklyAverage >= 1000
                                ? String(format: "%.1fL", vm.stats.weeklyAverage / 1000)
                                : "\(Int(vm.stats.weeklyAverage))ml",
                            icon: "chart.bar.fill",
                            iconColor: .hydrationBlue
                        )
                        StatCard(
                            title: "Current Streak",
                            value: "\(vm.stats.currentStreak) days",
                            subtitle: vm.stats.currentStreak > 0 ? "Keep it up!" : nil,
                            icon: "flame.fill",
                            iconColor: .orange,
                            accentColor: .orange
                        )
                        StatCard(
                            title: "Best Day",
                            value: vm.stats.bestDay >= 1000
                                ? String(format: "%.1fL", vm.stats.bestDay / 1000)
                                : "\(Int(vm.stats.bestDay))ml",
                            icon: "star.fill",
                            iconColor: .goldPrimary,
                            accentColor: .goldPrimary
                        )
                        StatCard(
                            title: "Longest Streak",
                            value: "\(vm.stats.longestStreak) days",
                            icon: "crown.fill",
                            iconColor: .goldPrimary,
                            accentColor: .goldPrimary
                        )
                    }
                    .padding(.horizontal, Spacing.md)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: appeared)

                    // Weekly bar chart
                    GlassCard {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("This Week").font(.titleMedium).foregroundStyle(.textPrimary)
                                    Text("Daily intake vs goal").font(.captionLarge).foregroundStyle(.textSecondary)
                                }
                                Spacer()
                                HStack(spacing: Spacing.md) {
                                    LegendDot(color: .hydrationBlue, label: "Intake")
                                    LegendDot(color: .goldPrimary, label: "Goal met")
                                }
                            }
                            if vm.stats.weeklyData.isEmpty {
                                Text("No data yet").font(.bodyMedium).foregroundStyle(.textTertiary)
                                    .frame(maxWidth: .infinity, minHeight: 120)
                            } else {
                                WeeklyBarChart(data: vm.stats.weeklyData, maxHeight: 120)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)

                    // Monthly trend chart
                    GlassCard {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("30-Day Trend").font(.titleMedium).foregroundStyle(.textPrimary)
                                Text("Monthly hydration pattern").font(.captionLarge).foregroundStyle(.textSecondary)
                            }
                            if vm.stats.monthlyData.isEmpty {
                                Text("No data yet").font(.bodyMedium).foregroundStyle(.textTertiary)
                                    .frame(maxWidth: .infinity, minHeight: 100)
                            } else {
                                MonthlyTrendChart(data: vm.stats.monthlyData, height: 100)
                            }
                            // Month labels
                            HStack {
                                Text("30 days ago").font(.captionSmall).foregroundStyle(.textTertiary)
                                Spacer()
                                Text("Today").font(.captionSmall).foregroundStyle(.textTertiary)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: appeared)

                    // Weekly breakdown
                    if !vm.stats.weeklyData.isEmpty {
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Week Breakdown").font(.titleMedium).foregroundStyle(.textPrimary)
                                ForEach(vm.stats.weeklyData.reversed()) { day in
                                    WeekDayRow(day: day, goalML: vm.goal.dailyGoalML)
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.4), value: appeared)
                    }

                    // Pet stats
                    GlassCard {
                        HStack(spacing: Spacing.md) {
                            PetCharacterView(pet: vm.pet, size: 70)
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text(vm.pet.name).font(.titleMedium).foregroundStyle(.textPrimary)
                                Text("Stage: \(vm.pet.stageEmoji) \(vm.pet.stageName)")
                                    .font(.bodySmall).foregroundStyle(.textSecondary)
                                Text("XP: \(vm.pet.xp)").font(.bodySmall).foregroundStyle(.textSecondary)
                                // Progress bar
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.white.opacity(0.1)).frame(height: 6)
                                        Capsule()
                                            .fill(LinearGradient(colors: [Color(hex: "4CAF50"), .goldPrimary],
                                                                 startPoint: .leading, endPoint: .trailing))
                                            .frame(width: geo.size.width * vm.pet.stageProgress, height: 6)
                                    }
                                }
                                .frame(height: 6)
                                Text("\(vm.pet.stageName) → \(vm.pet.growthStage.next.map { vm.pet.type.stageName($0) } ?? "Max level")")
                                    .font(.captionSmall).foregroundStyle(.textTertiary)
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, Spacing.md)

                    Spacer(minLength: 120)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { appeared = true }
        }
    }
}

struct LegendDot: View {
    let color: Color; let label: String
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.captionSmall).foregroundStyle(.textSecondary)
        }
    }
}

struct WeekDayRow: View {
    let day: DayData
    let goalML: Double

    var body: some View {
        HStack(spacing: Spacing.md) {
            Text(day.dayLabel)
                .font(.bodySmall).foregroundStyle(Calendar.current.isDateInToday(day.date) ? .hydrationBlue : .textSecondary)
                .frame(width: 36, alignment: .leading)
                .fontWeight(Calendar.current.isDateInToday(day.date) ? .semibold : .regular)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.07)).frame(height: 8)
                    Capsule()
                        .fill(day.isGoalMet ? LinearGradient.goldGradient
                              : LinearGradient(colors: [.hydrationBlueDim, .hydrationBlue], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * day.progress, height: 8)
                }
            }
            .frame(height: 8)

            Text(day.displayAmount)
                .font(.captionLarge).foregroundStyle(day.isGoalMet ? .goldPrimary : .textSecondary)
                .frame(width: 48, alignment: .trailing)

            if day.isGoalMet {
                Image(systemName: "checkmark.circle.fill").font(.captionLarge).foregroundStyle(.goldPrimary)
            }
        }
        .frame(height: 28)
    }
}
