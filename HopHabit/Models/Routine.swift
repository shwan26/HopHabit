import Foundation
import SwiftData

@Model
final class Routine {
    var id: UUID
    var name: String
    var totalSeconds: Int
    var goalHours: Int
    var createdAt: Date

    var goalSeconds: Int { goalHours * 3600 }

    var progress: Double {
        min(Double(totalSeconds) / Double(goalSeconds), 1.0)
    }

    var totalHours: Double { Double(totalSeconds) / 3600.0 }

    init(name: String, goalHours: Int = 10000) {
        self.id = UUID()
        self.name = name
        self.totalSeconds = 0
        self.goalHours = goalHours
        self.createdAt = Date()
    }

    func addSeconds(_ seconds: Int) {
        totalSeconds += seconds
    }
}
