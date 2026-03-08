//
//  TaskItem.swift
//  HopHabit


import Foundation
import SwiftData

@Model
final class TaskItem {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var date: Date         
    var createdAt: Date

    init(title: String, date: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.date = Calendar.current.startOfDay(for: date)
        self.createdAt = Date()
    }
}
