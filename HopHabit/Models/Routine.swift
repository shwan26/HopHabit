import Foundation
import SwiftData

@Model
final class Routine {
    var id: UUID
    var name: String
    var totalSeconds: Int       // Accumulated time in seconds
    var goalHours: Int          // Default 10000 (the 10,000-hour rule)
    var createdAt: Date

    // Computed goal in seconds
    var goalSeconds: Int { goalHours * 3600 }

    // Progress fraction 0.0 – 1.0
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
