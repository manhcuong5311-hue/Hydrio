import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var vm: HydrationViewModel
    @EnvironmentObject var store: StoreManager
    @State private var selectedDate = Date()
    @State private var selectedMonth = Date()
    @State private var showHistoryPaywall = false

    private let calendar = Calendar.current

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.lg) {

                    // Header
                    HStack {
                        Text("History")
                            .font(.displaySmall).foregroundStyle(.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)

                    // Month calendar
                    MonthCalendarView(
                        selectedDate: $selectedDate,
                        selectedMonth: $selectedMonth,
                        vm: vm
                    )

                    // Selected day detail
                    SelectedDayDetailView(date: selectedDate)

                    Spacer(minLength: 120)
                }
            }
        }
        .sheet(isPresented: $showHistoryPaywall) {
            PremiumSheet().environmentObject(store)
        }
    }
}

// MARK: - Month Calendar

struct MonthCalendarView: View {
    @Binding var selectedDate: Date
    @Binding var selectedMonth: Date
    @ObservedObject var vm: HydrationViewModel

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    var daysInMonth: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: selectedMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstDay) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }

    var monthYearString: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: selectedMonth)
    }

    var body: some View {
        GlassCard(padding: Spacing.md) {
            VStack(spacing: Spacing.md) {
                // Month navigation
                HStack {
                    Button {
                        withAnimation(.easeInOut) {
                            selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.titleSmall).foregroundStyle(.textSecondary)
                    }
                    Spacer()
                    Text(monthYearString)
                        .font(.titleMedium).foregroundStyle(.textPrimary)
                    Spacer()
                    Button {
                        withAnimation(.easeInOut) {
                            selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.titleSmall)
                            .foregroundStyle(calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
                                             ? Color.textTertiary : Color.textSecondary)
                    }
                    .disabled(calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month))
                }

                // Weekday labels
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(weekdays, id: \.self) { d in
                        Text(d).font(.captionSmall).foregroundStyle(.textTertiary).frame(height: 24)
                    }
                }

                // Days grid
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, optDate in
                        if let date = optDate {
                            CalendarDayCell(
                                date: date,
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                isToday: calendar.isDateInToday(date),
                                total: vm.totalFor(date: date),
                                goal: vm.goal.dailyGoalML
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3)) { selectedDate = date }
                            }
                        } else {
                            Color.clear.frame(height: 36)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }
}

struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let total: Double
    let goal: Double

    private let calendar = Calendar.current

    var progress: Double { goal > 0 ? min(total / goal, 1.0) : 0 }
    var isFuture: Bool { date > Date() }

    var fillColor: Color {
        if isFuture { return .clear }
        if total <= 0 { return .clear }
        if total >= goal { return .goldPrimary }
        return .hydrationBlue
    }

    var body: some View {
        ZStack {
            // Progress fill
            if !isFuture && total > 0 {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(fillColor.opacity(0.4), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }

            // Selected ring
            if isSelected {
                Circle().strokeBorder(Color.white.opacity(0.5), lineWidth: 1.5)
            }

            // Today dot
            if isToday {
                Circle().fill(Color.hydrationBlue.opacity(0.2))
            }

            // Day number
            Text("\(calendar.component(.day, from: date))")
                .font(isToday ? .titleSmall : .bodySmall)
                .foregroundStyle(
                    isFuture ? Color.textTertiary
                    : isSelected ? Color.white
                    : isToday ? Color.hydrationBlue
                    : Color.textPrimary
                )
                .fontWeight(isToday || isSelected ? .bold : .regular)
        }
        .frame(width: 36, height: 36)
    }
}

// MARK: - Selected Day Detail

struct SelectedDayDetailView: View {
    @EnvironmentObject var vm: HydrationViewModel
    let date: Date

    var entries: [DrinkEntry] { vm.entriesFor(date: date) }
    var total: Double { vm.totalFor(date: date) }
    var progress: Double { vm.goal.dailyGoalML > 0 ? min(total / vm.goal.dailyGoalML, 1.0) : 0 }

    var displayDate: String {
        let f = DateFormatter()
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text(displayDate)
                    .font(.titleMedium).foregroundStyle(.textPrimary)
                Spacer()
                HStack(spacing: 4) {
                    ProgressRing(progress: progress, size: 28, lineWidth: 3,
                                 color: progress >= 1.0 ? .goldPrimary : .hydrationBlue)
                    Text(total >= 1000 ? String(format: "%.1fL", total/1000) : "\(Int(total))ml")
                        .font(.titleSmall)
                        .foregroundStyle(progress >= 1.0 ? .goldPrimary : .hydrationBlue)
                }
            }
            .padding(.horizontal, Spacing.md)

            if entries.isEmpty {
                GlassCard {
                    HStack {
                        Spacer()
                        VStack(spacing: Spacing.sm) {
                            Image(systemName: "drop").font(.system(size: 28)).foregroundStyle(.textTertiary)
                            Text("No drinks logged").font(.bodyMedium).foregroundStyle(.textTertiary)
                        }
                        .padding(.vertical, Spacing.lg)
                        Spacer()
                    }
                }
                .padding(.horizontal, Spacing.md)
            } else {
                VStack(spacing: Spacing.xs) {
                    ForEach(entries) { entry in
                        DrinkEntryRow(entry: entry)
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
        }
    }
}
