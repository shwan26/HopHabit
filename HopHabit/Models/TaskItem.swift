import Foundation
import SwiftData

@Model
final class TaskItem {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var date: Date          // The day this task belongs to
    var createdAt: Date

    init(title: String, date: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.date = Calendar.current.startOfDay(for: date)
        self.createdAt = Date()
    }
}
