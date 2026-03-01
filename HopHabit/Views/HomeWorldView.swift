//
//  HomeWorldView.swift
//  HopHabit
//

import SwiftUI
import SwiftData

// MARK: - Particles

struct FallingStar: Identifiable {
    let id      = UUID()
    let startX  = CGFloat.random(in: 30...360)
    let startY  = CGFloat.random(in: 30...100)
    let size    = CGFloat.random(in: 2...4)
    let speed   = Double.random(in: 0.8...1.5)
    let drift   = CGFloat.random(in: -40...40)
}

struct RiceGrain: Identifiable {
    let id       = UUID()
    let startX   = CGFloat.random(in: -60...60)
    let startY   = CGFloat.random(in: -20...20)
    let endX     = CGFloat.random(in: -30...30)
    let endY     = CGFloat.random(in: 160...200)
    let rotation = Double.random(in: 0...360)
}

// MARK: - HomeWorldView

struct HomeWorldView: View {
    @Environment(\.modelContext) private var context
    @Query private var progressStates: [ProgressState]
    @Query private var tasks: [TaskItem]
    @Query private var habits: [Habit]

    @State private var showCelebration    = false
    @State private var rabbitAnimProgress: CGFloat = 0
    @State private var grandpaMessage     = ""
    @State private var showMessage        = false
    @State private var riceScale: CGFloat = 1.0
    @State private var rabbitJumping      = false
    @State private var fallingStars: [FallingStar] = []
    @State private var flyingGrains: [RiceGrain]   = []
    @State private var moonShake          = false

    // ── FIXED: state is now an @State var, initialized safely in .onAppear
    //    Never call context.insert() inside a computed property — SwiftUI
    //    re-evaluates computed vars on every render, which would create
    //    duplicate ProgressState objects and never persist any of them.
    @State private var progressState: ProgressState? = nil

    private var state: ProgressState? { progressState }

