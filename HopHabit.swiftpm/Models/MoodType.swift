//
//  MoodCheckIn.swift
//  HopHabit


import SwiftUI
import SwiftData


enum MoodType: Int, Codable, CaseIterable {
    case happy   = 1
    case neutral = 2
    case sad     = 3

    var label: String {
        switch self {
        case .happy:   return "Happy"
        case .neutral: return "Okay"
        case .sad:     return "Rough"
        }
    }

    var color: Color {
        switch self {
        case .happy:   return Color(red: 0.55, green: 0.90, blue: 0.55)
        case .neutral: return Color(red: 0.90, green: 0.82, blue: 0.38)
        case .sad:     return Color(red: 0.50, green: 0.65, blue: 1.00)
        }
    }
}

@Model
final class MoodEntry {
    var date: Date
    var moodRaw: Int

    init(date: Date, mood: MoodType) {
        self.date    = Calendar.current.startOfDay(for: date)
        self.moodRaw = mood.rawValue
    }

    var mood: MoodType {
        get { MoodType(rawValue: moodRaw) ?? .neutral }
        set { moodRaw = newValue.rawValue }
    }
}

struct RabbitFace: View {
    let mood: MoodType
    let size: CGFloat

    var body: some View {
        Canvas { ctx, sz in
            let s  = sz.width / 24
            let cx = sz.width  / 2
            let cy = sz.height / 2 + s * 2

            
            let earW: CGFloat = s * 3
            let earH: CGFloat = s * 8
            let earY: CGFloat = cy - s * 11

            for ex in [cx - s * 4, cx + s * 1.5] {
                var ear = Path()
                ear.addRoundedRect(in: CGRect(x: ex, y: earY, width: earW, height: earH),
                                   cornerSize: CGSize(width: earW / 2, height: earW / 2))
                ctx.fill(ear, with: .color(.white))

                var inner = Path()
                let iw = earW * 0.55
                inner.addRoundedRect(
                    in: CGRect(x: ex + earW * 0.22, y: earY + s, width: iw, height: earH * 0.72),
                    cornerSize: CGSize(width: iw / 2, height: iw / 2))
                ctx.fill(inner, with: .color(Color(red: 0.95, green: 0.70, blue: 0.75)))
            }

            
            var head = Path()
            head.addEllipse(in: CGRect(x: cx - s*7, y: cy - s*7, width: s*14, height: s*12))
            ctx.fill(head, with: .color(.white))

            
            let eyeY = cy - s * 1.5
            switch mood {
            case .happy:
                for ex in [cx - s*3, cx + s*1.8] {
                    var arc = Path()
                    arc.move(to: CGPoint(x: ex, y: eyeY))
                    arc.addQuadCurve(to:      CGPoint(x: ex + s*1.8, y: eyeY),
                                     control: CGPoint(x: ex + s*0.9, y: eyeY - s*1.4))
                    ctx.stroke(arc, with: .color(.black),
                               style: StrokeStyle(lineWidth: s*0.8, lineCap: .round))
                }
            case .neutral, .sad:
                for ex in [cx - s*3.2, cx + s*1.5] {
                    var eye = Path()
                    eye.addEllipse(in: CGRect(x: ex, y: eyeY - s, width: s*1.8, height: s*2))
                    ctx.fill(eye, with: .color(.black))
                }
                if mood == .sad {
                    var tear = Path()
                    tear.addEllipse(in: CGRect(x: cx - s*2.2, y: eyeY + s*1.5,
                                              width: s*0.9, height: s*1.6))
                    ctx.fill(tear, with: .color(Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.85)))
                }
            }

            
            var nose = Path()
            nose.addEllipse(in: CGRect(x: cx - s*0.7, y: cy + s, width: s*1.4, height: s))
            ctx.fill(nose, with: .color(Color(red: 0.95, green: 0.65, blue: 0.70)))

            
            switch mood {
            case .happy:
                var m = Path()
                m.move(to:    CGPoint(x: cx - s*2.5, y: cy + s*2.5))
                m.addQuadCurve(to:      CGPoint(x: cx + s*2.5, y: cy + s*2.5),
                               control: CGPoint(x: cx, y: cy + s*4.5))
                ctx.stroke(m, with: .color(.black),
                           style: StrokeStyle(lineWidth: s*0.75, lineCap: .round))
            case .neutral:
                var m = Path()
                m.move(to:    CGPoint(x: cx - s*2, y: cy + s*3))
                m.addLine(to: CGPoint(x: cx + s*2, y: cy + s*3))
                ctx.stroke(m, with: .color(.black),
                           style: StrokeStyle(lineWidth: s*0.65, lineCap: .round))
            case .sad:
                var m = Path()
                m.move(to:    CGPoint(x: cx - s*2.5, y: cy + s*3.5))
                m.addQuadCurve(to:      CGPoint(x: cx + s*2.5, y: cy + s*3.5),
                               control: CGPoint(x: cx, y: cy + s*1.8))
                ctx.stroke(m, with: .color(.black),
                           style: StrokeStyle(lineWidth: s*0.75, lineCap: .round))
            }

           
            if mood != .neutral {
                let blush = Color(red: 1.0, green: 0.65, blue: 0.70).opacity(0.50)
                for bx in [cx - s*5.2, cx + s*3.0] {
                    var b = Path()
                    b.addEllipse(in: CGRect(x: bx, y: cy + s*0.5, width: s*2.2, height: s*0.9))
                    ctx.fill(b, with: .color(blush))
                }
            }
        }
        .frame(width: size, height: size)
    }
}

