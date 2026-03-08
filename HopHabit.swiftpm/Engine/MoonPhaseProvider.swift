//
//  MoonPhaseProvider.swift
//  HopHabit

import Foundation

enum MoonPhaseProvider {

    enum Phase: String, CaseIterable {
        case newMoon        = "New Moon"
        case waxingCrescent = "Waxing Crescent"
        case firstQuarter   = "First Quarter"
        case waxingGibbous  = "Waxing Gibbous"
        case fullMoon       = "Full Moon"
        case waningGibbous  = "Waning Gibbous"
        case lastQuarter    = "Last Quarter"
        case waningCrescent = "Waning Crescent"

        var emoji: String {
            switch self {
            case .newMoon:        return "🌑"
            case .waxingCrescent: return "🌒"
            case .firstQuarter:   return "🌓"
            case .waxingGibbous:  return "🌔"
            case .fullMoon:       return "🌕"
            case .waningGibbous:  return "🌖"
            case .lastQuarter:    return "🌗"
            case .waningCrescent: return "🌘"
            }
        }

        var name: String { rawValue }
        var illumination: Double {
            switch self {
            case .newMoon:        return 0.0
            case .waxingCrescent: return 0.25
            case .firstQuarter:   return 0.5
            case .waxingGibbous:  return 0.75
            case .fullMoon:       return 1.0
            case .waningGibbous:  return 0.75
            case .lastQuarter:    return 0.5
            case .waningCrescent: return 0.25
            }
        }
    }

    static func phase() -> Phase {
        phase(for: Date())
    }

    static func phase(for date: Date) -> Phase {
        let referenceDate = Date(timeIntervalSince1970: 947_182_440)
        let synodicPeriod = 29.53058868
        let elapsed = date.timeIntervalSince(referenceDate) / 86_400
        var age = elapsed.truncatingRemainder(dividingBy: synodicPeriod)
        if age < 0 { age += synodicPeriod }

        switch age {
        case 0..<1.85:        return .newMoon
        case 1.85..<7.38:     return .waxingCrescent
        case 7.38..<9.22:     return .firstQuarter
        case 9.22..<14.77:    return .waxingGibbous
        case 14.77..<16.61:   return .fullMoon
        case 16.61..<22.15:   return .waningGibbous
        case 22.15..<23.99:   return .lastQuarter
        case 23.99..<29.53:   return .waningCrescent
        default:              return .newMoon
        }
    }
}
