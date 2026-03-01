//
//  RewardCalculator.swift
//  HopHabit

import Foundation

struct RewardCalculator {

    static let taskRiceRange:     ClosedRange<Int> = 2...5
    static let habitRiceRange:    ClosedRange<Int> = 4...7
    static let fullDayBonusRange: ClosedRange<Int> = 8...15
    static let loginBonus:        Int              = 1
    static let journalPaddyReward: Int             = 1

    static let moonBlessingChance: Double          = 0.05
    static let moonBlessingRange:  ClosedRange<Int> = 10...20


    static let rabbitStepsPerDay: Int = 1
    static let totalMoonSteps:    Int = 28

  

    static let practiceBoostMinSeconds: Int          = 5 * 60
    static let practiceBoostRange:      ClosedRange<Int> = 8...15



    struct RabbitSkin {
        let name:          String
        let emoji:         String
        let unlockHours:   Double
        let unlockMessage: String
    }

    static let rabbitSkins: [RabbitSkin] = [
        RabbitSkin(name: "Starter",     emoji: "🐰",   unlockHours: 0,    unlockMessage: "Your journey begins!"),
        RabbitSkin(name: "Moon Pup",    emoji: "🌙🐰",  unlockHours: 10,   unlockMessage: "10 hours — the moon notices you!"),
        RabbitSkin(name: "Rice Bunny",  emoji: "🌾🐰",  unlockHours: 50,   unlockMessage: "50 hours — you're growing strong!"),
        RabbitSkin(name: "Star Hare",   emoji: "⭐️🐇",  unlockHours: 100,  unlockMessage: "100 hours — a true practitioner!"),
        RabbitSkin(name: "Golden Hare", emoji: "✨🐇",  unlockHours: 250,  unlockMessage: "250 hours — legendary focus!"),
        RabbitSkin(name: "Moon Master", emoji: "🌕🐇",  unlockHours: 500,  unlockMessage: "500 hours — halfway to mastery!"),
        RabbitSkin(name: "Jade Rabbit", emoji: "💚🐇",  unlockHours: 750,  unlockMessage: "750 hours — almost there!"),
        RabbitSkin(name: "Legendary",   emoji: "🏆🐇",  unlockHours: 1000, unlockMessage: "1000 HOURS — You are a Master!"),
    ]

    static func currentSkin(forHours hours: Double) -> RabbitSkin {
        rabbitSkins.filter { hours >= $0.unlockHours }.last ?? rabbitSkins[0]
    }

    static func nextSkin(forHours hours: Double) -> RabbitSkin? {
        rabbitSkins.first { hours < $0.unlockHours }
    }

    // MARK: - Streak Tiers (variable bonus per tier)

    static func streakBonus(for streak: Int) -> Int {
        switch streak {
        case 3..<7:   return Int.random(in: 2...4)
        case 7..<14:  return Int.random(in: 5...9)
        case 14..<30: return Int.random(in: 12...16)
        case 30...:   return Int.random(in: 20...30)
        default:      return 0
        }
    }

    static func streakTierLabel(for streak: Int) -> String {
        switch streak {
        case 0..<3:   return "Seedling 🌱"
        case 3..<7:   return "Sprouting 🌿"
        case 7..<14:  return "Growing 🌸"
        case 14..<30: return "Blooming 🌕"
        default:      return "Legendary 🏆"
        }
    }

    static func isStreakInDanger(streak: Int, lastCompletedDay: Date?) -> Bool {
        guard streak > 0 else { return false }
        let hour = Calendar.current.component(.hour, from: Date())
        guard hour >= 20 else { return false }
        guard let last = lastCompletedDay else { return true }
        return !Calendar.current.isDateInToday(last)
    }