struct MoodHistoryRow: View {
    let allMoods: [MoodEntry]

    private var last7: [(date: Date, entry: MoodEntry?)] {
        let cal = Calendar.current
       
        return (0..<7).map { i -> (Date, MoodEntry?) in
            let daysBack = 6 - i
            let d = cal.startOfDay(
                for: cal.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
            )
            let entry = allMoods.first { cal.isDate($0.date, inSameDayAs: d) }
            return (d, entry)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mood · Last 7 Days")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.45))

            HStack(spacing: 0) {
                ForEach(last7, id: \.date) { item in
                    VStack(spacing: 4) {
                        if let entry = item.entry {
                            RabbitFace(mood: entry.mood, size: 32)
                                .transition(.scale(scale: 0.5).combined(with: .opacity))
                        } else {
                            Circle()
                                .stroke(.white.opacity(0.15), lineWidth: 1.5)
                                .frame(width: 32, height: 32)
                        }
                        Text(item.date, format: .dateTime.weekday(.narrow))
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    .frame(maxWidth: .infinity)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: item.entry != nil)
                }
            }
        }
        .padding(14)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}



struct MoodCheckInSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    let date: Date

    @Query(sort: \MoodEntry.date, order: .reverse)
    private var allMoods: [MoodEntry]

    private var existingEntry: MoodEntry? {
        allMoods.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    @State private var selected: MoodType? = nil
    @State private var bounceIdx: Int?     = nil
    @State private var saved               = false
    
    private var saveButtonColor: Color {
        if saved { return .green }
        if let m = selected { return m.color }
        return Color.white.opacity(0.07)
    }

    var body: some View {
        VStack(spacing: 0) {
      
            Capsule()
                .fill(.white.opacity(0.20))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 22)

            VStack(spacing: 4) {
                Text("How did today feel?")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.40))
            }
            .padding(.bottom, 26)

            HStack(spacing: 14) {
                ForEach(Array(MoodType.allCases.enumerated()), id: \.offset) { idx, mood in
                    rabbitButton(mood: mood, idx: idx)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)

    
            Button(action: saveMood) {
                HStack(spacing: 8) {
                    if saved {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text(saved
                         ? "Saved!"
                         : (selected == nil ? "Pick a mood first" : "Save Mood"))
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(selected == nil && !saved ? .white.opacity(0.28) : .black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    saveButtonColor,
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .animation(.easeInOut(duration: 0.20), value: selected)
                .animation(.easeInOut(duration: 0.20), value: saved)
            }
            .disabled(selected == nil || saved)
            .padding(.horizontal, 24)

            Spacer()
        }
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.hidden)
        .background(Color(red: 0.07, green: 0.07, blue: 0.20).ignoresSafeArea())
        .onAppear { selected = existingEntry?.mood }
    }

    private func rabbitButton(mood: MoodType, idx: Int) -> some View {
        let isSelected = selected == mood
        let isBouncing = bounceIdx == idx

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.50)) {
                selected  = mood
                bounceIdx = idx
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
                bounceIdx = nil
            }
        } label: {
            VStack(spacing: 8) {
                RabbitFace(mood: mood, size: 64)
                    .scaleEffect(isBouncing ? 1.26 : (isSelected ? 1.08 : 1.0))
                    .animation(.spring(response: 0.26, dampingFraction: 0.44), value: isBouncing)
                    .animation(.spring(response: 0.26, dampingFraction: 0.60), value: isSelected)

                Text(mood.label)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? mood.color : .white.opacity(0.38))
                    .animation(.easeInOut(duration: 0.15), value: isSelected)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                isSelected ? mood.color.opacity(0.15) : Color.white.opacity(0.04),
                in: RoundedRectangle(cornerRadius: 18)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? mood.color.opacity(0.60) : Color.clear, lineWidth: 1.5)
            )
            .animation(.easeInOut(duration: 0.16), value: isSelected)
        }
    }

    private func saveMood() {
        guard let mood = selected else { return }

        if let entry = existingEntry {
            entry.mood = mood
        } else {
            context.insert(MoodEntry(date: date, mood: mood))
        }

        do {
            try context.save()
        } catch {
            print("⚠️ MoodCheckIn save failed: \(error)")
        }

        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { dismiss() }
    }
}
