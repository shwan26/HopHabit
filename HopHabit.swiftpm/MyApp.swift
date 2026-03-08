import SwiftUI
import SwiftData

@main
struct HopHabitApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            TaskItem.self,
            Habit.self,
            Routine.self,
            SessionLog.self,
            ProgressState.self,
            GratitudeJournal.self,
            MoodEntry.self
        ])
    }
}
