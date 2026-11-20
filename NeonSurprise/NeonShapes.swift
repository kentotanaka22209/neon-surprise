import SwiftUI
import Foundation

// MARK: - Reusable Custom Neon Vector Shapes

struct StarPolygonShape: Shape {
    let points: Int
    let innerRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        let count = max(3, points)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerR = min(rect.width, rect.height) * 0.5
        let innerR = outerR * innerRatio
        var path = Path()
        let totalVertices = count * 2
        for i in 0..<totalVertices {
            let angle = (CGFloat(i) / CGFloat(totalVertices)) * CGFloat.pi * 2.0 - CGFloat.pi / 2.0
            let r = (i % 2 == 0) ? outerR : innerR
            let pt = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
            if i == 0 {
                path.move(to: pt)
            } else {
                path.addLine(to: pt)
            }
        }
        path.closeSubpath()
        return path
    }
}

struct DiamondCrystalShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        let midY = rect.midY
        path.move(to: CGPoint(x: midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: midY))
        path.addLine(to: CGPoint(x: midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: midY))
        path.closeSubpath()
        return path
    }
}

struct LotusBloomShape: Shape {
    let petals: Int

    func path(in rect: CGRect) -> Path {
        let count = max(4, petals)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.48
        var path = Path()

        for i in 0..<count {
            let angle = (CGFloat(i) / CGFloat(count)) * CGFloat.pi * 2.0 - CGFloat.pi / 2.0
            let tip = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            let sideAngle1 = angle - CGFloat.pi / CGFloat(count) * 0.72
            let sideAngle2 = angle + CGFloat.pi / CGFloat(count) * 0.72
            let ctrlR = radius * 0.62
            let c1 = CGPoint(x: center.x + cos(sideAngle1) * ctrlR, y: center.y + sin(sideAngle1) * ctrlR)
            let c2 = CGPoint(x: center.x + cos(sideAngle2) * ctrlR, y: center.y + sin(sideAngle2) * ctrlR)

            path.move(to: center)
            path.addQuadCurve(to: tip, control: c1)
            path.addQuadCurve(to: center, control: c2)
        }
        return path
    }
}

struct InfinityRibbonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let rx = rect.width * 0.42
        let ry = rect.height * 0.34
        var path = Path()
        let steps = 72
        for i in 0...steps {
            let t = (CGFloat(i) / CGFloat(steps)) * CGFloat.pi * 2.0
            let denom = 1.0 + sin(t) * sin(t)
            let x = center.x + rx * cos(t) / denom
            let y = center.y + ry * sin(t) * cos(t) / denom * 1.45
            let pt = CGPoint(x: x, y: y)
            if i == 0 {
                path.move(to: pt)
            } else {
                path.addLine(to: pt)
            }
        }
        path.closeSubpath()
        return path
    }
}

struct HarpWaveShape: Shape {
    var phase: CGFloat = 0.0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let lines = 3
        for idx in 0..<lines {
            let yRatio = 0.26 + CGFloat(idx) * 0.24
            let baseY = rect.minY + rect.height * yRatio
            let amp = rect.height * (0.11 + CGFloat(idx % 2) * 0.04)
            let steps = 32
            for step in 0...steps {
                let u = CGFloat(step) / CGFloat(steps)
                let x = rect.minX + rect.width * (0.08 + 0.84 * u)
                let envelope = sin(u * CGFloat.pi)
                let y = baseY + sin(u * CGFloat.pi * 2.0 + phase + CGFloat(idx) * 1.2) * amp * envelope
                let pt = CGPoint(x: x, y: y)
                if step == 0 {
                    path.move(to: pt)
                } else {
                    path.addLine(to: pt)
                }
            }
        }
        return path
    }
}

struct VortexSpiralShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxR = min(rect.width, rect.height) * 0.46
        var path = Path()
        for arm in 0..<3 {
            let armOffset = CGFloat(arm) * (CGFloat.pi * 2.0 / 3.0)
            let steps = 36
            for s in 0...steps {
                let u = CGFloat(s) / CGFloat(steps)
                let angle = armOffset + u * CGFloat.pi * 2.4
                let r = maxR * u
                let pt = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
                if s == 0 {
                    path.move(to: pt)
                } else {
                    path.addLine(to: pt)
                }
            }
        }
        return path
    }
}

struct HeartNovaShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let x = rect.minX
        let y = rect.minY

        path.move(to: CGPoint(x: x + w * 0.5, y: y + h * 0.88))
        path.addCurve(
            to: CGPoint(x: x + w * 0.1, y: y + h * 0.34),
            control1: CGPoint(x: x + w * 0.14, y: y + h * 0.66),
            control2: CGPoint(x: x + w * 0.08, y: y + h * 0.48)
        )
        path.addCurve(
            to: CGPoint(x: x + w * 0.5, y: y + h * 0.28),
            control1: CGPoint(x: x + w * 0.12, y: y + h * 0.10),
            control2: CGPoint(x: x + w * 0.44, y: y + h * 0.10)
        )
        path.addCurve(
            to: CGPoint(x: x + w * 0.9, y: y + h * 0.34),
            control1: CGPoint(x: x + w * 0.56, y: y + h * 0.10),
            control2: CGPoint(x: x + w * 0.88, y: y + h * 0.10)
        )
        path.addCurve(
            to: CGPoint(x: x + w * 0.5, y: y + h * 0.88),
            control1: CGPoint(x: x + w * 0.92, y: y + h * 0.48),
            control2: CGPoint(x: x + w * 0.86, y: y + h * 0.66)
        )
        path.closeSubpath()
        return path
    }
}

