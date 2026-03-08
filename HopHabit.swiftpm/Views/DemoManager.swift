//
//  DemoManager.swift
//  HopHabit

import Foundation
import SwiftData

struct DemoManager {


    @MainActor
    static func loadDemo(context: ModelContext) {
        // Idempotency guard — don't double-seed
        var descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { $0.title == "🎯 Demo: Morning Meditation" }
        )
        descriptor.fetchLimit = 1
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let cal   = Calendar.current
        let today = cal.startOfDay(for: Date())

        var stateDesc = FetchDescriptor<ProgressState>()
        stateDesc.fetchLimit = 1
        let states   = (try? context.fetch(stateDesc)) ?? []
        let state    = states.first ?? {
            let s = ProgressState(); context.insert(s); return s
        }()

        state.softStreak          = 14
        state.longestStreak       = 21
        state.totalRiceEarned     = 127
        state.totalPracticeHours  = 47.3
        // Yesterday — so "Complete Day" button is live today
        state.lastCompletedDay    = cal.date(byAdding: .day, value: -1, to: today)
        state.lastLoginDate       = nil

        let habitDefs: [(title: String, emoji: String)] = [
            ("🧘 Meditation",     "meditation"),
            ("💧 Hydration",      "hydration"),
            ("🤸 Stretching",     "stretching"),
            ("📖 Deep Study",     "study"),
            ("🚿 Cold Shower",    "shower"),
        ]

        for def in habitDefs {
            let habit = Habit(title: def.title, scheduledDays: [1,2,3,4,5,6,7])
            context.insert(habit)
            for offset in 0...6 {
                if let day = cal.date(byAdding: .day, value: -offset, to: today) {
                    habit.completedDates.append(cal.startOfDay(for: day))
                }
            }
        }


        let taskDefs: [(title: String, done: Bool)] = [
            ("🎯 Demo: Morning Meditation",  true),
            ("📝 Write project proposal",    true),
            ("📧 Reply to team emails",      true),
            ("🏃 Evening run",               true),
            ("🌙 Plan tomorrow's tasks",     false),
        ]
        for def in taskDefs {
            let task = TaskItem(title: def.title, date: today)
            task.isCompleted = def.done
            context.insert(task)
        }

        let routine = Routine(name: "Piano Practice", goalHours: 1000)
   
        routine.addSeconds(170_280)
        context.insert(routine)

        let logDurations = [
            (daysAgo: 0, seconds: 3_600),
            (daysAgo: 1, seconds: 5_400),
            (daysAgo: 2, seconds: 2_700),
        ]
        for log in logDurations {
            let entry = SessionLog(routineID: routine.id, durationSeconds: log.seconds)
            if let d = cal.date(byAdding: .day, value: -log.daysAgo, to: Date()) {
                entry.date = d
            }
            context.insert(entry)
        }

        let journal = GratitudeJournal(date: today, session: .morning)
        journal.thankfulItems   = ["My health and energy 🌿",
                                   "A supportive community 🤝",
                                   "This beautiful morning ☀️"]
        journal.goodThingsItems = ["I stayed consistent with practice 🎹",
                                   "I helped a colleague today 💬",
                                   "I chose growth over comfort 🌱"]
        context.insert(journal)

        let moodPattern: [MoodType] = [
            .happy,
            .happy,
            .neutral,
            .sad,
            .neutral,
            .happy,
            .happy,
        ]

        for (offset, mood) in moodPattern.enumerated() {
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            let entry = MoodEntry(date: day, mood: mood)
            context.insert(entry)
        }

       
        try? context.save()
    }

    @MainActor
    static func resetDemo(context: ModelContext) {
        
        try? context.delete(model: TaskItem.self)
        try? context.delete(model: Habit.self)
        try? context.delete(model: Routine.self)
        try? context.delete(model: SessionLog.self)
        try? context.delete(model: GratitudeJournal.self)
        try? context.delete(model: ProgressState.self)
        try? context.delete(model: MoodEntry.self)
        try? context.save()
    }
}
