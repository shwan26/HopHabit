//
//  Untitled.swift
//  HopHabit


import SwiftUI
import SwiftData


enum JournalSession: String, CaseIterable, Codable {
    case morning   = "morning"
    case afternoon = "afternoon"
    case evening   = "evening"

    var emoji: String {
        switch self {
        case .morning:   return "🌅"
        case .afternoon: return "☀️"
        case .evening:   return "🌙"
        }
    }

    var label: String { rawValue.capitalized }

    var defaultHour: Int {
        switch self {
        case .morning:   return 8
        case .afternoon: return 13
        case .evening:   return 20
        }
    }

    var ownedSlots: [Int] {
        switch self {
        case .morning:   return [0, 1, 2]
        case .afternoon: return [1]
        case .evening:   return [2]
        }
    }

    var primarySlot: Int {
        switch self {
        case .morning:   return 0
        case .afternoon: return 1
        case .evening:   return 2
        }
    }
}


@Model
final class GratitudeJournal {
    var date: Date
    var session: String
    var thankfulItems: [String]
    var goodThingsItems: [String]
    var scheduledHour: Int

    init(date: Date, session: JournalSession) {
        self.date            = date
        self.session         = session.rawValue
        self.thankfulItems   = ["", "", ""]
        self.goodThingsItems = ["", "", ""]
        self.scheduledHour   = session.defaultHour
    }

    var journalSession: JournalSession {
        JournalSession(rawValue: session) ?? .morning
    }

    var hasContent: Bool {
        thankfulItems.contains   { !$0.isEmpty } ||
        goodThingsItems.contains { !$0.isEmpty }
    }
}

