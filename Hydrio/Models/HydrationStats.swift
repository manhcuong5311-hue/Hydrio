import Foundation

struct DayData: Identifiable, Codable {
    let id: UUID
    let date: Date
    let amountML: Double
    let goalML: Double

    init(id: UUID = UUID(), date: Date, amountML: Double, goalML: Double) {
        self.id = id; self.date = date
        self.amountML = amountML; self.goalML = goalML
    }

    var progress: Double { goalML > 0 ? min(amountML / goalML, 1.0) : 0 }
    var isGoalMet: Bool { amountML >= goalML }

    var dayLabel: String {
        let f = DateFormatter(); f.dateFormat = "EEE"
        return f.string(from: date)
    }
    var shortDayLabel: String {
        let f = DateFormatter(); f.dateFormat = "EEEEE"
        return f.string(from: date)
    }
    var displayAmount: String {
        amountML >= 1000
            ? String(format: "%.1fL", amountML / 1000)
            : "\(Int(amountML))ml"
    }
}

struct HydrationStats {
    var weeklyAverage:  Double  = 0
    var currentStreak:  Int     = 0
    var longestStreak:  Int     = 0
    var bestDay:        Double  = 0
    var totalDaysTracked: Int   = 0
    var weeklyData:  [DayData]  = []
    var monthlyData: [DayData]  = []
}
