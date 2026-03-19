import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var vm: HydrationViewModel
    @State private var selectedCategory: AchievementCategory? = nil
    @State private var appeared = false

    var filtered: [Achievement] {
        guard let cat = selectedCategory else { return vm.achievements }
        return vm.achievements.filter { $0.category == cat }
    }

    var unlockedCount: Int { vm.achievements.filter { $0.isUnlocked }.count }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.lg) {

                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Achievements")
                                .font(.displaySmall).foregroundStyle(.textPrimary)
                            Text("\(unlockedCount) of \(vm.achievements.count) unlocked")
                                .font(.bodyMedium).foregroundStyle(.textSecondary)
                        }
                        Spacer()
                        // Overall progress ring
                        ZStack {
                            Circle().stroke(Color.white.opacity(0.08), lineWidth: 4).frame(width: 52, height: 52)
                            Circle()
                                .trim(from: 0, to: Double(unlockedCount) / Double(max(vm.achievements.count, 1)))
                                .stroke(LinearGradient.goldGradient,
                                        style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 52, height: 52)
                                .rotationEffect(.degrees(-90))
                            Text("\(Int(Double(unlockedCount) / Double(max(vm.achievements.count, 1)) * 100))%")
                                .font(.captionSmall).foregroundStyle(.goldPrimary).fontWeight(.bold)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)
                    .opacity(appeared ? 1 : 0)

                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.sm) {
                            CategoryChip(title: "All", isSelected: selectedCategory == nil, color: .hydrationBlue) {
                                withAnimation { selectedCategory = nil }
                            }
                            ForEach(AchievementCategory.allCases, id: \.self) { cat in
                                CategoryChip(title: cat.displayName, isSelected: selectedCategory == cat, color: cat.color) {
                                    withAnimation { selectedCategory = selectedCategory == cat ? nil : cat }
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                    .opacity(appeared ? 1 : 0)

                    // Recently unlocked
                    let recent = vm.achievements.filter { $0.isUnlocked }.sorted { ($0.unlockedDate ?? .distantPast) > ($1.unlockedDate ?? .distantPast) }.prefix(3)
                    if !recent.isEmpty && selectedCategory == nil {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Recently Unlocked")
                                .font(.titleSmall).foregroundStyle(.textPrimary)
                                .padding(.horizontal, Spacing.md)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.lg) {
                                    ForEach(recent) { ach in
                                        AchievementBadge(achievement: ach, size: 72)
                                    }
                                }
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
                    }

                    // Grid of achievements
                    let columns = [GridItem(.flexible(), spacing: Spacing.md),
                                   GridItem(.flexible(), spacing: Spacing.md),
                                   GridItem(.flexible(), spacing: Spacing.md)]
                    LazyVGrid(columns: columns, spacing: Spacing.lg) {
                        ForEach(filtered) { ach in
                            AchievementBadge(achievement: ach, size: 64)
                                .opacity(appeared ? 1 : 0)
                                .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)
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

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.captionLarge).fontWeight(.semibold)
                .foregroundStyle(isSelected ? Color(hex: "0B0B0B") : color)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs + 2)
                .background(isSelected ? AnyView(color) : AnyView(color.opacity(0.12)))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(isSelected ? Color.clear : color.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

extension AchievementCategory: CaseIterable {
    public static var allCases: [AchievementCategory] { [.beginner, .streak, .goal, .habit] }
}
