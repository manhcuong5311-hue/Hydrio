import UserNotifications
import UIKit
import Foundation

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // MARK: - Permission

    /// Request permission; returns true if granted.
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Current authorization status (main-thread safe).
    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Open iOS Settings → Notifications for this app.
    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Scheduling with Window Enforcement

    /// Schedules repeating calendar-based reminders for every slot inside the
    /// notification window that matches the user's chosen interval.
    ///
    /// Uses `UNCalendarNotificationTrigger` so each slot fires at the exact same
    /// time every day — eliminating night-time delivery entirely.
    ///
    /// Window enforcement examples:
    ///   - Reminder at 06:30 with default window → shifted to 08:00
    ///   - Reminder at 23:30 with default window → shifted to 21:00
    ///
    /// Up to 60 slots are scheduled (well within the system limit of 64).
    func scheduleReminders(interval: ReminderInterval, window: NotificationWindowManager) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        guard interval != .never, interval.minutes > 0 else { return }

        let morningMinutes = window.morningHour * 60 + window.morningMinute
        let eveningMinutes = window.eveningHour * 60 + window.eveningMinute

        var slot  = morningMinutes
        var count = 0

        while slot <= eveningMinutes && count < 60 {
            let h = slot / 60
            let m = slot % 60

            var components    = DateComponents()
            components.hour   = h
            components.minute = m

            let content       = UNMutableNotificationContent()
            content.title     = "Time to Hydrate! 💧"
            content.body      = "Don't forget to drink water and keep your streak going!"
            content.sound     = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: "hydration_\(h)_\(m)",
                content: content,
                trigger: trigger
            )
            center.add(request)

            slot  += interval.minutes
            count += 1
        }
    }

    /// Legacy overload — uses the shared window (reads persisted user settings).
    /// Called from HydrationViewModel so it always respects the stored window.
    func scheduleReminders(interval: ReminderInterval) {
        scheduleReminders(interval: interval, window: NotificationWindowManager.shared)
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Goal Reached

    func sendGoalReachedNotification() {
        let content   = UNMutableNotificationContent()
        content.title = "Goal Reached! 🎉"
        content.body  = "Amazing! You've hit your daily hydration goal. Your pet is thriving!"
        content.sound = .default
        let trigger   = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request   = UNNotificationRequest(
            identifier: "goal_reached_\(UUID())",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}
