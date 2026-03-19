import Foundation

struct DrinkEntry: Identifiable, Codable {
    let id: UUID
    let amountML: Double
    let date: Date
    let drinkType: DrinkType
    let note: String?

    init(id: UUID = UUID(), amountML: Double, date: Date = Date(),
         drinkType: DrinkType = .water, note: String? = nil) {
        self.id = id
        self.amountML = amountML
        self.date = date
        self.drinkType = drinkType
        self.note = note
    }

    var effectiveML: Double { amountML * drinkType.hydrationFactor }

    var timeString: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }

    var displayAmount: String {
        amountML >= 1000
            ? String(format: "%.1fL", amountML / 1000)
            : "\(Int(amountML))ml"
    }

    var hour: Int { Calendar.current.component(.hour, from: date) }
}
