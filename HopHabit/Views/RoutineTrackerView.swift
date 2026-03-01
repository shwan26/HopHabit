//
//  RoutineTrackerView.swift
//  HopHabit
//
//  Created by Giyu Tomioka on 2/28/26.
//

import SwiftUI
import SwiftData

// MARK: - Pomodoro Mode

enum PomodoroMode: String, CaseIterable {
    case off        = "Free"
    case classic    = "Classic"
    case extended   = "Extended"
    case deep       = "Deep"

    var workMinutes: Int {
        switch self {
        case .off:      return 0
        case .classic:  return 25
        case .extended: return 50
        case .deep:     return 90
        }
    }
    var restMinutes: Int {
        switch self {
        case .off:      return 0
        case .classic:  return 5
        case .extended: return 10
        case .deep:     return 20
        }
    }
    var emoji: String {
        switch self {
        case .off:      return "∞"
        case .classic:  return "🍅"
        case .extended: return "🔥"
        case .deep:     return "🌊"
        }
    }
    var label: String {
        switch self {
        case .off:      return "Free"
        case .classic:  return "25 / 5"
        case .extended: return "50 / 10"
        case .deep:     return "90 / 20"
        }
    }
}

enum PomodoroPhase {
    case work, rest
    var label: String { self == .work ? "Focus" : "Rest" }
    var color: Color  { self == .work ? .purple : .green }
}

// MARK: - Burst Particle

private struct BurstParticle: Identifiable {
    let id     = UUID()
    var x:     CGFloat
    var y:     CGFloat
    var opacity: Double  = 1
    var scale: CGFloat   = 1
    let symbol: String
}

// MARK: - RoutineTrackerView

