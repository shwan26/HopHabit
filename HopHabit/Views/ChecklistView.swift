//
//  ChecklistView.swift
//  HopHabit
//
//  Created by Giyu Tomioka on 2/28/26.
//

import SwiftUI
import SwiftData
import Charts
internal import Combine

struct ChecklistView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TaskItem.createdAt) private var allTasks: [TaskItem]
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    @State private var newTaskTitle = ""
    @State private var showAddHabit = false
    @State private var newHabitTitle = ""
    @State private var showTimeChart = false
    @State private var timerTick = Date()  // Forces UI refresh every second

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var todayTasks: [TaskItem] {
        allTasks.filter { Calendar.current.isDateInToday($0.date) }
    }

    private var todayHabits: [Habit] {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return habits.filter { $0.scheduledDays.contains(weekday) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("0A0A2E").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Tasks section
                        SectionHeader(title: "Today's Tasks", icon: "checkmark.square.fill", color: .purple)

                        ForEach(todayTasks) { task in
                            TaskRow(task: task) {
                                task.isCompleted.toggle()
                            } onDelete: {
                                context.delete(task)
                            }
                        }

                        // Add task input
                        HStack {
                            TextField("Add a task…", text: $newTaskTitle)
                                .textFieldStyle(.plain)
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                                .submitLabel(.done)
                                .onSubmit(addTask)

                            Button(action: addTask) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.purple)
                            }
                            .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                        }

                        // Habits section header with chart button
                        HStack {
                            SectionHeader(title: "Daily Habits", icon: "repeat.circle.fill", color: .indigo)
                            Spacer()
                            Button {
                                showTimeChart = true
                            } label: {
                                Label("Time Stats", systemImage: "chart.bar.fill")
                                    .font(.caption.bold())
                                    .foregroundStyle(.indigo)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.indigo.opacity(0.15), in: Capsule())
                            }
                        }

                        ForEach(todayHabits) { habit in
                            HabitRow(habit: habit, tick: timerTick) {
                                habit.toggle()
                            } onTimerToggle: {
                                if habit.isTimerRunning {
                                    habit.stopTimer()
                                } else {
                                    habit.startTimer()
                                }
                            } onDelete: {
                                habit.stopTimer()
                                context.delete(habit)
                            }
                        }

                        // Add habit button
                        Button(action: { showAddHabit = true }) {
                            Label("Add Habit", systemImage: "plus.circle")
                                .font(.subheadline)
                                .foregroundStyle(.indigo)
                        }
                        .padding(.top, 4)
                    }
                    .padding()
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color("0A0A2E"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showAddHabit) {
                AddHabitSheet(isPresented: $showAddHabit)
            }
            .sheet(isPresented: $showTimeChart) {
                HabitTimeChartView(habits: habits)
            }
            .onReceive(timer) { date in
                // Only refresh if any timer is running
                if habits.contains(where: { $0.isTimerRunning }) {
                    timerTick = date
                }
            }
        }
    }

    private func addTask() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        let task = TaskItem(title: title)
        context.insert(task)
        newTaskTitle = ""
    }
}

// MARK: - Task Row

struct TaskRow: View {
    let task: TaskItem
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? .green : .white.opacity(0.5))
            }

            Text(task.title)
                .foregroundStyle(task.isCompleted ? .white.opacity(0.4) : .white)
                .strikethrough(task.isCompleted)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.6))
            }
        }
        .padding(12)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.2), value: task.isCompleted)
    }
}

// MARK: - Habit Row

struct HabitRow: View {
    let habit: Habit
    let tick: Date  // Used to trigger redraws while timer is running
    let onToggle: () -> Void
    let onTimerToggle: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false
    private var completed: Bool { habit.isCompleted(on: Date()) }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(completed ? .green : .white.opacity(0.5))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(habit.title)
                    .foregroundStyle(completed ? .white.opacity(0.4) : .white)
                    .strikethrough(completed)