    private var todayTasks: [TaskItem] {
        tasks.filter { Calendar.current.isDateInToday($0.date) }
    }
    private var todayHabits: [Habit] {
        let w = Calendar.current.component(.weekday, from: Date())
        return habits.filter { $0.scheduledDays.contains(w) }
    }
    private var completionPercent: Double {
        let total = todayTasks.count + todayHabits.count
        guard total > 0 else { return 0 }
        let done = todayTasks.filter(\.isCompleted).count
                 + todayHabits.filter { $0.isCompleted(on: Date()) }.count
        return Double(done) / Double(total)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [Color(r: 8, g: 8, b: 28),
                             Color(r: 14, g: 14, b: 46),
                             Color(r: 10, g: 10, b: 36)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerView
                        moonScene
                        infoCards
                        completeDayButton
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 32)
                    }
                }

                ForEach(fallingStars) {
                    FallingStarView(star: $0, containerHeight: geo.size.height)
                }
                ForEach(flyingGrains) {
                    FlyingRiceGrainView(grain: $0, containerWidth: geo.size.width)
                }

                if showCelebration {
                    CelebrationOverlay(riceEarned: RewardCalculator.riceEarned(
                        completedTasks: todayTasks.filter(\.isCompleted).count,
                        totalTasks: todayTasks.count,
                        completedHabits: todayHabits.filter { $0.isCompleted(on: Date()) }.count,
                        totalHabits: todayHabits.count
                    ))
                    .transition(.scale.combined(with: .opacity))
                    .onTapGesture { withAnimation { showCelebration = false } }
                }

                if showMessage {
                    quoteBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .navigationTitle("")
        }
        // ── FIXED: create ProgressState here, once, safely on the main actor
        .onAppear { ensureProgressState() }
        // ── Keep @State in sync if the query result changes (e.g. after iCloud sync)
        .onChange(of: progressStates) { _, states in
            if progressState == nil { progressState = states.first }
        }
    }

    // MARK: ── Ensure ProgressState exists ───────────────────────────────────

    private func ensureProgressState() {
        if let existing = progressStates.first {
            progressState = existing
        } else {
            let s = ProgressState()
            context.insert(s)
            try? context.save()   // ← persist immediately so it survives a kill
            progressState = s
        }
    }

    // MARK: ── Header ─────────────────────────────────────────────────────

    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("HopHabit")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            HStack(spacing: 6) {
                Text("🌾").font(.system(size: 18))
                Text("\(state?.totalRiceEarned ?? 0)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(r: 255, g: 220, b: 80))
                    .contentTransition(.numericText())
                    .animation(.spring(), value: state?.totalRiceEarned)
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(r: 50, g: 38, b: 5))
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(r: 180, g: 140, b: 30).opacity(0.6), lineWidth: 1))
            )
        }
        .padding(.horizontal, 22).padding(.top, 16).padding(.bottom, 8)
    }

    // MARK: ── Moon Scene ──────────────────────────────────────────────────

    private let moonSize: CGFloat = 240

    private var moonScene: some View {
        ZStack {
            StarsView()

            ZStack {
                PixelMoonView(shake: moonShake)
                    .frame(width: moonSize, height: moonSize)
                    .onTapGesture { tapMoon() }

                OnMoonCharacterView(
                    imageName: "pixel_rabbit",
                    fallback: "🐇",
                    spriteSize: 70,
                    moonSize: moonSize,
                    rimInset: 40,
                    angleDegrees: -145,
                    isJumping: rabbitJumping,
                    flipHorizontal: true,
                    badgeSystemImage: nil,
                    hintEmoji: nil,
                    onTap: tapRabbit
                )

                OnMoonCharacterView(
                    imageName: "pixel_grandpa",
                    fallback: "🧓",
                    spriteSize: 95,
                    moonSize: moonSize,
                    rimInset: 40,
                    angleDegrees: -40,
                    isJumping: false,
                    flipHorizontal: false,
                    badgeSystemImage: state?.isTodayCompleted == true ? "checkmark.seal.fill" : nil,
                    hintEmoji: "💬",
                    onTap: tapGrandpa
                )
            }
            .offset(y: -10)

            VStack {
                Spacer()
                Text(MoonPhaseProvider.phase().emoji + "  " + MoonPhaseProvider.phase().name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.bottom, 6)
            }
        }
        .frame(height: 340)
    }

    // MARK: ── Info Cards ──────────────────────────────────────────────────

    private var infoCards: some View {
        HStack(spacing: 12) {
            riceBowlCard
            VStack(spacing: 12) {
                streakCard
                harvestCard
            }
        }
        .padding(.horizontal, 20).padding(.top, 16)
    }

    private var riceBowlCard: some View {
        VStack(spacing: 8) {
            Text("Rice Bowl")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))
                .textCase(.uppercase).kerning(0.8)

            GrowingRiceBowl(riceCount: state?.totalRiceEarned ?? 0, scale: riceScale)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20).fill(Color(r: 20, g: 18, b: 44))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.07), lineWidth: 1))
        )
    }

    private var streakCard: some View {
        HStack(spacing: 10) {
            Text("🔥").font(.system(size: 30))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(state?.softStreak ?? 0)")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(r: 255, g: 160, b: 50))
                Text("day streak").font(.system(size: 11)).foregroundStyle(.white.opacity(0.4))
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 14).frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16).fill(Color(r: 28, g: 20, b: 10))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(r: 255, g: 140, b: 30).opacity(0.2), lineWidth: 1))
        )
    }

    private var harvestCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))
                .textCase(.uppercase).kerning(0.8)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.08)).frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            colors: [Color(r: 120, g: 200, b: 80), Color(r: 80, g: 220, b: 160)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * completionPercent, height: 6)
                        .animation(.spring(response: 0.5), value: completionPercent)
                }
            }
            .frame(height: 6)

            HStack {
                Text("\(todayTasks.filter(\.isCompleted).count)/\(todayTasks.count) tasks")
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.6))
                Spacer()
                Text(String(format: "%.0f%%", completionPercent * 100))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(r: 120, g: 220, b: 140))
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12).frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16).fill(Color(r: 14, g: 26, b: 18))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(r: 80, g: 180, b: 100).opacity(0.2), lineWidth: 1))
        )
    }

    // MARK: ── Complete Day Button ─────────────────────────────────────────

    private var completeDayButton: some View {
        let completed = state?.isTodayCompleted == true
        return Button(action: completeDay) {
            HStack(spacing: 10) {
                Image(systemName: completed ? "checkmark.seal.fill" : "moon.stars.fill")
                    .font(.system(size: 18))
                Text(completed ? "Day Completed ✓" : "Complete Day")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 18)
            .background(
                Group {
                    if completed {
                        Color(r: 50, g: 50, b: 90)
                    } else {
                        LinearGradient(
                            colors: [Color(r: 130, g: 100, b: 255), Color(r: 80, g: 20, b: 180)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    }
                }
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: completed ? .clear : Color(r: 100, g: 60, b: 220).opacity(0.5),
                    radius: 12, y: 4)
            .opacity(completed ? 0.55 : 1.0)
        }
        .disabled(completed)
    }

    // MARK: ── Quote Banner ────────────────────────────────────────────────

    private var quoteBanner: some View {
        VStack {
            HStack(alignment: .top, spacing: 10) {
                Text("🧓").font(.system(size: 28))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Grandpa says")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.4))
                        .textCase(.uppercase).kerning(0.8)
                    Text(grandpaMessage)
                        .font(.system(size: 14, weight: .medium)).foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Button { withAnimation { showMessage = false } } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.3)).font(.system(size: 18))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16).fill(Color(r: 30, g: 28, b: 72))
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(r: 120, g: 100, b: 200).opacity(0.4), lineWidth: 1))
            )
            .padding(.horizontal, 16).padding(.top, 8)
            Spacer()
        }
    }

    // MARK: ── Interactions ────────────────────────────────────────────────

    private func tapMoon() {
        withAnimation(.default) { moonShake = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { moonShake = false }
        for i in 0..<20 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.055) {
                let s = FallingStar()
                withAnimation { fallingStars.append(s) }
                DispatchQueue.main.asyncAfter(deadline: .now() + s.speed + 0.6) {
                    fallingStars.removeAll { $0.id == s.id }
                }
            }
        }
    }

    private func tapRabbit() {
        guard !rabbitJumping else { return }
        withAnimation(.spring(response: 0.22, dampingFraction: 0.38)) { rabbitJumping = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.spring()) { rabbitJumping = false }
        }
    }

    private func tapGrandpa() {
        grandpaMessage = GrandpaQuotes.random()
        withAnimation(.spring()) { showMessage = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            withAnimation { showMessage = false }
        }
    }

    // MARK: ── Complete Day ────────────────────────────────────────────────

    private func completeDay() {
        guard let s = state, !s.isTodayCompleted else { return }

        let rice = RewardCalculator.riceEarned(
            completedTasks: todayTasks.filter(\.isCompleted).count,
            totalTasks: todayTasks.count,
            completedHabits: todayHabits.filter { $0.isCompleted(on: Date()) }.count,
            totalHabits: todayHabits.count
        )

        s.softStreak    = RewardCalculator.updatedStreak(current: s.softStreak, lastCompleted: s.lastCompletedDay)
        s.longestStreak = max(s.longestStreak, s.softStreak)
        s.lastCompletedDay = Date()
        // ── FIXED: save streak + lastCompletedDay immediately so they survive a kill
        try? context.save()

        // Animate rabbit hop
        let newPos = RewardCalculator.advanceRabbit(current: s.rabbitPosition)
        withAnimation(.easeInOut(duration: 0.6)) { rabbitAnimProgress = 1.0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            s.rabbitPosition = newPos
            rabbitAnimProgress = 0
            try? context.save()   // ← save new position
        }

        // Rice grain animation
        for i in 0..<min(rice, 14) {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.07) {
                let g = RiceGrain()
                flyingGrains.append(g)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    flyingGrains.removeAll { $0.id == g.id }
                }
            }
        }

        // ── FIXED: save rice count immediately, not inside a nested asyncAfter
        s.totalRiceEarned += rice
        try? context.save()

        withAnimation(.spring(response: 0.25, dampingFraction: 0.38)) { riceScale = 1.4 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation { riceScale = 1.0 }
        }

        withAnimation(.spring()) { showCelebration = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation { showCelebration = false }
        }
    }
}

