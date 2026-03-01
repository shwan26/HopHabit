import Foundation
import SwiftData

// MARK: - Time Entry

@Model
final class HabitTimeEntry {
    var id: UUID
    var habitID: UUID
    var startTime: Date
    var endTime: Date?  // nil = still running

    init(habitID: UUID, startTime: Date = Date()) {
        self.id = UUID()
        self.habitID = habitID
        self.startTime = startTime
        self.endTime = nil
    }

    var duration: TimeInterval {
        (endTime ?? Date()).timeIntervalSince(startTime)
    }

    var isRunning: Bool { endTime == nil }
}

// MARK: - Habit

@Model
final class Habit {
    var id: UUID
    var title: String
    /// ISO weekday numbers (1=Sun … 7=Sat) when this habit is scheduled
    var scheduledDays: [Int]
    var completedDates: [Date]  // start-of-day dates where habit was done
    var createdAt: Date

    @Relationship(deleteRule: .cascade) var timeEntries: [HabitTimeEntry] = []

    init(title: String, scheduledDays: [Int] = [1, 2, 3, 4, 5, 6, 7]) {
        self.id = UUID()
        self.title = title
        self.scheduledDays = scheduledDays
        self.completedDates = []
        self.createdAt = Date()
    }

    // MARK: Completion

    func isCompleted(on date: Date) -> Bool {
        let day = Calendar.current.startOfDay(for: date)
        return completedDates.contains { Calendar.current.isDate($0, inSameDayAs: day) }
    }

    func toggle(on date: Date = Date()) {
        let day = Calendar.current.startOfDay(for: date)
        if let idx = completedDates.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: day) }) {
            completedDates.remove(at: idx)
        } else {
            completedDates.append(day)
        }
    }

    var currentStreak: Int {
        var streak = 0
        var checkDate = Calendar.current.startOfDay(for: Date())
        while isCompleted(on: checkDate) {
            streak += 1
            checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        return streak
    }

    // MARK: Time Tracking

    /// The currently running time entry for this habit, if any
    var activeEntry: HabitTimeEntry? {
        timeEntries.first { $0.isRunning }
    }

    var isTimerRunning: Bool { activeEntry != nil }

    /// Start a new timer session
    func startTimer() {
        guard !isTimerRunning else { return }
        let entry = HabitTimeEntry(habitID: id)
        timeEntries.append(entry)
    }

    /// Stop the currently running timer
    func stopTimer() {
        activeEntry?.endTime = Date()
    }

    /// Total time spent today (seconds)
    var totalTimeToday: TimeInterval {
        timeEntries
            .filter { Calendar.current.isDateInToday($0.startTime) }
            .reduce(0) { $0 + $1.duration }
    }

    /// Total time for a specific date (seconds)
    func totalTime(on date: Date) -> TimeInterval {
        timeEntries
            .filter { Calendar.current.isDate($0.startTime, inSameDayAs: date) }
            .reduce(0) { $0 + $1.duration }
    }

    /// Total time across all entries (seconds)
    var totalTimeAllTime: TimeInterval {
        timeEntries.reduce(0) { $0 + $1.duration }
    }
}

// MARK: - Helpers

extension TimeInterval {
    /// Format as "1h 23m" or "45m" or "30s"
    var formatted: String {
        let totalSeconds = Int(self)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}
