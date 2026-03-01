//
//  ChecklistView.swift
//  HopHabit
//
//  Created by Giyu Tomioka on 2/28/26.
//

import SwiftUI
import SwiftData

struct ChecklistView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TaskItem.createdAt) private var allTasks: [TaskItem]
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    @State private var newTaskTitle = ""
    @State private var showAddHabit = false
    @State private var newHabitTitle = ""

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
                Color( "0A0A2E").ignoresSafeArea()

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

                        // Habits section
                        SectionHeader(title: "Daily Habits", icon: "repeat.circle.fill", color: .indigo)

                        ForEach(todayHabits) { habit in
                            HabitRow(habit: habit) {
                                habit.toggle()
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
    let onToggle: () -> Void
    private var completed: Bool { habit.isCompleted(on: Date()) }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(completed ? .green : .white.opacity(0.5))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.title)
                    .foregroundStyle(completed ? .white.opacity(0.4) : .white)
                    .strikethrough(completed)
                Text(StreakManager.label(for: habit.currentStreak))
                    .font(.caption2)
                    .foregroundStyle(.indigo.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.2), value: completed)
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