// MARK: - PixelMoonView

struct PixelMoonView: View {
    let shake: Bool
    @State private var glow = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(r: 160, g: 180, b: 255).opacity(glow ? 0.22 : 0.08))
                .scaleEffect(glow ? 1.18 : 1.0)
                .animation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true), value: glow)
                .scaleEffect(1.35)

            Image("pixel_moon")
                .resizable().interpolation(.none).scaledToFit().clipShape(Circle())
        }
        .rotationEffect(.degrees(shake ? 4 : 0))
        .animation(
            shake ? .easeInOut(duration: 0.07).repeatCount(5, autoreverses: true) : .default,
            value: shake
        )
        .onAppear { glow = true }
    }
}

// MARK: - MoonDiscView

struct MoonDiscView: View {
    let illumination: Double
    var body: some View {
        ZStack {
            Circle().fill(Color(r: 255, g: 253, b: 231).opacity(0.12))
            Circle().fill(Color(r: 255, g: 253, b: 231))
                .mask(GeometryReader { geo in
                    Rectangle()
                        .frame(width: max(0, geo.size.width * illumination))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                })
        }
        .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 1))
    }
}

// MARK: - OnMoonCharacterView

struct OnMoonCharacterView: View {
    let imageName: String
    let fallback: String
    let spriteSize: CGFloat
    let moonSize: CGFloat
    let rimInset: CGFloat
    let angleDegrees: Double
    let isJumping: Bool
    let flipHorizontal: Bool
    let badgeSystemImage: String?
    let hintEmoji: String?
    let onTap: () -> Void