struct JournalSheetView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    @Query private var progressStates: [ProgressState]
    private var state: ProgressState? { progressStates.first }

    let date: Date
    let journals: [GratitudeJournal]
    
    let isPastDay: Bool

    @State private var selectedSession: JournalSession = .morning

    
    @State private var thankful:   [String] = ["", "", ""]
    @State private var goodThings: [String] = ["", "", ""]
    @State private var scheduledHour: Int = JournalSession.morning.defaultHour
    @State private var isSaving = false
    @State private var showPaddyToast = false

   
    @State private var isEditing = false

    private var currentJournal: GratitudeJournal? {
        journals.first { $0.journalSession == selectedSession }
    }

    private var isReadOnly: Bool { isPastDay || !isEditing }
    private var dayHasAnyContent: Bool { journals.contains { $0.hasContent } }
    private var visibleSlots: [Int] { selectedSession.ownedSlots }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(r: 10, g: 10, b: 46).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        dateHeader
                        sessionPicker
                        if isEditing { schedulePicker }
                        Divider().background(.white.opacity(0.1))
                        entrySection(
                            icon: "🙏",
                            title: "Grateful For",
                            items: $thankful,
                            placeholder: "I'm grateful for…"
                        )
                        Divider().background(.white.opacity(0.1))
                        entrySection(
                            icon: "✨",
                            title: "Something Good About Me",
                            items: $goodThings,
                            placeholder: "Something good about me…"
                        )
                        if isEditing { saveButton }
                    }
                    .padding()
                }

                if showPaddyToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 10) {
                            Text("🌾").font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("+1 Paddy Earned!")
                                    .font(.subheadline.bold()).foregroundStyle(.white)
                                Text("Journal complete for today")
                                    .font(.caption).foregroundStyle(.white.opacity(0.7))
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.green.opacity(0.85), in: RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal).padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle(
                isPastDay ? "Looking Back" : (isEditing ? "Edit Journal" : "Gratitude Journal")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(r: 10, g: 10, b: 46), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }.foregroundStyle(.white.opacity(0.7))
                }
                if !isPastDay && dayHasAnyContent && !isEditing {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { isEditing = true }
                        } label: {
                            Text("Edit").foregroundStyle(.purple)
                        }
                    }
                }
                if !isPastDay && isEditing {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { isEditing = false }
                        } label: {
                            Text("Done").foregroundStyle(.purple).fontWeight(.semibold)
                        }
                    }
                }
            }
            .onAppear {
                mergeAllSessions()
                selectDefaultSession()
                isEditing = !isPastDay && !dayHasAnyContent
            }
            .onChange(of: selectedSession) { _, _ in
                scheduledHour = currentJournal?.scheduledHour ?? selectedSession.defaultHour
            }
        }
    }

    private var dateHeader: some View {
        HStack(spacing: 6) {
            if isPastDay {
                Label("Locked", systemImage: "lock.fill")
                    .font(.caption2).foregroundStyle(.white.opacity(0.3))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(.white.opacity(0.06), in: Capsule())
            } else if isEditing {
                Label("Editing", systemImage: "pencil")
                    .font(.caption2).foregroundStyle(.purple)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(.purple.opacity(0.12), in: Capsule())
            } else if dayHasAnyContent {
                Label("Tap Edit to change", systemImage: "eye")
                    .font(.caption2).foregroundStyle(.white.opacity(0.3))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(.white.opacity(0.06), in: Capsule())
            }
            Spacer()
            Text(date, format: .dateTime.weekday(.wide).month(.abbreviated).day().year())
                .font(.subheadline).foregroundStyle(.white.opacity(0.5))
        }
    }

    private var sessionPicker: some View {
        HStack(spacing: 0) {
            ForEach(JournalSession.allCases, id: \.rawValue) { session in
                Button { selectedSession = session } label: {
                    VStack(spacing: 4) {
                        Text(session.emoji).font(.title3)
                        Text(session.label)
                            .font(.caption.bold())
                            .foregroundStyle(selectedSession == session ? .white : .white.opacity(0.4))
                        Circle()
                            .fill(sessionHasContent(session) ? Color.purple : Color.clear)
                            .frame(width: 5, height: 5)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        selectedSession == session ? Color.purple.opacity(0.3) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                }
            }
        }
        .padding(4)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
    }

    private var schedulePicker: some View {
        HStack {
            Image(systemName: "clock.fill").foregroundStyle(.purple)
            Text("Reminder time").font(.subheadline).foregroundStyle(.white.opacity(0.7))
            Spacer()
            Picker("Hour", selection: $scheduledHour) {
                ForEach(0..<24, id: \.self) { h in Text(hourLabel(h)).tag(h) }
            }
            .pickerStyle(.menu).tint(.purple)
        }
        .padding(12)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }

    private func entrySection(
        icon: String,
        title: String,
        items: Binding<[String]>,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(icon).font(.title3)
                Text(title).font(.subheadline.bold()).foregroundStyle(.white)
            }
            ForEach(visibleSlots, id: \.self) { idx in
                HStack(alignment: .top, spacing: 10) {
                    sessionDot(for: idx)
                    if isReadOnly {
                        let text = items.wrappedValue[idx]
                        Text(text.isEmpty ? "—" : text)
                            .font(.subheadline)
                            .foregroundStyle(text.isEmpty ? .white.opacity(0.2) : .white.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                    } else {
                        TextField(placeholder, text: items[idx], axis: .vertical)
                            .foregroundStyle(.white)
                            .font(.subheadline)
                            .padding(10)
                            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
                            .lineLimit(3, reservesSpace: true)
                    }
                }
            }
            if selectedSession == .morning && isEditing {
                Text("Tip: you can fill all 3 now, or let afternoon ☀️ and evening 🌙 fill theirs later.")
                    .font(.caption2).foregroundStyle(.white.opacity(0.3)).padding(.top, 2)
            }
        }
    }

    private func sessionDot(for slotIndex: Int) -> some View {
        let session: JournalSession = slotIndex == 0 ? .morning : (slotIndex == 1 ? .afternoon : .evening)
        return VStack(spacing: 2) {
            Text(session.emoji).font(.caption2)
        }
        .frame(width: 26)
        .padding(.top, 8)
    }

    private var saveButton: some View {
        Button { saveJournal() } label: {
            HStack {
                if isSaving {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Save").fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.purple, in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(.white)
        }
        .padding(.top, 4)
    }

    private func mergeAllSessions() {
        var t = ["", "", ""]
        var g = ["", "", ""]
        for j in journals {
            let items = padded(j.thankfulItems)
            let goods = padded(j.goodThingsItems)
            for slot in j.journalSession.ownedSlots where slot < 3 {
                if !items[slot].isEmpty { t[slot] = items[slot] }
                if !goods[slot].isEmpty { g[slot] = goods[slot] }
            }
        }
        thankful   = t
        goodThings = g
    }

    private func selectDefaultSession() {
        guard !isPastDay else { return }
        for session in JournalSession.allCases {
            if !sessionHasContent(session) { selectedSession = session; return }
        }
        selectedSession = .morning
    }

    private func sessionHasContent(_ session: JournalSession) -> Bool {
        journals.first { $0.journalSession == session }?.hasContent == true
    }

    private func padded(_ arr: [String]) -> [String] {
        var a = arr; while a.count < 3 { a.append("") }; return Array(a.prefix(3))
    }

    private func saveJournal() {
        isSaving = true
        let wasComplete = isDayJournalComplete(using: journals)

        let journal: GratitudeJournal
        if let existing = currentJournal {
            journal = existing
        } else {
            journal = GratitudeJournal(date: date, session: selectedSession)
            context.insert(journal)
        }

        var t = padded(journal.thankfulItems)
        var g = padded(journal.goodThingsItems)
        for slot in selectedSession.ownedSlots where slot < 3 {
            t[slot] = thankful[slot]
            g[slot] = goodThings[slot]
        }
        journal.thankfulItems   = t
        journal.goodThingsItems = g
        journal.scheduledHour   = scheduledHour
        try? context.save()

        let nowComplete = RewardCalculator.shouldAwardJournalPaddy(
            thankfulSlots: thankful,
            goodThingsSlots: goodThings
        )

        if !wasComplete && nowComplete { awardJournalPaddy() }

        isSaving = false

        if !wasComplete && nowComplete {
            withAnimation(.spring()) { showPaddyToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { dismiss() }
        } else {
            dismiss()
        }
    }

    private func isDayJournalComplete(using journals: [GratitudeJournal]) -> Bool {
        var t = ["", "", ""], g = ["", "", ""]
        for j in journals {
            let items = padded(j.thankfulItems)
            let goods = padded(j.goodThingsItems)
            for slot in j.journalSession.ownedSlots where slot < 3 {
                if !items[slot].isEmpty { t[slot] = items[slot] }
                if !goods[slot].isEmpty { g[slot] = goods[slot] }
            }
        }
        return RewardCalculator.shouldAwardJournalPaddy(thankfulSlots: t, goodThingsSlots: g)
    }

    private func awardJournalPaddy() {
        if let s = state {
            s.totalRiceEarned += RewardCalculator.journalPaddyReward
        } else {
            let newState = ProgressState()
            newState.totalRiceEarned = RewardCalculator.journalPaddyReward
            context.insert(newState)
        }
        try? context.save()
    }

    private func hourLabel(_ h: Int) -> String {
        let f = DateFormatter(); f.dateFormat = "h a"
        let cal = Calendar.current
        var c = cal.dateComponents([.year, .month, .day], from: date)
        c.hour = h; c.minute = 0
        return cal.date(from: c).map { f.string(from: $0) } ?? "\(h):00"
    }
}