                HStack(spacing: 8) {
                    Text(StreakManager.label(for: habit.currentStreak))
                        .font(.caption2)
                        .foregroundStyle(.indigo.opacity(0.8))

                    if habit.totalTimeToday > 0 || habit.isTimerRunning {
                        Text("⏱ \(habit.totalTimeToday.formatted)")
                            .font(.caption2)
                            .foregroundStyle(habit.isTimerRunning ? .orange : .white.opacity(0.5))
                            .id(tick)  // Forces redraw on tick
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Timer toggle button
            Button(action: onTimerToggle) {
                Image(systemName: habit.isTimerRunning ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title3)
                    .foregroundStyle(habit.isTimerRunning ? .orange : .white.opacity(0.35))
            }

            // Delete button
            Button {
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.6))
            }
            .confirmationDialog("Delete \"\(habit.title)\"?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete Habit", role: .destructive, action: onDelete)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently remove the habit and all its history.")
            }
        }
        .padding(12)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(habit.isTimerRunning ? .orange.opacity(0.4) : .clear, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: completed)
        .animation(.easeInOut(duration: 0.2), value: habit.isTimerRunning)
    }
}

// MARK: - Habit Time Chart

struct HabitTimeChartView: View {
    let habits: [Habit]
    @Environment(\.dismiss) private var dismiss

    @State private var selectedRange: ChartRange = .week

    enum ChartRange: String, CaseIterable {
        case today = "Today"
        case week = "7 Days"
        case month = "30 Days"

        var days: Int {
            switch self {
            case .today: return 1
            case .week: return 7
            case .month: return 30
            }
        }
    }

    // Data point for the chart
    struct HabitBarEntry: Identifiable {
        let id = UUID()
        let habitTitle: String
        let minutes: Double
    }

    private var chartData: [HabitBarEntry] {
        habits.map { habit in
            let totalSeconds: TimeInterval
            if selectedRange == .today {
                totalSeconds = habit.totalTimeToday
            } else {
                let cal = Calendar.current
                let days = (0..<selectedRange.days).compactMap {
                    cal.date(byAdding: .day, value: -$0, to: Date())
                }
                totalSeconds = days.reduce(0) { $0 + habit.totalTime(on: $1) }
            }
            return HabitBarEntry(habitTitle: habit.title, minutes: totalSeconds / 60)
        }
        .filter { $0.minutes > 0 }
        .sorted { $0.minutes > $1.minutes }
    }

    // Per-day breakdown for the past N days
    struct DayEntry: Identifiable {
        let id = UUID()
        let date: Date
        let habitTitle: String
        let minutes: Double
    }

    private var dailyData: [DayEntry] {
        let cal = Calendar.current
        let days = (0..<min(selectedRange.days, 7)).compactMap {
            cal.date(byAdding: .day, value: -$0, to: Date())
        }.reversed()

        return days.flatMap { date in
            habits.map { habit in
                DayEntry(date: date, habitTitle: habit.title, minutes: habit.totalTime(on: date) / 60)
            }
        }
        .filter { $0.minutes > 0 }
    }