    private var radians: Double { angleDegrees * .pi / 180 }
    private var center: CGPoint { .init(x: moonSize / 2, y: moonSize / 2) }
    private var rimRadius: CGFloat { moonSize / 2 - rimInset }
    private var rimPoint: CGPoint {
        CGPoint(x: center.x + CGFloat(cos(radians)) * rimRadius,
                y: center.y + CGFloat(sin(radians)) * rimRadius)
    }
    private var spriteCenter: CGPoint {
        CGPoint(x: rimPoint.x, y: rimPoint.y - spriteSize / 2)
    }
    private var headPoint: CGPoint {
        CGPoint(x: spriteCenter.x, y: spriteCenter.y - spriteSize * 0.55)
    }

    var body: some View {
        // where the sprite’s CENTER should be (so its bottom touches the rim)
        let spriteCenter = CGPoint(x: rimPoint.x, y: rimPoint.y - spriteSize / 2)

        ZStack {
            // contact shadow at the rim
            Capsule()
                .fill(Color.black.opacity(0.25))
                .frame(width: spriteSize * 0.35, height: 6)
                .position(x: rimPoint.x, y: rimPoint.y + 2)
                .blur(radius: 1.2)

            // sprite + emoji bubble grouped together so they move together
            ZStack {
                Group {
                    if UIImage(named: imageName) != nil {
                        Image(imageName)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                    } else {
                        Text(fallback)
                    }
                }
                .frame(width: spriteSize, height: spriteSize, alignment: .bottom)
                .scaleEffect(x: flipHorizontal ? -1 : 1, y: 1)
                .overlay(alignment: .top) {
                    if let emoji = hintEmoji {
                        Text(emoji)
                            .font(.system(size: 12))
                            .opacity(0.85)
                            .offset(y: -10)   // ✅ close to head
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if let badge = badgeSystemImage {
                        Image(systemName: badge)
                            .foregroundStyle(.green)
                            .font(.system(size: 10))
                            .offset(x: 6, y: -6)
                    }
                }
            }
            .position(spriteCenter)
            .offset(y: isJumping ? -18 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.38), value: isJumping)
            .onTapGesture { onTap() }
        }
        .frame(width: moonSize, height: moonSize)
    }
}

// MARK: - GrowingRiceBowl

struct RiceTier {
    let emoji: String; let label: String; let color: Color
    static func from(riceCount: Int) -> RiceTier {
        switch riceCount {
        case 0:        return .init(emoji: "🪣", label: "Empty",   color: .gray)
        case 1..<20:   return .init(emoji: "🍚", label: "Sprout",  color: Color(r: 200, g: 169, b: 110))
        case 20..<60:  return .init(emoji: "🍚", label: "Harvest", color: Color(r: 212, g: 160, b: 23))
        case 60..<150: return .init(emoji: "🍛", label: "Feast",   color: Color(r: 232, g: 184, b: 0))
        default:       return .init(emoji: "🏆", label: "Legend",  color: Color(r: 255, g: 215, b: 0))
        }
    }
}

struct GrowingRiceBowl: View {
    let riceCount: Int
    let scale: CGFloat
    private var tier: RiceTier { RiceTier.from(riceCount: riceCount) }
    private var fillLevel: Int {
        switch riceCount {
        case 0: return 0; case 1..<10: return 1; case 10..<30: return 2
        case 30..<70: return 3; case 70..<150: return 4; default: return 5
        }
    }

    var body: some View {
        VStack(spacing: 6) { riceStackView; bowlView; tierLabel }.scaleEffect(scale)
    }

    private var riceStackView: some View {
        VStack(spacing: 2) {
            ForEach(0..<fillLevel, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<(3 + row), id: \.self) { _ in
                        Text("🌾").font(.system(size: CGFloat(9 + row * 2)))
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5), value: fillLevel)
    }

