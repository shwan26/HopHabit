import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var title: String
    /// ISO weekday numbers (1=Sun … 7=Sat) when this habit is scheduled
    var scheduledDays: [Int]
    var completedDates: [Date]  // start-of-day dates where habit was done
    var createdAt: Date

    init(title: String, scheduledDays: [Int] = [1, 2, 3, 4, 5, 6, 7]) {
        self.id = UUID()
        self.title = title
        self.scheduledDays = scheduledDays
        self.completedDates = []
        self.createdAt = Date()
    }

    /// Whether this habit is completed for a given day
    func isCompleted(on date: Date) -> Bool {
        let day = Calendar.current.startOfDay(for: date)
        return completedDates.contains { Calendar.current.isDate($0, inSameDayAs: day) }
    }

    /// Toggle completion for today
    func toggle(on date: Date = Date()) {
        let day = Calendar.current.startOfDay(for: date)
        if let idx = completedDates.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: day) }) {
            completedDates.remove(at: idx)
        } else {
            completedDates.append(day)
        }
    }

    /// Current streak (consecutive days up to today)
    var currentStreak: Int {
        var streak = 0
        var checkDate = Calendar.current.startOfDay(for: Date())
        while isCompleted(on: checkDate) {
            streak += 1
            checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        return streak
    }
}
