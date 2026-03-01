//
//  RabbitPathEngine.swift
//  HopHabit


import SwiftUI


struct RabbitPathEngine {


    let orbitRadius: CGFloat

    let center: CGPoint

    let totalSteps: Int

    init(orbitRadius: CGFloat = 130, center: CGPoint = CGPoint(x: 160, y: 160), totalSteps: Int = 28) {
        self.orbitRadius = orbitRadius
        self.center = center
        self.totalSteps = totalSteps
    }

    func position(for step: Int) -> CGPoint {
        let angle = (2 * CGFloat.pi / CGFloat(totalSteps)) * CGFloat(step) - (.pi / 2)
        let x = center.x + orbitRadius * cos(angle)
        let y = center.y + orbitRadius * sin(angle)
        return CGPoint(x: x, y: y)
    }

    func animatedPosition(step: Int, progress: CGFloat) -> CGPoint {
        let from = position(for: step)
        let to = position(for: (step + 1) % totalSteps)
        return CGPoint(
            x: from.x + (to.x - from.x) * progress,
            y: from.y + (to.y - from.y) * progress
        )
    }
}
