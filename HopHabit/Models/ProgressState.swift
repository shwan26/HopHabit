//
//  ProgressState.swift
//  HopHabit

import Foundation
import SwiftData

@Model
final class ProgressState {
    var id: UUID = UUID()
        var totalRiceEarned: Int = 0
        var rabbitPosition: Int = 0
        var lastCompletedDay: Date?
        var softStreak: Int = 0
        var longestStreak: Int = 0
        var totalPracticeHours: Double = 0

        var lastLoginDate: Date?

    init() {
        self.id                  = UUID()
        self.totalRiceEarned     = 0
        self.rabbitPosition      = 0
        self.lastCompletedDay    = nil
        self.softStreak          = 0
        self.longestStreak       = 0
        self.totalPracticeHours  = 0
        self.lastLoginDate       = nil
    }

    var isTodayCompleted: Bool {
        guard let last = lastCompletedDay else { return false }
        return Calendar.current.isDateInToday(last)
    }
}
