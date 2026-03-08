//
//  SessionLog.swift
//  HopHabit

import Foundation
import SwiftData

@Model
final class SessionLog {
    var id: UUID
    var routineID: UUID
    var durationSeconds: Int
    var date: Date

    init(routineID: UUID, durationSeconds: Int) {
        self.id = UUID()
        self.routineID = routineID
        self.durationSeconds = durationSeconds
        self.date = Date()
    }

    var formattedDuration: String {
        let m = durationSeconds / 60
        let s = durationSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
