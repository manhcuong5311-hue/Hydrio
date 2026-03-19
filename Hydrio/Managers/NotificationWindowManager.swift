import Foundation
import Combine

// MARK: - Notification Window Manager

/// Manages the safe notification delivery window.
///
/// Default window: 08:00 – 21:00.
/// Free users are locked to this default.
/// Premium users can customise both the morning start and evening end times.
///
/// A shared singleton is used so HydrationViewModel can reach it without
/// requiring an injected dependency.
final class NotificationWindowManager: ObservableObject {

    // MARK: - Shared Instance

    static let shared = NotificationWindowManager()

    // MARK: - Default Values

    static let defaultMorningHour   = 8
    static let defaultMorningMinute = 0
    static let defaultEveningHour   = 21
    static let defaultEveningMinute = 0

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let morningHour   = "hydrio_notif_morning_hour"
        static let morningMinute = "hydrio_notif_morning_minute"
        static let eveningHour   = "hydrio_notif_evening_hour"
        static let eveningMinute = "hydrio_notif_evening_minute"
    }

    // MARK: - Published

    @Published var morningHour:   Int
    @Published var morningMinute: Int
    @Published var eveningHour:   Int
    @Published var eveningMinute: Int

    // MARK: - Init

    private init() {
        let ud = UserDefaults.standard
        morningHour   = ud.object(forKey: Keys.morningHour)   != nil ? ud.integer(forKey: Keys.morningHour)   : Self.defaultMorningHour
        morningMinute = ud.object(forKey: Keys.morningMinute) != nil ? ud.integer(forKey: Keys.morningMinute) : Self.defaultMorningMinute
        eveningHour   = ud.object(forKey: Keys.eveningHour)   != nil ? ud.integer(forKey: Keys.eveningHour)   : Self.defaultEveningHour
        eveningMinute = ud.object(forKey: Keys.eveningMinute) != nil ? ud.integer(forKey: Keys.eveningMinute) : Self.defaultEveningMinute
    }

    // MARK: - Persistence

    func save() {
        let ud = UserDefaults.standard
        ud.set(morningHour,   forKey: Keys.morningHour)
        ud.set(morningMinute, forKey: Keys.morningMinute)
        ud.set(eveningHour,   forKey: Keys.eveningHour)
        ud.set(eveningMinute, forKey: Keys.eveningMinute)
    }

    func resetToDefaults() {
        morningHour   = Self.defaultMorningHour
        morningMinute = Self.defaultMorningMinute
        eveningHour   = Self.defaultEveningHour
        eveningMinute = Self.defaultEveningMinute
        save()
    }

    // MARK: - Time Clamping

    /// Clamps an arbitrary (hour, minute) into the safe notification window.
    /// Times before morning start → morning start.
    /// Times after evening end   → evening end.
    func clamped(hour: Int, minute: Int) -> (hour: Int, minute: Int) {
        let total   = hour * 60 + minute
        let morning = morningHour * 60 + morningMinute
        let evening = eveningHour * 60 + eveningMinute
        if total < morning { return (morningHour, morningMinute) }
        if total > evening { return (eveningHour, eveningMinute) }
        return (hour, minute)
    }

    // MARK: - Display Helpers

    var morningDisplayTime: String { formatted(hour: morningHour, minute: morningMinute) }
    var eveningDisplayTime: String { formatted(hour: eveningHour, minute: eveningMinute) }

    /// A Date in today's calendar set to the morning window start.
    var morningDate: Date {
        Calendar.current.date(bySettingHour: morningHour, minute: morningMinute, second: 0, of: Date()) ?? Date()
    }

    /// A Date in today's calendar set to the evening window end.
    var eveningDate: Date {
        Calendar.current.date(bySettingHour: eveningHour, minute: eveningMinute, second: 0, of: Date()) ?? Date()
    }

    private func formatted(hour: Int, minute: Int) -> String {
        var c = DateComponents()
        c.hour = hour
        c.minute = minute
        guard let date = Calendar.current.date(from: c) else {
            return String(format: "%d:%02d", hour, minute)
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}
