//
//  StreakManager.swift
//  HopHabit
//
//  Helpers for displaying habit streak information.
//

import Foundation

enum StreakManager {

    /// Returns a human-readable streak label, e.g. "🔥 5-day streak" or "Start your streak!"
    static func label(for streak: Int) -> String {
        switch streak {
        case 0:        return "Start your streak!"
        case 1:        return "🌱 1-day streak — keep going!"
        case 2..<7:    return "🔥 \(streak)-day streak"
        case 7..<14:   return "⚡️ \(streak)-day streak — on fire!"
        case 14..<30:  return "💎 \(streak)-day streak — impressive!"
        case 30..<100: return "🏅 \(streak)-day streak — legendary!"
        default:       return "🏆 \(streak)-day streak — unstoppable!"
        }
    }

    /// Short version used in compact UI contexts.
    static func shortLabel(for streak: Int) -> String {
        streak == 0 ? "No streak" : "🔥 \(streak)d"
    }
}
