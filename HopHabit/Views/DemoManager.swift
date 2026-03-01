//
//  DemoManager.swift
//  HopHabit
//
//  Demo Mode: one tap populates every view with realistic data so judges
//  see the full app experience immediately — no manual setup required.
//
//  What it seeds:
//   • 5 Habits (Meditation, Hydration, Stretching, Deep Study, Cold Shower)
//     all marked complete for today + 6 prior days (to build streak)
//   • 5 TaskItems for today, 4 of 5 already completed
//   • 1 Routine (Piano Practice) with 47.3 hours logged
//     + 3 recent SessionLogs so "Recent Sessions" shows data
//   • GratitudeJournal for today (morning) — all 6 slots filled
//   • ProgressState: 14-day softStreak, longestStreak 21, 127 rice,
//     totalPracticeHours 47.3, lastCompletedDay = yesterday (so
//     "Complete Day" is live), lastLoginDate = nil (triggers login bonus)
//
//  Call loadDemo(context:) once; it's idempotent — bails early if demo
//  data already exists (checks for a task titled "🎯 Demo: Morning Meditation").
//

import Foundation
import SwiftData

struct DemoManager {

    // MARK: - Public entry point

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

        // ── ProgressState ──────────────────────────────────────────────────
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
        // nil → triggers the daily login bonus toast on HomeWorldView
        state.lastLoginDate       = nil

        // ── Habits ────────────────────────────────────────────────────────
        let habitDefs: [(title: String, emoji: String)] = [
            ("🧘 Meditation",     "meditation"),
            ("💧 Hydration",      "hydration"),
            ("🤸 Stretching",     "stretching"),
            ("📖 Deep Study",     "study"),
            ("🚿 Cold Shower",    "shower"),
        ]
        let weekday = cal.component(.weekday, from: today)

        for def in habitDefs {
            let habit = Habit(title: def.title, scheduledDays: [1,2,3,4,5,6,7])
            context.insert(habit)
            // Mark complete today + 6 prior days → streak = 7
            for offset in 0...6 {
                if let day = cal.date(byAdding: .day, value: -offset, to: today) {
                    habit.completedDates.append(cal.startOfDay(for: day))
                }
            }
        }

        // ── Tasks ─────────────────────────────────────────────────────────
        // Use the special sentinel title only for the first task (idempotency check)
        let taskDefs: [(title: String, done: Bool)] = [
            ("🎯 Demo: Morning Meditation",  true),
            ("📝 Write project proposal",    true),
            ("📧 Reply to team emails",      true),
            ("🏃 Evening run",               true),
            ("🌙 Plan tomorrow's tasks",     false),   // one left → triggers almost-there nudge
        ]
        for def in taskDefs {
            let task = TaskItem(title: def.title, date: today)
            task.isCompleted = def.done
            context.insert(task)
        }

        // ── Routine + SessionLogs ─────────────────────────────────────────
        let routine = Routine(name: "Piano Practice", goalHours: 1000)
        // 47.3 h = 170 280 s
        routine.addSeconds(170_280)
        context.insert(routine)

        let logDurations = [
            (daysAgo: 0, seconds: 3_600),   // 1h today
            (daysAgo: 1, seconds: 5_400),   // 1.5h yesterday
            (daysAgo: 2, seconds: 2_700),   // 45 min
        ]
        for log in logDurations {
            let entry = SessionLog(routineID: routine.id, durationSeconds: log.seconds)
            if let d = cal.date(byAdding: .day, value: -log.daysAgo, to: Date()) {
                entry.date = d
            }
            context.insert(entry)
        }

        // ── GratitudeJournal ──────────────────────────────────────────────
        let journal = GratitudeJournal(date: today, session: .morning)
        journal.thankfulItems   = ["My health and energy 🌿",
                                   "A supportive community 🤝",
                                   "This beautiful morning ☀️"]
        journal.goodThingsItems = ["I stayed consistent with practice 🎹",
                                   "I helped a colleague today 💬",
                                   "I chose growth over comfort 🌱"]
        context.insert(journal)

        // ── Persist ───────────────────────────────────────────────────────
        try? context.save()
    }

    // MARK: - Reset (clears ALL app data for a clean re-demo)

    @MainActor
    static func resetDemo(context: ModelContext) {
        // Delete everything in all model types
        try? context.delete(model: TaskItem.self)
        try? context.delete(model: Habit.self)
        try? context.delete(model: Routine.self)
        try? context.delete(model: SessionLog.self)
        try? context.delete(model: GratitudeJournal.self)
        try? context.delete(model: ProgressState.self)
        try? context.save()
    }
}