    static func calculateReward(
        completedTasks:  Int,
        totalTasks:      Int,
        completedHabits: Int,
        totalHabits:     Int,
        currentStreak:   Int
    ) -> RewardResult {
        let taskRice  = (0..<completedTasks).reduce(0)  { acc, _ in acc + Int.random(in: taskRiceRange)  }
        let habitRice = (0..<completedHabits).reduce(0) { acc, _ in acc + Int.random(in: habitRiceRange) }

        let hasItems  = totalTasks + totalHabits > 0
        let allDone   = completedTasks == totalTasks && completedHabits == totalHabits
        let bonusRice = (hasItems && allDone) ? Int.random(in: fullDayBonusRange) : 0

        let newStreak  = currentStreak + 1
        let streakRice = streakBonus(for: newStreak)

        var moonBlessingAmt = 0
        var gotBlessing     = false
        if hasItems && allDone && Double.random(in: 0...1) < moonBlessingChance {
            moonBlessingAmt = Int.random(in: moonBlessingRange)
            gotBlessing     = true
        }

        let total = taskRice + habitRice + bonusRice + streakRice + moonBlessingAmt
        return RewardResult(
            taskRice:        taskRice,
            habitRice:       habitRice,
            fullDayBonus:    bonusRice,
            streakBonus:     streakRice,
            moonBlessing:    moonBlessingAmt,
            gotMoonBlessing: gotBlessing,
            totalRice:       total,
            earnedFullBonus: bonusRice > 0
        )
    }

    static func riceEarned(
        completedTasks:  Int,
        totalTasks:      Int,
        completedHabits: Int,
        totalHabits:     Int
    ) -> Int {
        calculateReward(
            completedTasks:  completedTasks,
            totalTasks:      totalTasks,
            completedHabits: completedHabits,
            totalHabits:     totalHabits,
            currentStreak:   0
        ).totalRice
    }

    static func shouldAwardJournalPaddy(thankfulSlots: [String], goodThingsSlots: [String]) -> Bool {
        let allT = thankfulSlots.prefix(3).allSatisfy   { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let allG = goodThingsSlots.prefix(3).allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        return allT && allG
    }

    static func advanceRabbit(current: Int) -> Int {
        (current + rabbitStepsPerDay) % totalMoonSteps
    }

    static func rabbitBoost(forSessionSeconds s: Int) -> Int {
        s >= practiceBoostMinSeconds ? Int.random(in: practiceBoostRange) : 0
    }

   
    static func almostThereMessage(
        completedTasks:  Int,
        totalTasks:      Int,
        completedHabits: Int,
        totalHabits:     Int
    ) -> String? {
        let total     = totalTasks + totalHabits
        let done      = completedTasks + completedHabits
        let remaining = total - done
        guard total > 0, remaining > 0, remaining <= 2 else { return nil }
        let hour = Calendar.current.component(.hour, from: Date())
        if remaining == 1 {
            return hour >= 20 ? "⚠️ Just 1 left — don't lose your streak tonight!"
                              : "✨ Just 1 more — you're so close!"
        } else {
            return hour >= 20 ? "🔥 2 items left — finish before midnight!"
                              : "🌙 Almost there — 2 items to go!"
        }
    }

    static func updatedStreak(current: Int, lastCompleted: Date?) -> Int {
        guard let last = lastCompleted else { return 1 }
        let cal        = Calendar.current
        let lastDay    = cal.startOfDay(for: last)
        let today      = cal.startOfDay(for: Date())
        let daysMissed = cal.dateComponents([.day], from: lastDay, to: today).day ?? 0
        switch daysMissed {
        case 0:  return current
        case 1:  return current + 1
        case 2:  return max(1, current / 2)
        default: return 1
        }
    }

    static func completionFraction(
        completedTasks:  Int,
        totalTasks:      Int,
        completedHabits: Int,
        totalHabits:     Int
    ) -> Double {
        let total = totalTasks + totalHabits
        guard total > 0 else { return 0 }
        return min(1.0, Double(completedTasks + completedHabits) / Double(total))
    }
}

struct RewardResult {
    let taskRice:        Int
    let habitRice:       Int
    let fullDayBonus:    Int
    let streakBonus:     Int
    let moonBlessing:    Int
    let gotMoonBlessing: Bool
    let totalRice:       Int
    let earnedFullBonus: Bool

    var summaryLines: [String] {
        var lines: [String] = []
        if taskRice      > 0 { lines.append("Tasks           +\(taskRice) 🌾") }
        if habitRice     > 0 { lines.append("Habits          +\(habitRice) 🌾") }
        if fullDayBonus  > 0 { lines.append("Full day!       +\(fullDayBonus) 🌾") }
        if streakBonus   > 0 { lines.append("Streak bonus    +\(streakBonus) 🌾") }
        if moonBlessing  > 0 { lines.append("🌕 Moon Blessing! +\(moonBlessing) 🌾") }
        return lines
    }
}
