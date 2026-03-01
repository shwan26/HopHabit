//
//  HopHabitApp.swift
//  HopHabit
//
//  Created by Giyu Tomioka on 2/28/26.
//

// HopHabitApp.swift
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
            Habit.self,       // ← already there
            Routine.self,
            SessionLog.self,
            ProgressState.self,
            GratitudeJournal.self  // ← ADD THIS
        ])
    }
}
