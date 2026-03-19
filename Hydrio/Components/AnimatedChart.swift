import SwiftUI

struct WeeklyBarChart: View {
    let data: [DayData]
    var maxHeight: CGFloat = 120

    @State private var animated = false

    var maxValue: Double { max(data.map { $0.amountML }.max() ?? 1, 1) }

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(data) { day in
                VStack(spacing: 4) {
                    // Value label on top of bar
                    if day.amountML > 0 {
                        Text(day.displayAmount)
                            .font(.captionSmall)
                            .foregroundStyle(.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .opacity(animated ? 1 : 0)
                    }

                    ZStack(alignment: .bottom) {
                        // Background track
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                            .frame(height: maxHeight)

                        // Fill bar
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(
                                day.isGoalMet
                                    ? LinearGradient(colors: [.goldPrimary, .goldSecondary],
                                                     startPoint: .bottom, endPoint: .top)
                                    : LinearGradient(colors: [.hydrationBlueDim, .hydrationBlue],
                                                     startPoint: .bottom, endPoint: .top)
                            )
                            .frame(
                                height: animated
                                    ? max(4, CGFloat(day.amountML / maxValue) * maxHeight)
                                    : 4
                            )
                            .shadow(
                                color: day.isGoalMet ? Color.goldPrimary.opacity(0.3) : Color.hydrationBlue.opacity(0.3),
                                radius: 4
                            )
                    }

                    Text(day.shortDayLabel)
                        .font(.captionSmall)
                        .foregroundStyle(Calendar.current.isDateInToday(day.date) ? .hydrationBlue : .textTertiary)
                        .fontWeight(Calendar.current.isDateInToday(day.date) ? .semibold : .regular)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                animated = true
            }
        }
    }
}

struct MonthlyTrendChart: View {
    let data: [DayData]
    var height: CGFloat = 100

    @State private var animated = false

    var maxValue: Double { max(data.map { $0.amountML }.max() ?? 1, 1) }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = height

            ZStack {
                // Goal line
                if let first = data.first {
                    let goalY = h - CGFloat(first.goalML / maxValue) * h
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: goalY))
                        path.addLine(to: CGPoint(x: w, y: goalY))
                    }
                    .stroke(Color.goldPrimary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }

                // Area fill
                if data.count > 1 {
                    Path { path in
                        let step = w / CGFloat(data.count - 1)
                        path.move(to: CGPoint(x: 0, y: h))
                        for (i, d) in data.enumerated() {
                            let x = CGFloat(i) * step
                            let y = animated ? h - CGFloat(d.amountML / maxValue) * h : h
                            if i == 0 { path.addLine(to: CGPoint(x: x, y: y)) }
                            else       { path.addLine(to: CGPoint(x: x, y: y)) }
                        }
                        path.addLine(to: CGPoint(x: w, y: h))
                        path.closeSubpath()
                    }
                    .fill(LinearGradient(
                        colors: [Color.hydrationBlue.opacity(0.3), Color.hydrationBlue.opacity(0)],
                        startPoint: .top, endPoint: .bottom
                    ))

                    // Line
                    Path { path in
                        let step = w / CGFloat(data.count - 1)
                        for (i, d) in data.enumerated() {
                            let x = CGFloat(i) * step
                            let y = animated ? h - CGFloat(d.amountML / maxValue) * h : h
                            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                            else       { path.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }
                    .stroke(Color.hydrationBlue, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .shadow(color: Color.hydrationBlue.opacity(0.4), radius: 4)
                }
            }
        }
        .frame(height: height)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) { animated = true }
        }
    }
}