    private var totalTime: TimeInterval {
        habits.reduce(0) { sum, habit in
            if selectedRange == .today {
                return sum + habit.totalTimeToday
            } else {
                let cal = Calendar.current
                let days = (0..<selectedRange.days).compactMap {
                    cal.date(byAdding: .day, value: -$0, to: Date())
                }
                return sum + days.reduce(0) { $0 + habit.totalTime(on: $1) }
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("0A0A2E").ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Range picker
                        Picker("Range", selection: $selectedRange) {
                            ForEach(ChartRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        // Summary card
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Time")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.5))
                                Text(totalTime.formatted)
                                    .font(.title2.bold())
                                    .foregroundStyle(.white)
                            }
                            Spacer()
                            Image(systemName: "clock.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.indigo.opacity(0.7))
                        }
                        .padding(16)
                        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)

                        if chartData.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "chart.bar.xaxis")
                                    .font(.system(size: 44))
                                    .foregroundStyle(.white.opacity(0.2))
                                Text("No time tracked yet")
                                    .foregroundStyle(.white.opacity(0.4))
                                    .font(.subheadline)
                                Text("Tap ▶ next to a habit to start timing.")
                                    .foregroundStyle(.white.opacity(0.25))
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        } else {
                            // Bar chart: time per habit
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Time Per Habit")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal)

                                Chart(chartData) { entry in
                                    BarMark(
                                        x: .value("Minutes", entry.minutes),
                                        y: .value("Habit", entry.habitTitle)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.indigo, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(6)
                                    .annotation(position: .trailing) {
                                        Text(TimeInterval(entry.minutes * 60).formatted)
                                            .font(.caption2)
                                            .foregroundStyle(.white.opacity(0.6))
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks(values: .automatic) { value in
                                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                            .foregroundStyle(.white.opacity(0.1))
                                        AxisValueLabel {
                                            if let m = value.as(Double.self) {
                                                Text("\(Int(m))m")
                                                    .font(.caption2)
                                                    .foregroundStyle(.white.opacity(0.4))
                                            }
                                        }
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks { value in
                                        AxisValueLabel {
                                            if let title = value.as(String.self) {
                                                Text(title)
                                                    .font(.caption2)
                                                    .foregroundStyle(.white.opacity(0.7))
                                            }
                                        }
                                    }
                                }
                                .frame(height: max(120, CGFloat(chartData.count) * 52))
                                .padding(.horizontal)
                            }

                            // Stacked line chart: time by day
                            if selectedRange != .today && !dailyData.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Daily Breakdown")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal)

                                    Chart(dailyData) { entry in
                                        BarMark(
                                            x: .value("Day", entry.date, unit: .day),
                                            y: .value("Minutes", entry.minutes)
                                        )
                                        .foregroundStyle(by: .value("Habit", entry.habitTitle))
                                        .cornerRadius(4)
                                    }
                                    .chartForegroundStyleScale(range: habitColorGradients)
                                    .chartXAxis {
                                        AxisMarks(values: .stride(by: .day)) { value in
                                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                                .foregroundStyle(.white.opacity(0.1))
                                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                                .foregroundStyle(.white.opacity(0.5))
                                        }
                                    }
                                    .chartYAxis {
                                        AxisMarks { value in
                                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                                .foregroundStyle(.white.opacity(0.1))
                                            AxisValueLabel {
                                                if let m = value.as(Double.self) {
                                                    Text("\(Int(m))m")
                                                        .font(.caption2)
                                                        .foregroundStyle(.white.opacity(0.4))
                                                }
                                            }
                                        }
                                    }
                                    .chartLegend(position: .bottom, alignment: .leading)
                                    .frame(height: 180)
                                    .padding(.horizontal)
                                }
                            }

                            // Rank list
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Ranking")
                                    .font(.headline)
                                    .foregroundStyle(.white)

                                ForEach(Array(chartData.enumerated()), id: \.element.id) { index, entry in
                                    HStack(spacing: 12) {
                                        Text("#\(index + 1)")
                                            .font(.caption.bold())
                                            .foregroundStyle(index == 0 ? .yellow : .white.opacity(0.4))
                                            .frame(width: 28)

                                        Text(entry.habitTitle)
                                            .foregroundStyle(.white)
                                            .frame(maxWidth: .infinity, alignment: .leading)

                                        Text(TimeInterval(entry.minutes * 60).formatted)
                                            .font(.caption.bold())
                                            .foregroundStyle(.indigo)
                                    }
                                    .padding(10)
                                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                                }
                            }
                            .padding(.horizontal)
                        }

                        Spacer(minLength: 32)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Time Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("0A0A2E"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.purple)
                }
            }
        }
    }

    // Distinct colors for different habits in the stacked chart
    private var habitColorGradients: [Color] {
        [.indigo, .purple, .cyan, .teal, .mint, .blue, .pink]
    }
}

// MARK: - Add Habit Sheet

struct AddHabitSheet: View {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var context
    @State private var title = ""
    @State private var selectedDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7]

    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color("0A0A2E").ignoresSafeArea()
                VStack(alignment: .leading, spacing: 20) {
                    TextField("Habit name", text: $title)
                        .textFieldStyle(.plain)
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

                    Text("Repeat on")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))

                    HStack(spacing: 8) {
                        ForEach(1...7, id: \.self) { day in
                            let active = selectedDays.contains(day)
                            Button(dayNames[day - 1]) {
                                if active { selectedDays.remove(day) } else { selectedDays.insert(day) }
                            }
                            .font(.caption.bold())
                            .frame(width: 40, height: 36)
                            .background(active ? Color.indigo : .white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(.white)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }.foregroundStyle(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                        .foregroundStyle(.purple)
                }
            }
        }
    }

    private func save() {
        let habit = Habit(title: title.trimmingCharacters(in: .whitespaces), scheduledDays: Array(selectedDays))
        context.insert(habit)
        isPresented = false
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .foregroundStyle(color)
    }
}