    private var bowlView: some View {
        ZStack {
            Ellipse().fill(Color(r: 80, g: 50, b: 15)).frame(width: 76, height: 26).offset(y: 8)
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(
                    colors: [Color(r: 150, g: 100, b: 55), Color(r: 90, g: 55, b: 15)],
                    startPoint: .top, endPoint: .bottom))
                .frame(width: 70, height: 38)
            if riceCount > 0 {
                Ellipse().fill(Color(r: 248, g: 242, b: 222)).frame(width: 58, height: 13).offset(y: -8)
            }
            Ellipse().stroke(Color(r: 170, g: 130, b: 75), lineWidth: 2)
                .frame(width: 70, height: 16).offset(y: -10)
        }
        .frame(height: 50)
    }

    private var tierLabel: some View {
        VStack(spacing: 2) {
            HStack(spacing: 5) {
                Text(tier.emoji).font(.system(size: 13))
                Text("\(riceCount)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(tier.color)
                    .contentTransition(.numericText())
                    .animation(.spring(), value: riceCount)
            }
            Text(tier.label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.35))
                .textCase(.uppercase).kerning(1.2)
        }
    }
}

// MARK: - Particle Views

struct FallingStarView: View {
    let star: FallingStar
    let containerHeight: CGFloat
    @State private var fallen  = false
    @State private var opacity = 0.0

    var body: some View {
        Circle().fill(Color.white).frame(width: star.size, height: star.size)
            .position(x: star.startX + (fallen ? star.drift : 0),
                      y: fallen ? containerHeight * 0.72 : star.startY)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: star.speed)) { fallen = true }
                withAnimation(.easeIn(duration: 0.12)) { opacity = 1.0 }
                withAnimation(.easeOut(duration: 0.35).delay(star.speed * 0.65)) { opacity = 0 }
            }
    }
}

struct FlyingRiceGrainView: View {
    let grain: RiceGrain
    let containerWidth: CGFloat
    @State private var progress: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        let x = grain.startX + (grain.endX - grain.startX) * progress
        let y = grain.startY + (grain.endY - grain.startY) * progress - 90 * sin(.pi * progress)
        Text("🌾").font(.system(size: 13))
            .rotationEffect(.degrees(grain.rotation + Double(progress) * 200))
            .position(x: containerWidth / 2 + x, y: y + 300)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.9)) { progress = 1 }
                withAnimation(.easeIn(duration: 0.4).delay(0.55)) { opacity = 0 }
            }
    }
}

// MARK: - Stars

struct StarsView: View {
    private static let data: [(CGFloat, CGFloat, CGFloat, Double)] = {
        var rng = SeededRandom(seed: 42)
        return (0..<60).map { _ in
            (rng.next(in: 0...400), rng.next(in: 0...340),
             rng.next(in: 0.8...2.8), Double(rng.next(in: 0.15...0.9)))
        }
    }()
    var body: some View {
        Canvas { ctx, _ in
            for (x, y, r, op) in Self.data {
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                         with: .color(.white.opacity(op)))
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - SummaryTile

struct SummaryTile: View {
    let value: String; let label: String; let icon: String
    var body: some View {
        VStack(spacing: 4) {
            Label(value, systemImage: icon).font(.subheadline.bold()).foregroundStyle(.white)
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - CelebrationOverlay

struct CelebrationOverlay: View {
    let riceEarned: Int
    @State private var opacity: Double = 0
    @State private var scale: CGFloat  = 0.8
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 18) {
                Text("🎉").font(.system(size: 72))
                Text("Day Complete!")
                    .font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(.white)
                Text("+\(riceEarned) 🌾 rice earned")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(r: 255, g: 220, b: 80))
                Text("Tap to continue").font(.system(size: 13)).foregroundStyle(.white.opacity(0.4))
            }
            .padding(36)
            .background(
                RoundedRectangle(cornerRadius: 28).fill(Color(r: 22, g: 20, b: 60))
                    .overlay(RoundedRectangle(cornerRadius: 28)
                        .stroke(Color(r: 120, g: 90, b: 240).opacity(0.4), lineWidth: 1))
            )
            .scaleEffect(scale).opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) { opacity = 1; scale = 1 }
        }
    }
}

// MARK: - Color convenience

extension Color {
    init(r: Double, g: Double, b: Double, a: Double = 1) {
        self.init(.sRGB, red: r/255, green: g/255, blue: b/255, opacity: a)
    }
}

// MARK: - SeededRandom

private struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func nextUInt64() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    mutating func next(in range: ClosedRange<CGFloat>) -> CGFloat {
        let t = CGFloat(nextUInt64()) / CGFloat(UInt64.max)
        return range.lowerBound + t * (range.upperBound - range.lowerBound)
    }
}