struct CrownEmblemShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let x = rect.minX
        let y = rect.minY

        path.move(to: CGPoint(x: x + w * 0.14, y: y + h * 0.76))
        path.addLine(to: CGPoint(x: x + w * 0.10, y: y + h * 0.30))
        path.addLine(to: CGPoint(x: x + w * 0.32, y: y + h * 0.50))
        path.addLine(to: CGPoint(x: x + w * 0.50, y: y + h * 0.16))
        path.addLine(to: CGPoint(x: x + w * 0.68, y: y + h * 0.50))
        path.addLine(to: CGPoint(x: x + w * 0.90, y: y + h * 0.30))
        path.addLine(to: CGPoint(x: x + w * 0.86, y: y + h * 0.76))
        path.closeSubpath()
        return path
    }
}

// MARK: - Specimen Artwork Renderer View

struct SpecimenArtworkView: View {
    let specimen: NeonSpecimen
    let unlocked: Bool
    var size: CGFloat = 68
    var pulsePhase: Double = 0.0

    var body: some View {
        let primary = unlocked ? specimen.primaryColor.color : Color.white.opacity(0.22)
        let secondary = unlocked ? specimen.secondaryColor.color : Color.white.opacity(0.10)
        let gradient = LinearGradient(colors: [primary, secondary], startPoint: .topLeading, endPoint: .bottomTrailing)

        ZStack {
            if unlocked {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [primary.opacity(0.32), secondary.opacity(0.08), .clear],
                            center: .center,
                            startRadius: 2,
                            endRadius: size * 0.68
                        )
                    )
                    .frame(width: size * 1.22, height: size * 1.22)
            }

            glyphContent(gradient: gradient, primary: primary, secondary: secondary)
                .frame(width: size * 0.76, height: size * 0.76)
                .shadow(color: unlocked ? primary.opacity(0.75) : .clear, radius: size * 0.14)
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private func glyphContent(gradient: LinearGradient, primary: Color, secondary: Color) -> some View {
        let softGradient = LinearGradient(
            colors: [primary.opacity(0.32), secondary.opacity(0.32)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        switch specimen.glyph {
        case .lotus:
            LotusBloomShape(petals: 6)
                .stroke(gradient, style: StrokeStyle(lineWidth: size * 0.045, lineCap: .round, lineJoin: .round))
        case .harpWave:
            HarpWaveShape(phase: CGFloat(pulsePhase))
                .stroke(gradient, style: StrokeStyle(lineWidth: size * 0.055, lineCap: .round))
        case .diamondPrism:
            ZStack {
                DiamondCrystalShape()
                    .stroke(gradient, lineWidth: size * 0.05)
                DiamondCrystalShape()
                    .scale(0.55)
                    .fill(softGradient)
            }
        case .vortexStar:
            VortexSpiralShape()
                .stroke(gradient, style: StrokeStyle(lineWidth: size * 0.048, lineCap: .round))
        case .starburst:
            StarPolygonShape(points: 5, innerRatio: 0.42)
                .stroke(gradient, style: StrokeStyle(lineWidth: size * 0.048, lineJoin: .round))
        case .infinityLoop:
            InfinityRibbonShape()
                .stroke(gradient, style: StrokeStyle(lineWidth: size * 0.055, lineCap: .round))
        case .sakuraCrown:
            ZStack {
                LotusBloomShape(petals: 5)
                    .fill(softGradient)
                LotusBloomShape(petals: 5)
                    .stroke(gradient, lineWidth: size * 0.045)
            }
        case .cometOrb:
            ZStack {
                Circle()
                    .stroke(gradient, style: StrokeStyle(lineWidth: size * 0.04, dash: [size * 0.08, size * 0.05]))
                StarPolygonShape(points: 4, innerRatio: 0.35)
                    .scale(0.62)
                    .fill(gradient)
            }
        case .twinRings:
            ZStack {
                Circle()
                    .stroke(primary, lineWidth: size * 0.045)
                    .offset(x: -size * 0.12)
                Circle()
                    .stroke(secondary, lineWidth: size * 0.045)
                    .offset(x: size * 0.12)
            }
            .scaleEffect(0.75)
        case .zeroGravityAtom:
            ZStack {
                Ellipse()
                    .stroke(primary, lineWidth: size * 0.04)
                    .rotationEffect(.degrees(30))
                Ellipse()
                    .stroke(secondary, lineWidth: size * 0.04)
                    .rotationEffect(.degrees(-30))
                Circle()
                    .fill(gradient)
                    .frame(width: size * 0.18, height: size * 0.18)
            }
        case .feverSupernova:
            ZStack {
                StarPolygonShape(points: 8, innerRatio: 0.38)
                    .fill(softGradient)
                StarPolygonShape(points: 8, innerRatio: 0.38)
                    .stroke(gradient, lineWidth: size * 0.045)
            }
        case .constellationCrown:
            ZStack {
                CrownEmblemShape()
                    .fill(softGradient)
                CrownEmblemShape()
                    .stroke(gradient, style: StrokeStyle(lineWidth: size * 0.05, lineJoin: .round))
            }
        }
    }
}
