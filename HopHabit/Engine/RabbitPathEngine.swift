//
//  RabbitPathEngine.swift
//  HopHabit
//
//  Created by Giyu Tomioka on 2/28/26.
//

import SwiftUI

/// Converts a rabbit step (0–27) into an (x, y) point along a circular moon path.
struct RabbitPathEngine {

    /// Radius of the orbit circle in points
    let orbitRadius: CGFloat
    /// Center of the moon
    let center: CGPoint
    /// Total positions
    let totalSteps: Int

    init(orbitRadius: CGFloat = 130, center: CGPoint = CGPoint(x: 160, y: 160), totalSteps: Int = 28) {
        self.orbitRadius = orbitRadius
        self.center = center
        self.totalSteps = totalSteps
    }

    /// Position for a given step (0-indexed). Step 0 is top-center.
    func position(for step: Int) -> CGPoint {
        let angle = (2 * CGFloat.pi / CGFloat(totalSteps)) * CGFloat(step) - (.pi / 2)
        let x = center.x + orbitRadius * cos(angle)
        let y = center.y + orbitRadius * sin(angle)
        return CGPoint(x: x, y: y)
    }

    /// Animated position using fractional progress between steps
    func animatedPosition(step: Int, progress: CGFloat) -> CGPoint {
        let from = position(for: step)
        let to = position(for: (step + 1) % totalSteps)
        return CGPoint(
            x: from.x + (to.x - from.x) * progress,
            y: from.y + (to.y - from.y) * progress
        )
    }
}
