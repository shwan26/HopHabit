//
//  CalendarMoonView.swift
//  HopHabit
//
//  Created by Giyu Tomioka on 2/28/26.
//
//  Responsibility: moon-phase calendar + streak summary.
//  The Gratitude Journal (GratitudeJournal model, JournalSession,
//  JournalSheetView) lives in GratitudeJournal.swift.
//

import SwiftUI
import SwiftData

// MARK: - CalendarMoonView

struct CalendarMoonView: View {
    @Environment(\.modelContext) private var context
    @Query private var allTasks: [TaskItem]
    @Query private var progressStates: [ProgressState]
    @Query private var journals: [GratitudeJournal]

    @State private var displayedMonth = Date()
    @State private var selectedDate: Date? = nil
    @State private var showJournalSheet = false
    @State private var showDemoBanner   = false

    private var state: ProgressState? { progressStates.first }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(r: 10, g: 10, b: 46).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        monthNavigator
                        weekdayHeader
                        calendarGrid
                        moonLegend
                        streakSummary
                        journalPromptBanner
                    }
                    .padding()
                }

                // Demo loaded banner
                if showDemoBanner {
                    VStack {
                        Spacer()
                        HStack(spacing: 10) {
                            Text("🎬").font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Demo Mode Active!")
                                    .font(.subheadline.bold()).foregroundStyle(.white)
                                Text("14-day streak, journal & stats pre-loaded")
                                    .font(.caption).foregroundStyle(.white.opacity(0.7))
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.indigo.opacity(0.92), in: RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal).padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .zIndex(20)
                }
            }
            .navigationTitle("Moon Calendar")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(r: 10, g: 10, b: 46), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 10) {
                        // Journal shortcut
                        Button {
                            selectedDate = Date()
                            showJournalSheet = true
                        } label: {
                            Image(systemName: "book.fill").foregroundStyle(.purple)
                        }
                        // Demo menu
                        Menu {
                            Button {
                                DemoManager.loadDemo(context: context)
                                withAnimation(.spring()) { showDemoBanner = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    withAnimation { showDemoBanner = false }
                                }
                            } label: {
                                Label("Load Demo Day", systemImage: "play.rectangle.fill")
                            }
                            Button(role: .destructive) {
                                DemoManager.resetDemo(context: context)
                            } label: {
                                Label("Reset Demo", systemImage: "arrow.counterclockwise")
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Text("🎬")
                                Text("Demo")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(
                                Capsule().fill(
                                    LinearGradient(colors: [Color(r: 100, g: 60, b: 220),
                                                            Color(r: 60, g: 20, b: 160)],
                                                   startPoint: .topLeading,
                                                   endPoint: .bottomTrailing)
                                )
                            )
                            .shadow(color: Color(r: 100, g: 60, b: 220).opacity(0.5), radius: 6, y: 2)
                        }
                    }
                }
            }
            .sheet(isPresented: $showJournalSheet) {
                if let date = selectedDate {
                    JournalSheetView(
                        date: date,
                        journals: journalsFor(date: date),
                        isPastDay: isInPast(date)
                    )
                }
            }
        }
    }

    // MARK: - Month Navigator

    private var monthNavigator: some View {
        HStack {
            Button(action: { changeMonth(-1) }) {
                Image(systemName: "chevron.left").foregroundStyle(.white)
            }
            Spacer()
            Text(displayedMonth, format: .dateTime.month(.wide).year())
                .font(.headline).foregroundStyle(.white)
            Spacer()
            Button(action: { changeMonth(1) }) {
                Image(systemName: "chevron.right").foregroundStyle(.white)
            }
        }
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(Array(zip(0..., ["S","M","T","W","T","F","S"])), id: \.0) { _, d in
                Text(d)
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let days = daysInMonth()
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(0..<firstWeekdayOffset(), id: \.self) { _ in Color.clear.frame(height: 48) }
            ForEach(days, id: \.self) { date in
                let future = isInFuture(date)
                DayCell(
                    date: date,
                    phase: MoonPhaseProvider.phase(for: date),
                    hasCompletedTasks: hasCompletedTasks(on: date),
                    hasJournal: hasJournal(on: date),
                    isToday: Calendar.current.isDateInToday(date),
                    isFuture: future
                )
                .onTapGesture {
                    guard !future else { return }
                    selectedDate = date
                    showJournalSheet = true
                }
            }
        }
    }

    // MARK: - Moon Legend

    private var moonLegend: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Moon Phases")
                .font(.caption.bold()).foregroundStyle(.white.opacity(0.5))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(MoonPhaseProvider.Phase.allCases, id: \.rawValue) { phase in
                        HStack(spacing: 4) {
                            Text(phase.emoji)
                            Text(phase.name)
                                .font(.caption2).foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Streak Summary

    private var streakSummary: some View {
        HStack(spacing: 0) {
            statCell(value: state?.softStreak    ?? 0, label: "Current\nStreak",   color: .purple)
            Divider().frame(height: 50).background(.white.opacity(0.2))
            statCell(value: state?.longestStreak ?? 0, label: "Best\nStreak",     color: .yellow)
            Divider().frame(height: 50).background(.white.opacity(0.2))
            statCell(value: state?.totalRiceEarned ?? 0, label: "Total\nRice 🌾", color: .green)
        }
        .padding(16)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
    }

    private func statCell(value: Int, label: String, color: Color) -> some View {
        VStack {
            Text("\(value)").font(.title.bold()).foregroundStyle(color)
            Text(label)
                .font(.caption).foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Journal Prompt Banner

    private var journalPromptBanner: some View {
        Button {
            selectedDate = Date()
            showJournalSheet = true
        } label: {
            HStack(spacing: 12) {
                Text("📓").font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gratitude Journal")
                        .font(.subheadline.bold()).foregroundStyle(.white)
                    Text("Record what you're thankful for today")
                        .font(.caption).foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.4)).font(.caption)
            }
            .padding(14)
            .background(.purple.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.purple.opacity(0.3), lineWidth: 1))
        }
    }

    // MARK: - Helpers

    private func changeMonth(_ delta: Int) {
        displayedMonth = Calendar.current.date(byAdding: .month, value: delta, to: displayedMonth)
            ?? displayedMonth
    }

    private func daysInMonth() -> [Date] {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: displayedMonth)
        guard let start = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: start) else { return [] }
        return range.compactMap { day -> Date? in
            var c = comps; c.day = day; return cal.date(from: c)
        }
    }

    private func firstWeekdayOffset() -> Int {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: displayedMonth)
        guard let start = cal.date(from: comps) else { return 0 }
        return cal.component(.weekday, from: start) - 1
    }

    private func hasCompletedTasks(on date: Date) -> Bool {
        allTasks.contains { Calendar.current.isDate($0.date, inSameDayAs: date) && $0.isCompleted }
    }

    private func hasJournal(on date: Date) -> Bool {
        journals.contains { Calendar.current.isDate($0.date, inSameDayAs: date) && $0.hasContent }
    }

    private func isInPast(_ date: Date) -> Bool {
        Calendar.current.compare(date, to: Date(), toGranularity: .day) == .orderedAscending
    }

    private func isInFuture(_ date: Date) -> Bool {
        Calendar.current.compare(date, to: Date(), toGranularity: .day) == .orderedDescending
    }

    private func journalsFor(date: Date) -> [GratitudeJournal] {
        journals.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
}

// MARK: - DayCell

struct DayCell: View {
    let date: Date
    let phase: MoonPhaseProvider.Phase
    let hasCompletedTasks: Bool
    let hasJournal: Bool
    let isToday: Bool
    let isFuture: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text(phase.emoji)
                .font(.system(size: 18))
                .opacity(isFuture ? 0.25 : 1)
            Text(date, format: .dateTime.day())
                .font(.caption2)
                .foregroundStyle(
                    isToday  ? .purple  :
                    isFuture ? .white.opacity(0.2) :
                               .white.opacity(0.7)
                )
            HStack(spacing: 3) {
                Circle()
                    .fill(hasCompletedTasks ? Color.green  : Color.clear)
                    .frame(width: 4, height: 4)
                Circle()
                    .fill(hasJournal        ? Color.purple : Color.clear)
                    .frame(width: 4, height: 4)
            }
        }
        .frame(height: 52)
        .background(
            isToday ? Color.purple.opacity(0.2) : Color.clear,
            in: RoundedRectangle(cornerRadius: 8)
        )
    }
}
