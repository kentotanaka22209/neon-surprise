import SwiftUI
import Foundation

// MARK: - Core Simulation Entities

struct StarDrop: Identifiable, Sendable {
    let id: UUID
    var position: CGPoint
    var velocity: CGPoint
    var radius: CGFloat
    var color: RGBAColor
    var combo: Int
    var isRainbow: Bool
    var rainbowPhase: Double
    var age: Double
    var maxAge: Double
    var trail: [CGPoint]
    var lastHitStringID: UUID?
    var stringCooldown: Double
    var lastHitPrismID: UUID?
    var prismCooldown: Double
    var rotation: Double

    init(
        id: UUID = UUID(),
        position: CGPoint,
        velocity: CGPoint,
        radius: CGFloat = 8.5,
        color: RGBAColor,
        combo: Int = 0,
        isRainbow: Bool = false,
        maxAge: Double = 14.0
    ) {
        self.id = id
        self.position = position
        self.velocity = velocity
        self.radius = radius
        self.color = color
        self.combo = combo
        self.isRainbow = isRainbow
        self.rainbowPhase = Double.random(in: 0...1)
        self.age = 0
        self.maxAge = maxAge
        self.trail = [position]
        self.lastHitStringID = nil
        self.stringCooldown = 0
        self.lastHitPrismID = nil
        self.prismCooldown = 0
        self.rotation = Double.random(in: 0...(Double.pi * 2))
    }
}

struct NeonString: Identifiable, Sendable {
    let id: UUID
    var start: CGPoint
    var end: CGPoint
    var kind: StringKind
    var vibrationAmplitude: CGFloat
    var vibrationPhase: Double
    var pluckedT: CGFloat
    var vibrationNormal: CGPoint
    var glowIntensity: Double
    var appearProgress: Double
    var pluckCount: Int

    init(
        id: UUID = UUID(),
        start: CGPoint,
        end: CGPoint,
        kind: StringKind = .standard
    ) {
        self.id = id
        self.start = start
        self.end = end
        self.kind = kind
        self.vibrationAmplitude = 10.0
        self.vibrationPhase = 0.0
        self.pluckedT = 0.5
        let dir = end.subtracting(start).normalized()
        self.vibrationNormal = CGPoint(x: -dir.y, y: dir.x)
        self.glowIntensity = 0.9
        self.appearProgress = 0.0
        self.pluckCount = 0
    }

    var length: CGFloat {
        start.distance(to: end)
    }

    var midpoint: CGPoint {
        CGPoint.lerp(start, end, t: 0.5)
    }
}

struct ResonanceBloom: Identifiable, Sendable {
    let id: UUID
    var position: CGPoint
    var radius: CGFloat
    var petalCount: Int
    var color: RGBAColor
    var isLit: Bool
    var bloomProgress: Double
    var pulsePhase: Double
    var rearmTimer: Double

    init(
        id: UUID = UUID(),
        position: CGPoint,
        radius: CGFloat = 24.0,
        petalCount: Int = 6,
        color: RGBAColor
    ) {
        self.id = id
        self.position = position
        self.radius = radius
        self.petalCount = petalCount
        self.color = color
        self.isLit = false
        self.bloomProgress = 0.0
        self.pulsePhase = Double.random(in: 0...(Double.pi * 2))
        self.rearmTimer = 0.0
    }
}

struct LightPrism: Identifiable, Sendable {
    let id: UUID
    var position: CGPoint
    var radius: CGFloat
    var rotation: Double
    var pulse: Double

    init(
        id: UUID = UUID(),
        position: CGPoint,
        radius: CGFloat = 22.0
    ) {
        self.id = id
        self.position = position
        self.radius = radius
        self.rotation = Double.random(in: 0...(Double.pi * 2))
        self.pulse = 0.0
    }
}

struct GravityOrb: Identifiable, Sendable {
    let id: UUID
    var position: CGPoint
    var radius: CGFloat
    var influenceRadius: CGFloat
    var strength: CGFloat
    var swirlDirection: CGFloat
    var phase: Double

    init(
        id: UUID = UUID(),
        position: CGPoint,
        radius: CGFloat = 18.0,
        influenceRadius: CGFloat = 155.0,
        strength: CGFloat = 21000.0,
        swirlDirection: CGFloat = 1.0
    ) {
        self.id = id
        self.position = position
        self.radius = radius
        self.influenceRadius = influenceRadius
        self.strength = strength
        self.swirlDirection = swirlDirection
        self.phase = Double.random(in: 0...(Double.pi * 2))
    }
}

struct EmitterNode: Identifiable, Sendable {
    let id: UUID
    var position: CGPoint
    var launchVelocity: CGPoint
    var pulse: Double
    var phase: Double

    init(
        id: UUID = UUID(),
        position: CGPoint,
        launchVelocity: CGPoint = CGPoint(x: 0, y: 65)
    ) {
        self.id = id
        self.position = position
        self.launchVelocity = launchVelocity
        self.pulse = 0.0
        self.phase = Double.random(in: 0...(Double.pi * 2))
    }
}

// MARK: - Visual Feedback Entities

struct SparkParticle: Identifiable, Sendable {
    let id: UUID
    var position: CGPoint
    var velocity: CGPoint
    var size: CGFloat
    var color: RGBAColor
    var life: Double
    var maxLife: Double

    init(
        position: CGPoint,
        velocity: CGPoint,
        size: CGFloat,
        color: RGBAColor,
        maxLife: Double
    ) {
        self.id = UUID()
        self.position = position
        self.velocity = velocity
        self.size = size
        self.color = color
        self.life = 0.0
        self.maxLife = maxLife
    }

    var progress: Double {
        min(1.0, life / max(0.001, maxLife))
    }
}

struct RippleWave: Identifiable, Sendable {
    let id: UUID
    var center: CGPoint
    var maxRadius: CGFloat
    var color: RGBAColor
    var lineWidth: CGFloat
    var life: Double
    var maxLife: Double

    init(
        center: CGPoint,
        maxRadius: CGFloat,
        color: RGBAColor,
        lineWidth: CGFloat = 3.0,
        maxLife: Double = 0.55
    ) {
        self.id = UUID()
        self.center = center
        self.maxRadius = maxRadius
        self.color = color
        self.lineWidth = lineWidth
        self.life = 0.0
        self.maxLife = maxLife
    }

    var progress: Double {
        min(1.0, life / max(0.001, maxLife))
    }
}

struct FloatingScore: Identifiable, Sendable {
    let id: UUID
    var text: String
    var position: CGPoint
    var color: RGBAColor
    var fontSize: CGFloat
    var life: Double
    var maxLife: Double

    init(
        text: String,
        position: CGPoint,
        color: RGBAColor,
        fontSize: CGFloat = 18.0,
        maxLife: Double = 1.05
    ) {
        self.id = UUID()
        self.text = text
        self.position = position
        self.color = color
        self.fontSize = fontSize
        self.life = 0.0
        self.maxLife = maxLife
    }

    var progress: Double {
        min(1.0, life / max(0.001, maxLife))
    }
}

struct BackgroundStar: Identifiable, Sendable {
    let id: Int
    let normX: CGFloat
    let normY: CGFloat
    let size: CGFloat
    let phase: Double
    let speed: Double
}

struct DragPreviewLine: Equatable, Sendable {
    var start: CGPoint
    var end: CGPoint
    var kind: StringKind

    var length: CGFloat {
        start.distance(to: end)
    }
}
