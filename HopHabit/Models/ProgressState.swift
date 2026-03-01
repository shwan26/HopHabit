//
//  ProgressState.swift
//  HopHabit
//
//  Created by Giyu Tomioka on 2/28/26.
//

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

        // ✅ IMPORTANT: default at declaration (not only in init)
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

    /// Whether today has already been completed
    var isTodayCompleted: Bool {
        guard let last = lastCompletedDay else { return false }
        return Calendar.current.isDateInToday(last)
    }
}