struct RoutineTrackerView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Routine.createdAt) private var routines: [Routine]
    @Query(sort: \SessionLog.date, order: .reverse) private var logs: [SessionLog]
    @Query private var progressStates: [ProgressState]
    private var state: ProgressState? { progressStates.first }

    @State private var selectedRoutine: Routine?
    @State private var isRunning      = false
    @State private var elapsedSeconds = 0
    @State private var timerTask: Task<Void, Never>?

    // Pomodoro
    @State private var pomodoroMode:       PomodoroMode  = .off
    @State private var pomodoroPhase:      PomodoroPhase = .work
    @State private var pomodoroSecondsLeft = 0
    @State private var pomodoroCount       = 0

    // Sheets / alerts
    @State private var showAddRoutine  = false
    @State private var newRoutineName  = ""
    @State private var routineToDelete: Routine?
    @State private var showDeleteAlert = false

    // Motivation
    @State private var showMotivation  = true

    // Dopamine states
    @State private var showBoostToast    = false
    @State private var boostAmount       = 0
    @State private var showSkinToast     = false
    @State private var newSkinUnlock: RewardCalculator.RabbitSkin? = nil
    @State private var particles: [BurstParticle] = []
    @State private var saveButtonScale: CGFloat    = 1.0
    @State private var showAlmostThere   = false
    @State private var almostThereMsg    = ""
    @State private var showDemoBanner    = false

    private let totalGoalHours = 1000

    var body: some View {
        NavigationStack {
            ZStack {
                Color(r: 10, g: 10, b: 46).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        addButton

                        if routines.isEmpty {
                            emptyState
                        } else {
                            routinePicker
                            if let routine = selectedRoutine {
                                milestoneCard(routine: routine)
                                if showMotivation && routine.totalHours < 1 {
                                    motivationBanner
                                }
                                // Almost-there nudge (pomodoro milestone approach)
                                if showAlmostThere {
                                    almostThereBanner
                                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                                }
                                pomodoroSelector
                                timerCard
                                recentSessions(for: routine)
                            }
                        }
                    }
                    .padding()
                }

                // Burst particles overlay
                ForEach(particles) { p in
                    Text(p.symbol)
                        .font(.caption)
                        .position(x: p.x, y: p.y)
                        .opacity(p.opacity)
                        .scaleEffect(p.scale)
                }

                // Variable rabbit boost toast
                if showBoostToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 10) {
                            Text("🐰").font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("+\(boostAmount)s Rabbit Boost!")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                Text("5 min practice — your rabbit hops faster!")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.purple.opacity(0.9), in: RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .zIndex(1)
                }

                // Skin unlock toast
                if showSkinToast, let skin = newSkinUnlock {
                    VStack {
                        Spacer()
                        HStack(spacing: 12) {
                            Text(skin.emoji).font(.title)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("New Rabbit Unlocked!")
                                    .font(.subheadline.bold()).foregroundStyle(.white)
                                Text(skin.unlockMessage)
                                    .font(.caption).foregroundStyle(.white.opacity(0.7))
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(
                            LinearGradient(colors: [.purple, .blue.opacity(0.8)],
                                           startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 90)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .zIndex(2)
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
                                Text("Piano Practice loaded — 47h progress")
                                    .font(.caption).foregroundStyle(.white.opacity(0.7))
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.indigo.opacity(0.92), in: RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal).padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .zIndex(3)
                }
            }
            .navigationTitle("Practice")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(r: 10, g: 10, b: 46), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            DemoManager.loadDemo(context: context)
                            // Auto-select the demo routine
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                selectedRoutine = routines.first
                            }
                            withAnimation(.spring()) { showDemoBanner = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation { showDemoBanner = false }
                            }
                        } label: {
                            Label("Load Demo Day", systemImage: "play.rectangle.fill")
                        }
                        Button(role: .destructive) {
                            DemoManager.resetDemo(context: context)
                            selectedRoutine = nil
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
            .onAppear {
                if selectedRoutine == nil { selectedRoutine = routines.first }
            }
            .sheet(isPresented: $showAddRoutine) { addRoutineSheet }
            .alert("Delete Routine", isPresented: $showDeleteAlert, presenting: routineToDelete) { routine in
                Button("Delete", role: .destructive) { deleteRoutine(routine) }
                Button("Cancel", role: .cancel) {}
            } message: { routine in
                Text("\"\(routine.name)\" and all its sessions will be permanently deleted.")
            }
        }
    }

    // MARK: - Sub-views

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("🎯").font(.system(size: 48))
            Text("Add a practice routine\nto start your 1000-hour journey")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    private var routinePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(routines) { routine in
                    Button {
                        guard selectedRoutine?.id != routine.id else { return }
                        stopTimer()
                        selectedRoutine = routine
                        showMotivation = true
                    } label: {
                        Text(routine.name)
                            .font(.subheadline.bold())
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                selectedRoutine?.id == routine.id ? Color.purple : Color.white.opacity(0.1),
                                in: RoundedRectangle(cornerRadius: 20)
                            )
                            .foregroundStyle(.white)
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            routineToDelete = routine
                            showDeleteAlert = true
                        } label: {
                            Label("Delete Routine", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private func milestoneCard(routine: Routine) -> some View {
        let hours     = routine.totalHours
        let progress  = min(1.0, hours / Double(totalGoalHours))
        let percent   = progress * 100
        let remaining = max(0, Double(totalGoalHours) - hours)
        let skin      = RewardCalculator.currentSkin(forHours: hours)
        let nextSkin  = RewardCalculator.nextSkin(forHours: hours)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    // Routine name with current skin emoji
                    HStack(spacing: 6) {
                        Text(skin.emoji)
                        Text(routine.name)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    Text(milestoneLabel(hours: hours))
                        .font(.caption)
                        .foregroundStyle(.purple.opacity(0.9))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f", hours))
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("/ \(totalGoalHours) hrs")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            // Progress bar with milestone ticks
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.white.opacity(0.08))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(colors: [.purple, .blue.opacity(0.8)],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(0, geo.size.width * progress), height: 10)
                        .animation(.easeInOut(duration: 0.4), value: progress)
                    ForEach([100, 250, 500, 750], id: \.self) { mark in
                        let x = geo.size.width * (Double(mark) / Double(totalGoalHours))
                        Rectangle()
                            .fill(.white.opacity(hours >= Double(mark) ? 0.6 : 0.2))
                            .frame(width: 2, height: 10)
                            .offset(x: x)
                    }
                }
            }
            .frame(height: 10)

            HStack {
                Text(String(format: "%.1f%%", percent))
                    .font(.caption2.bold())
                    .foregroundStyle(.purple)
                Spacer()
                if remaining > 0 {
                    // Show progress to next skin unlock
                    if let next = nextSkin {
                        Text(String(format: "%.0fh to %@", next.unlockHours - hours, next.emoji))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.35))
                    }
                } else {
                    Text("🏆 1000 Hours Mastered!")
                        .font(.caption2.bold())
                        .foregroundStyle(.yellow)
                }
            }

            HStack {
                Spacer()
                Button {
                    routineToDelete = routine
                    showDeleteAlert = true
                } label: {
                    Label("Delete Routine", systemImage: "trash")
                        .font(.caption2)
                        .foregroundStyle(.red.opacity(0.6))
                }
            }
        }
        .padding(16)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
    }

    private var motivationBanner: some View {
        HStack(spacing: 12) {
            Text("🐰").font(.title2)
            VStack(alignment: .leading, spacing: 3) {
                Text("Just 5 minutes today")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text("Every master started at zero. One small hop is all it takes.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
            Button {
                withAnimation { showMotivation = false }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(14)
        .background(
            LinearGradient(colors: [.purple.opacity(0.25), .blue.opacity(0.15)],
                           startPoint: .leading, endPoint: .trailing),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.purple.opacity(0.3), lineWidth: 1))
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    private var almostThereBanner: some View {
        HStack(spacing: 10) {
            Text(almostThereMsg)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(
            LinearGradient(colors: [.orange.opacity(0.3), .red.opacity(0.15)],
                           startPoint: .leading, endPoint: .trailing),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.orange.opacity(0.4), lineWidth: 1))
    }

    private var pomodoroSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Timer Mode")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.4))

            HStack(spacing: 8) {
                ForEach(PomodoroMode.allCases, id: \.rawValue) { mode in
                    Button {
                        guard !isRunning else { return }
                        pomodoroMode = mode
                        resetPomodoroState()
                    } label: {
                        VStack(spacing: 3) {
                            Text(mode.emoji).font(.title3)
                            Text(mode.label)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(pomodoroMode == mode ? .white : .white.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            pomodoroMode == mode ? Color.purple.opacity(0.35) : Color.white.opacity(0.05),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                        .overlay(
                            pomodoroMode == mode
                                ? RoundedRectangle(cornerRadius: 10).stroke(.purple.opacity(0.5), lineWidth: 1)
                                : nil
                        )
                    }
                    .disabled(isRunning)
                    .opacity(isRunning && pomodoroMode != mode ? 0.4 : 1)
                }
            }

            if pomodoroMode != .off {
                HStack(spacing: 6) {
                    Label("\(pomodoroMode.workMinutes) min focus", systemImage: "brain.head.profile")
                        .font(.caption2)
                        .foregroundStyle(.purple.opacity(0.8))
                    Text("·").foregroundStyle(.white.opacity(0.2))
                    Label("\(pomodoroMode.restMinutes) min rest", systemImage: "leaf")
                        .font(.caption2)
                        .foregroundStyle(.green.opacity(0.8))
                    if pomodoroCount > 0 {
                        Spacer()
                        Text("\(pomodoroCount) 🍅 done")
                            .font(.caption2.bold())
                            .foregroundStyle(.orange.opacity(0.8))
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
    }

    private var timerCard: some View {
        VStack(spacing: 20) {
            if pomodoroMode != .off {
                HStack(spacing: 8) {
                    Circle()
                        .fill(pomodoroPhase.color)
                        .frame(width: 8, height: 8)
                    Text(pomodoroPhase.label.uppercased())
                        .font(.caption.bold())
                        .tracking(2)
                        .foregroundStyle(pomodoroPhase.color)
                }
            }

            ZStack {
                if pomodoroMode != .off {
                    let total  = Double((pomodoroPhase == .work ? pomodoroMode.workMinutes : pomodoroMode.restMinutes) * 60)
                    let remain = Double(pomodoroSecondsLeft)
                    Circle()
                        .stroke(.white.opacity(0.06), lineWidth: 6)
                        .frame(width: 160, height: 160)
                    Circle()
                        .trim(from: 0, to: total > 0 ? remain / total : 0)
                        .stroke(pomodoroPhase.color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 160, height: 160)
                        .animation(.linear(duration: 1), value: pomodoroSecondsLeft)

                    VStack(spacing: 4) {
                        Text(formatTime(pomodoroSecondsLeft))
                            .font(.system(size: 38, weight: .thin, design: .monospaced))
                            .foregroundStyle(.white)
                        Text(String(format: "+%@", formatCompact(elapsedSeconds)))
                            .font(.caption2.monospaced())
                            .foregroundStyle(.white.opacity(0.3))
                    }
                } else {
                    Text(formatTime(elapsedSeconds))
                        .font(.system(size: 56, weight: .thin, design: .monospaced))
                        .foregroundStyle(.white)
                }
            }
            .frame(height: pomodoroMode != .off ? 160 : 70)

            HStack(spacing: 16) {
                Button(action: toggleTimer) {
                    Label(isRunning ? "Pause" : (elapsedSeconds == 0 && pomodoroSecondsLeft == 0 ? "Start" : "Resume"),
                          systemImage: isRunning ? "pause.fill" : "play.fill")
                        .frame(minWidth: 110)
                        .padding(.vertical, 14)
                        .background(isRunning ? Color.orange : Color.purple,
                                    in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                        .font(.headline)
                }

                // Save button pulses every 5 minutes to draw attention
                if !isRunning && elapsedSeconds > 0 {
                    Button(action: saveSession) {
                        Label("Save", systemImage: "checkmark.circle.fill")
                            .frame(minWidth: 110)
                            .padding(.vertical, 14)
                            .background(Color.green, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.white)
                            .font(.headline)
                    }
                    .scaleEffect(saveButtonScale)
                }
            }

            if elapsedSeconds == 0 && !isRunning {
                Button {
                    startFiveMinuteBoost()
                } label: {
                    Label("Quick 5-min start 🐰", systemImage: "bolt.fill")
                        .font(.subheadline)
                        .foregroundStyle(.purple)
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(.purple.opacity(0.12), in: Capsule())
                }
            }
        }
        .padding(20)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
        .onChange(of: elapsedSeconds) { _, newValue in
            // Pulse save button every 5 minutes
            if newValue % 300 == 0 && newValue > 0 { pulseSaveButton() }
            // Almost-there nudge 5 min before a pomodoro milestone
            checkAlmostThere(newValue)
        }
    }

    private func recentSessions(for routine: Routine) -> some View {
        let routineLogs = logs.filter { $0.routineID == routine.id }.prefix(5)
        guard !routineLogs.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                Text("Recent Sessions")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white.opacity(0.5))
                ForEach(Array(routineLogs), id: \.id) { log in
                    HStack {
                        Text(log.date, format: .dateTime.month().day())
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                        Spacer()
                        Text(log.formattedDuration)
                            .font(.caption.monospaced())
                            .foregroundStyle(.purple)
                    }
                    .padding(.vertical, 4)
                    Divider().background(.white.opacity(0.1))
                }
            }
        )
    }

    private var addButton: some View {
        Button(action: { showAddRoutine = true }) {
            Label("New Practice", systemImage: "plus.circle")
                .font(.subheadline)
                .foregroundStyle(.purple)
        }
    }

    private var addRoutineSheet: some View {
        NavigationStack {
            ZStack {
                Color(r: 10, g: 10, b: 46).ignoresSafeArea()
                VStack(spacing: 16) {
                    TextField("Routine name (e.g. Piano)", text: $newRoutineName)
                        .textFieldStyle(.plain)
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

                    Text("Your goal: 1000 hours of deliberate practice.\nEvery minute counts. 🌾")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                        .multilineTextAlignment(.center)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(r: 10, g: 10, b: 46), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddRoutine = false }.foregroundStyle(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let r = Routine(name: newRoutineName)
                        context.insert(r)
                        selectedRoutine = r
                        newRoutineName = ""
                        showAddRoutine = false
                        showMotivation = true
                    }
                    .disabled(newRoutineName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundStyle(.purple)
                }
            }
        }
    }

    // MARK: - Timer Logic

    private func toggleTimer() {
        isRunning ? stopTimer() : startTimer()
    }

    private func startTimer() {
        if pomodoroMode != .off && pomodoroSecondsLeft == 0 {
            pomodoroSecondsLeft = pomodoroMode.workMinutes * 60
            pomodoroPhase = .work
        }
        isRunning = true
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                await MainActor.run { tick() }
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel(); timerTask = nil; isRunning = false
    }

    private func tick() {
        elapsedSeconds += 1
        if pomodoroMode != .off {
            if pomodoroSecondsLeft > 0 { pomodoroSecondsLeft -= 1 }
            if pomodoroSecondsLeft == 0 {
                if pomodoroPhase == .work {
                    pomodoroCount += 1
                    pomodoroPhase = .rest
                    pomodoroSecondsLeft = pomodoroMode.restMinutes * 60
                } else {
                    pomodoroPhase = .work
                    pomodoroSecondsLeft = pomodoroMode.workMinutes * 60
                }
            }
        }
    }

    private func startFiveMinuteBoost() {
        if pomodoroMode == .off { pomodoroMode = .classic }
        pomodoroSecondsLeft = 5 * 60
        pomodoroPhase = .work
        startTimer()
    }

    private func saveSession() {
        guard let routine = selectedRoutine, elapsedSeconds > 0 else { return }
        let sessionSeconds = elapsedSeconds

        // Snapshot skin before adding hours — for unlock detection
        let hoursBefore = routine.totalHours
        let skinBefore  = RewardCalculator.currentSkin(forHours: hoursBefore)

        let log = SessionLog(routineID: routine.id, durationSeconds: sessionSeconds)
        context.insert(log)
        routine.addSeconds(sessionSeconds)

        // Update ProgressState.totalPracticeHours (sum of all routines)
        if let s = state {
            s.totalPracticeHours = routines.reduce(0) { $0 + $1.totalHours }
        }

        elapsedSeconds = 0
        pomodoroCount  = 0
        resetPomodoroState()
        stopTimer()
        withAnimation { showAlmostThere = false }
        try? context.save()

        // Check for new skin unlock
        let hoursAfter = routine.totalHours
        let skinAfter  = RewardCalculator.currentSkin(forHours: hoursAfter)
        if skinAfter.unlockHours > skinBefore.unlockHours {
            newSkinUnlock = skinAfter
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring()) { showSkinToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                    withAnimation { showSkinToast = false }
                }
            }
        }

        // Variable rabbit boost (random 8–15s)
        let boost = RewardCalculator.rabbitBoost(forSessionSeconds: sessionSeconds)
        if boost > 0 {
            boostAmount = boost
            triggerParticleBurst()
            withAnimation(.spring()) { showBoostToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { showBoostToast = false }
            }
        }
    }

    private func resetPomodoroState() {
        pomodoroSecondsLeft = 0; pomodoroPhase = .work; pomodoroCount = 0
    }

    private func deleteRoutine(_ routine: Routine) {
        if selectedRoutine?.id == routine.id {
            stopTimer(); elapsedSeconds = 0; resetPomodoroState()
        }
        logs.filter { $0.routineID == routine.id }.forEach { context.delete($0) }
        context.delete(routine)
        if selectedRoutine?.id == routine.id {
            selectedRoutine = routines.first(where: { $0.id != routine.id })
        }
    }

    // MARK: - Dopamine Helpers

    /// Pulses the save button with a spring bounce — called every 5 minutes while paused.
    private func pulseSaveButton() {
        withAnimation(.interpolatingSpring(stiffness: 500, damping: 8)) { saveButtonScale = 1.15 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 12)) { saveButtonScale = 1.0 }
        }
    }

    /// 🌾⭐️✨ particle burst from screen center when a session is saved.
    private func triggerParticleBurst() {
        let center = CGPoint(x: UIScreen.main.bounds.width / 2, y: 400)
        let symbols = ["🌾", "⭐️", "✨"]
        var newP: [BurstParticle] = []
        for i in 0..<12 {
            let angle  = Double(i) * (360.0 / 12.0) * .pi / 180
            let radius = CGFloat.random(in: 40...100)
            newP.append(BurstParticle(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius,
                symbol: symbols[i % symbols.count]
            ))
        }
        particles = newP
        withAnimation(.easeOut(duration: 0.8)) {
            particles = particles.map { var p = $0; p.opacity = 0; p.scale = 0.2; return p }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { particles = [] }
    }

    /// Shows "almost there" nudge 5 minutes before a round pomodoro milestone.
    private func checkAlmostThere(_ seconds: Int) {
        guard pomodoroMode != .off && isRunning && pomodoroPhase == .work else { return }
        let elapsed = seconds / 60
        for target in [30, 60, 90, 120] where elapsed == target - 5 {
            almostThereMsg = "⚡️ 5 minutes to \(target)min milestone — keep going!"
            withAnimation { showAlmostThere = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                withAnimation { showAlmostThere = false }
            }
            return
        }
    }

    // MARK: - Formatters

    private func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600; let m = (seconds % 3600) / 60; let s = seconds % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%02d:%02d", m, s)
    }

    private func formatCompact(_ seconds: Int) -> String {
        let m = seconds / 60; let s = seconds % 60
        return m > 0 ? "\(m)m \(s)s total" : "\(s)s total"
    }

    private func milestoneLabel(hours: Double) -> String {
        switch hours {
        case 0..<1:    return "🌱 Getting started — just show up!"
        case 1..<10:   return "🌿 Building the habit"
        case 10..<50:  return "🌸 Finding your rhythm"
        case 50..<100: return "⚡️ Momentum building"
        case 100..<250:return "🔥 100 hours in — real progress!"
        case 250..<500:return "💎 Quarter of the way there"
        case 500..<750:return "🌕 Halfway to mastery"
        case 750..<999:return "🏅 Almost legendary"
        default:       return "🏆 1000 Hours — You're a Master!"
        }
    }
}
