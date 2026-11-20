import SwiftUI
import Foundation

struct NeonCanvasView: View {
    @ObservedObject var engine: NeonSimulationEngine

    var body: some View {
        let _ = engine.frameTick
        Canvas { context, size in
            drawBackground(in: &context, size: size)
            drawSubtleGrid(in: &context, size: size)
            drawStars(in: &context, size: size)

            context.drawLayer { layer in
                layer.blendMode = .plusLighter
                drawGravityOrbs(in: &layer)
                drawEmitters(in: &layer)
                drawRipples(in: &layer)
                drawBlooms(in: &layer)
                drawPrisms(in: &layer)
                drawStrings(in: &layer)
                drawDragPreview(in: &layer)
                drawDrops(in: &layer)
                drawSparks(in: &layer)
            }

            drawFloatingScores(in: &context)

            if engine.isFeverActive {
                drawFeverBorder(in: &context, size: size)
            }

            if engine.screenFlashOpacity > 0.005 {
                let flashRect = CGRect(origin: .zero, size: size)
                context.fill(
                    Path(flashRect),
                    with: .color(engine.theme.primary.withAlpha(engine.screenFlashOpacity).color)
                )
            }
        }
        .offset(engine.shakeOffset)
    }

    // MARK: - Background & Starfield

    private func drawBackground(in context: inout GraphicsContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        let grad = Gradient(colors: [engine.theme.backgroundTop.color, engine.theme.backgroundBottom.color])
        context.fill(
            Path(rect),
            with: .linearGradient(grad, startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height))
        )

        // Soft ambient nebula pools
        let t = engine.elapsedTime
        let pool1 = CGPoint(x: size.width * CGFloat(0.25 + 0.08 * sin(t * 0.3)), y: size.height * 0.28)
        let pool2 = CGPoint(x: size.width * CGFloat(0.76 + 0.07 * cos(t * 0.25)), y: size.height * 0.72)
        let r = max(size.width, size.height) * 0.45

        context.fill(
            Path(ellipseIn: CGRect(x: pool1.x - r, y: pool1.y - r, width: r * 2, height: r * 2)),
            with: .radialGradient(
                Gradient(colors: [engine.theme.primary.withAlpha(0.11).color, .clear]),
                center: pool1,
                startRadius: 0,
                endRadius: r
            )
        )
        context.fill(
            Path(ellipseIn: CGRect(x: pool2.x - r, y: pool2.y - r, width: r * 2, height: r * 2)),
            with: .radialGradient(
                Gradient(colors: [engine.theme.secondary.withAlpha(0.10).color, .clear]),
                center: pool2,
                startRadius: 0,
                endRadius: r
            )
        )
    }

    private func drawSubtleGrid(in context: inout GraphicsContext, size: CGSize) {
        let spacing: CGFloat = 44.0
        var path = Path()
        var x: CGFloat = spacing
        while x < size.width {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            x += spacing
        }
        var y: CGFloat = spacing
        while y < size.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            y += spacing
        }
        context.stroke(path, with: .color(Color.white.opacity(0.032)), lineWidth: 0.7)
    }

    private func drawStars(in context: inout GraphicsContext, size: CGSize) {
        let t = engine.elapsedTime
        for star in engine.backgroundStars {
            let x = star.normX * size.width
            let y = star.normY * size.height
            let twinkle = 0.22 + 0.55 * (0.5 + 0.5 * sin(t * star.speed + star.phase))
            let rect = CGRect(x: x - star.size * 0.5, y: y - star.size * 0.5, width: star.size, height: star.size)
            context.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(twinkle)))
        }
    }

    // MARK: - Gravity Orbs

    private func drawGravityOrbs(in context: inout GraphicsContext) {
        for orb in engine.gravityOrbs {
            let c = orb.position
            let auraR = orb.influenceRadius * 0.78
            context.fill(
                Path(ellipseIn: CGRect(x: c.x - auraR, y: c.y - auraR, width: auraR * 2, height: auraR * 2)),
                with: .radialGradient(
                    Gradient(colors: [RGBAColor.neonViolet.withAlpha(0.28).color, RGBAColor.neonViolet.withAlpha(0.05).color, .clear]),
                    center: c,
                    startRadius: 4,
                    endRadius: auraR
                )
            )

            // Rotating dashed gravitational rings
            for ring in 0..<2 {
                let r = orb.radius * (1.7 + CGFloat(ring) * 1.15)
                var ringPath = Path()
                let segments = 24
                for s in 0..<segments {
                    if s % 2 == 1 { continue }
                    let a1 = orb.phase * (ring == 0 ? 1.2 : -0.75) + Double(s) / Double(segments) * Double.pi * 2.0
                    let a2 = a1 + (Double.pi * 2.0 / Double(segments)) * 0.65
                    let startPt = CGPoint(x: c.x + CGFloat(cos(a1)) * r, y: c.y + CGFloat(sin(a1)) * r)
                    ringPath.move(to: startPt)
                    ringPath.addArc(center: c, radius: r, startAngle: .radians(a1), endAngle: .radians(a2), clockwise: false)
                }
                context.stroke(
                    ringPath,
                    with: .color(RGBAColor.neonViolet.withAlpha(ring == 0 ? 0.62 : 0.30).color),
                    style: StrokeStyle(lineWidth: ring == 0 ? 2.0 : 1.4, lineCap: .round)
                )
            }

            // Swirling core
            let coreRect = CGRect(x: c.x - orb.radius * 0.7, y: c.y - orb.radius * 0.7, width: orb.radius * 1.4, height: orb.radius * 1.4)
            context.fill(Path(ellipseIn: coreRect), with: .color(RGBAColor.neonViolet.withAlpha(0.65).color))
            let innerRect = CGRect(x: c.x - orb.radius * 0.32, y: c.y - orb.radius * 0.32, width: orb.radius * 0.64, height: orb.radius * 0.64)
            context.fill(Path(ellipseIn: innerRect), with: .color(Color.white.opacity(0.9)))
        }
    }

    // MARK: - Emitters

    private func drawEmitters(in context: inout GraphicsContext) {
        for emitter in engine.emitters {
            let c = emitter.position
            let pulseScale = 1.0 + CGFloat(emitter.pulse) * 0.38
            let r = 14.0 * pulseScale

            context.fill(
                Path(ellipseIn: CGRect(x: c.x - r * 2.2, y: c.y - r * 2.2, width: r * 4.4, height: r * 4.4)),
                with: .radialGradient(
                    Gradient(colors: [engine.theme.primary.withAlpha(0.45).color, .clear]),
                    center: c,
                    startRadius: 2,
                    endRadius: r * 2.2
                )
            )

            // Outer gate ring
            context.stroke(
                Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                with: .color(engine.theme.primary.withAlpha(0.9).color),
                style: StrokeStyle(lineWidth: 2.2)
            )

            // Direction indicator chevron
            let dir = emitter.launchVelocity.normalized()
            let tip = c.adding(dir.scaled(by: r + 7))
            let perp = CGPoint(x: -dir.y, y: dir.x)
            let p1 = c.adding(dir.scaled(by: r + 1)).adding(perp.scaled(by: 5))
            let p2 = c.adding(dir.scaled(by: r + 1)).adding(perp.scaled(by: -5))
            var arrow = Path()
            arrow.move(to: p1)
            arrow.addLine(to: tip)
            arrow.addLine(to: p2)
            context.stroke(arrow, with: .color(Color.white.opacity(0.85)), style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))

            // Core dot
            let dotR: CGFloat = 4.5
            context.fill(Path(ellipseIn: CGRect(x: c.x - dotR, y: c.y - dotR, width: dotR * 2, height: dotR * 2)), with: .color(.white))
        }
    }

    // MARK: - Resonance Blooms

    private func drawBlooms(in context: inout GraphicsContext) {
        for bloom in engine.blooms {
            let c = bloom.position
            let breath = 1.0 + 0.08 * sin(bloom.pulsePhase)
            let glowR = bloom.radius * (bloom.isLit ? 2.6 : 1.7) * CGFloat(breath)

            // Halo
            context.fill(
                Path(ellipseIn: CGRect(x: c.x - glowR, y: c.y - glowR, width: glowR * 2, height: glowR * 2)),
                with: .radialGradient(
                    Gradient(colors: [
                        bloom.color.withAlpha(bloom.isLit ? 0.55 : 0.24).color,
                        bloom.color.withAlpha(0.05).color,
                        .clear
                    ]),
                    center: c,
                    startRadius: 2,
                    endRadius: glowR
                )
            )

            // Unlit dashed target orbit
            if !bloom.isLit {
                let orbitR = bloom.radius * CGFloat(breath)
                context.stroke(
                    Path(ellipseIn: CGRect(x: c.x - orbitR, y: c.y - orbitR, width: orbitR * 2, height: orbitR * 2)),
                    with: .color(bloom.color.withAlpha(0.68).color),
                    style: StrokeStyle(lineWidth: 1.8, dash: [5, 5])
                )
            }

            // Flower petals
            let petalScale: CGFloat = bloom.isLit
                ? CGFloat(0.65 + 0.55 * easeOutBack(bloom.bloomProgress))
                : CGFloat(0.56 * breath)
            let petalLen = bloom.radius * petalScale
            var petalPath = Path()
            for i in 0..<bloom.petalCount {
                let angle = Double(i) / Double(bloom.petalCount) * Double.pi * 2.0 + bloom.pulsePhase * (bloom.isLit ? 0.35 : 0.15)
                let tip = CGPoint(x: c.x + CGFloat(cos(angle)) * petalLen, y: c.y + CGFloat(sin(angle)) * petalLen)
                let spread = Double.pi / Double(bloom.petalCount) * 0.72
                let ctrlR = petalLen * 0.62
                let c1 = CGPoint(x: c.x + CGFloat(cos(angle - spread)) * ctrlR, y: c.y + CGFloat(sin(angle - spread)) * ctrlR)
                let c2 = CGPoint(x: c.x + CGFloat(cos(angle + spread)) * ctrlR, y: c.y + CGFloat(sin(angle + spread)) * ctrlR)
                petalPath.move(to: c)
                petalPath.addQuadCurve(to: tip, control: c1)
                petalPath.addQuadCurve(to: c, control: c2)
            }

            if bloom.isLit {
                context.fill(petalPath, with: .color(bloom.color.withAlpha(0.45).color))
                context.stroke(petalPath, with: .color(bloom.color.color), style: StrokeStyle(lineWidth: 2.6, lineJoin: .round))
                context.stroke(petalPath, with: .color(Color.white.opacity(0.8)), style: StrokeStyle(lineWidth: 1.0, lineJoin: .round))
            } else {
                context.fill(petalPath, with: .color(bloom.color.withAlpha(0.18).color))
                context.stroke(petalPath, with: .color(bloom.color.withAlpha(0.85).color), style: StrokeStyle(lineWidth: 1.8, lineJoin: .round))
            }

            // Center jewel
            let coreR: CGFloat = bloom.isLit ? 6.0 : 4.0
            context.fill(
                Path(ellipseIn: CGRect(x: c.x - coreR, y: c.y - coreR, width: coreR * 2, height: coreR * 2)),
                with: .color(bloom.isLit ? .white : bloom.color.withAlpha(0.9).color)
            )
        }
    }

    // MARK: - Prisms

    private func drawPrisms(in context: inout GraphicsContext) {
        for prism in engine.prisms {
            let c = prism.position
            let scale = 1.0 + CGFloat(prism.pulse) * 0.35
            let r = prism.radius * scale
            let rainbow = RGBAColor.rainbow(phase: engine.elapsedTime * 0.35 + prism.rotation * 0.1)

            // Prismatic halo
            context.fill(
                Path(ellipseIn: CGRect(x: c.x - r * 2.1, y: c.y - r * 2.1, width: r * 4.2, height: r * 4.2)),
                with: .radialGradient(
                    Gradient(colors: [rainbow.withAlpha(0.40 + prism.pulse * 0.35).color, .clear]),
                    center: c,
                    startRadius: 2,
                    endRadius: r * 2.1
                )
            )

            // Rotating diamond crystal
            var diamond = Path()
            for idx in 0..<4 {
                let angle = prism.rotation + Double(idx) * (Double.pi / 2.0)
                let pt = CGPoint(x: c.x + CGFloat(cos(angle)) * r, y: c.y + CGFloat(sin(angle)) * r)
                if idx == 0 { diamond.move(to: pt) } else { diamond.addLine(to: pt) }
            }
            diamond.closeSubpath()

            context.fill(diamond, with: .color(rainbow.withAlpha(0.24 + prism.pulse * 0.3).color))
            context.stroke(diamond, with: .color(rainbow.withAlpha(0.95).color), style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))
            context.stroke(diamond, with: .color(Color.white.opacity(0.85)), style: StrokeStyle(lineWidth: 1.0, lineJoin: .round))

            // Inner triangle refraction facet
            var inner = Path()
            for idx in 0..<3 {
                let angle = -prism.rotation * 1.4 + Double(idx) * (Double.pi * 2.0 / 3.0)
                let pt = CGPoint(x: c.x + CGFloat(cos(angle)) * (r * 0.45), y: c.y + CGFloat(sin(angle)) * (r * 0.45))
                if idx == 0 { inner.move(to: pt) } else { inner.addLine(to: pt) }
            }
            inner.closeSubpath()
            context.stroke(inner, with: .color(Color.white.opacity(0.75)), lineWidth: 1.2)
        }
    }

    // MARK: - Elastic Neon Strings

    private func drawStrings(in context: inout GraphicsContext) {
        for string in engine.strings {
            let a = string.start
            let b = CGPoint.lerp(string.start, string.end, t: CGFloat(easeOutBack(string.appearProgress)))
            let color: RGBAColor
            if string.kind == .prism {
                color = RGBAColor.rainbow(phase: engine.elapsedTime * 0.45 + Double(string.start.x) * 0.002)
            } else {
                color = engine.theme.colorForStringKind(string.kind)
            }

            let offsetMag = sin(string.vibrationPhase) * Double(string.vibrationAmplitude)
            let anchorOnLine = CGPoint.lerp(a, b, t: string.pluckedT)
            let control = anchorOnLine.adding(string.vibrationNormal.scaled(by: CGFloat(offsetMag) * 1.65))

            var curve = Path()
            curve.move(to: a)
            curve.addQuadCurve(to: b, control: control)

            let glowBoost = 1.0 + string.glowIntensity * 0.75
            let capStyle = StrokeStyle(lineWidth: 16.0 * CGFloat(glowBoost), lineCap: .round)
            let midStyle = StrokeStyle(lineWidth: 7.0 * CGFloat(glowBoost), lineCap: .round)
            let coreStyle = StrokeStyle(lineWidth: string.kind == .boost ? 3.5 : 2.6, lineCap: .round)
            let whiteStyle = StrokeStyle(lineWidth: 1.2, lineCap: .round)

            context.stroke(curve, with: .color(color.withAlpha(0.16 + string.glowIntensity * 0.14).color), style: capStyle)
            context.stroke(curve, with: .color(color.withAlpha(0.45 + string.glowIntensity * 0.25).color), style: midStyle)
            context.stroke(curve, with: .color(color.color), style: coreStyle)
            context.stroke(curve, with: .color(Color.white.opacity(0.88)), style: whiteStyle)

            // Anchor pegs at both ends
            for endpoint in [a, b] {
                let r: CGFloat = 4.8 + CGFloat(string.glowIntensity) * 1.8
                context.fill(
                    Path(ellipseIn: CGRect(x: endpoint.x - r * 2.0, y: endpoint.y - r * 2.0, width: r * 4.0, height: r * 4.0)),
                    with: .color(color.withAlpha(0.28).color)
                )
                context.fill(
                    Path(ellipseIn: CGRect(x: endpoint.x - r, y: endpoint.y - r, width: r * 2, height: r * 2)),
                    with: .color(color.color)
                )
                context.fill(
                    Path(ellipseIn: CGRect(x: endpoint.x - 2.0, y: endpoint.y - 2.0, width: 4.0, height: 4.0)),
                    with: .color(.white)
                )
            }
        }
    }

    private func drawDragPreview(in context: inout GraphicsContext) {
        guard let preview = engine.dragPreview, preview.length > 8 else { return }
        let color = preview.kind == .prism
            ? RGBAColor.rainbow(phase: engine.elapsedTime * 0.9)
            : engine.theme.colorForStringKind(preview.kind)

        var line = Path()
        line.move(to: preview.start)
        line.addLine(to: preview.end)

        context.stroke(line, with: .color(color.withAlpha(0.25).color), style: StrokeStyle(lineWidth: 12, lineCap: .round))
        context.stroke(line, with: .color(color.withAlpha(0.95).color), style: StrokeStyle(lineWidth: 2.6, lineCap: .round, dash: [8, 6]))

        for pt in [preview.start, preview.end] {
            let r: CGFloat = 7.0
            context.stroke(
                Path(ellipseIn: CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)),
                with: .color(color.color),
                lineWidth: 2.0
            )
            context.fill(
                Path(ellipseIn: CGRect(x: pt.x - 3, y: pt.y - 3, width: 6, height: 6)),
                with: .color(.white)
            )
        }
    }

    // MARK: - Star Drops & Trails

    private func drawDrops(in context: inout GraphicsContext) {
        for drop in engine.drops {
            // Luminous tapered trail
            if drop.trail.count >= 2 {
                for idx in 1..<drop.trail.count {
                    let ratio = Double(idx) / Double(drop.trail.count)
                    var seg = Path()
                    seg.move(to: drop.trail[idx - 1])
                    seg.addLine(to: drop.trail[idx])
                    context.stroke(
                        seg,
                        with: .color(drop.color.withAlpha(ratio * 0.55).color),
                        style: StrokeStyle(lineWidth: CGFloat(ratio) * drop.radius * 1.15, lineCap: .round)
                    )
                }
            }

            let c = drop.position
            let haloR = drop.radius * (drop.combo >= 3 ? 2.9 : 2.3)
            context.fill(
                Path(ellipseIn: CGRect(x: c.x - haloR, y: c.y - haloR, width: haloR * 2, height: haloR * 2)),
                with: .radialGradient(
                    Gradient(colors: [drop.color.withAlpha(0.62).color, drop.color.withAlpha(0.10).color, .clear]),
                    center: c,
                    startRadius: 1,
                    endRadius: haloR
                )
            )

            // Skin-specific geometry
            let shapePath = dropSkinPath(center: c, radius: drop.radius, rotation: drop.rotation, skin: engine.dropSkin)
            context.fill(shapePath, with: .color(drop.color.color))
            context.stroke(shapePath, with: .color(Color.white.opacity(0.9)), lineWidth: 1.2)

            // Hot white core
            let coreR = drop.radius * 0.42
            context.fill(
                Path(ellipseIn: CGRect(x: c.x - coreR, y: c.y - coreR, width: coreR * 2, height: coreR * 2)),
                with: .color(.white)
            )
        }
    }

    private func dropSkinPath(center: CGPoint, radius: CGFloat, rotation: Double, skin: DropSkin) -> Path {
        switch skin {
        case .starlight:
            return Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))

        case .diamond:
            var path = Path()
            for i in 0..<4 {
                let a = rotation + Double(i) * Double.pi * 0.5
                let r = (i % 2 == 0) ? radius * 1.25 : radius * 0.92
                let pt = CGPoint(x: center.x + CGFloat(cos(a)) * r, y: center.y + CGFloat(sin(a)) * r)
                if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
            }
            path.closeSubpath()
            return path

        case .sakura:
            var path = Path()
            let petals = 5
            for i in 0..<petals {
                let a = rotation * 0.7 + Double(i) / Double(petals) * Double.pi * 2.0
                let tip = CGPoint(x: center.x + CGFloat(cos(a)) * radius * 1.3, y: center.y + CGFloat(sin(a)) * radius * 1.3)
                let c1 = CGPoint(x: center.x + CGFloat(cos(a - 0.5)) * radius * 0.85, y: center.y + CGFloat(sin(a - 0.5)) * radius * 0.85)
                let c2 = CGPoint(x: center.x + CGFloat(cos(a + 0.5)) * radius * 0.85, y: center.y + CGFloat(sin(a + 0.5)) * radius * 0.85)
                path.move(to: center)
                path.addQuadCurve(to: tip, control: c1)
                path.addQuadCurve(to: center, control: c2)
            }
            return path

        case .comet:
            var path = Path()
            let spikes = 4
            for i in 0..<(spikes * 2) {
                let a = rotation + Double(i) / Double(spikes * 2) * Double.pi * 2.0
                let r = (i % 2 == 0) ? radius * 1.45 : radius * 0.52
                let pt = CGPoint(x: center.x + CGFloat(cos(a)) * r, y: center.y + CGFloat(sin(a)) * r)
                if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
            }
            path.closeSubpath()
            return path

        case .heartNova:
            let box = CGRect(x: center.x - radius * 1.2, y: center.y - radius * 1.15, width: radius * 2.4, height: radius * 2.3)
            return HeartNovaShape().path(in: box)
        }
    }

    // MARK: - Sparks, Ripples & Floating Texts

    private func drawSparks(in context: inout GraphicsContext) {
        for spark in engine.sparks {
            let alpha = 1.0 - spark.progress
            let r = spark.size * CGFloat(1.0 - spark.progress * 0.5)
            let rect = CGRect(x: spark.position.x - r, y: spark.position.y - r, width: r * 2, height: r * 2)
            context.fill(Path(ellipseIn: rect), with: .color(spark.color.withAlpha(alpha).color))
        }
    }

    private func drawRipples(in context: inout GraphicsContext) {
        for ripple in engine.ripples {
            let p = ripple.progress
            let eased = 1.0 - pow(1.0 - p, 3.0)
            let r = max(2.0, ripple.maxRadius * CGFloat(eased))
            let alpha = (1.0 - p) * 0.85
            let rect = CGRect(x: ripple.center.x - r, y: ripple.center.y - r, width: r * 2, height: r * 2)
            context.stroke(
                Path(ellipseIn: rect),
                with: .color(ripple.color.withAlpha(alpha).color),
                lineWidth: ripple.lineWidth * CGFloat(1.0 - p * 0.65)
            )
        }
    }

    private func drawFloatingScores(in context: inout GraphicsContext) {
        for item in engine.floatingScores {
            let alpha = 1.0 - pow(item.progress, 2.0)
            let text = Text(item.text)
                .font(.system(size: item.fontSize, weight: .heavy, design: .rounded))
                .foregroundStyle(item.color.withAlpha(alpha).color)
            context.draw(text, at: item.position)
        }
    }

    private func drawFeverBorder(in context: inout GraphicsContext, size: CGSize) {
        let rainbow = RGBAColor.rainbow(phase: engine.elapsedTime * 0.85)
        let insetRect = CGRect(origin: .zero, size: size).insetBy(dx: 3, dy: 3)
        let borderPath = Path(roundedRect: insetRect, cornerRadius: 20)
        context.stroke(borderPath, with: .color(rainbow.withAlpha(0.55).color), lineWidth: 5.0)
    }

    private func easeOutBack(_ t: Double) -> Double {
        let clamped = max(0.0, min(1.0, t))
        let c1 = 1.70158
        let c3 = c1 + 1.0
        return 1.0 + c3 * pow(clamped - 1.0, 3.0) + c1 * pow(clamped - 1.0, 2.0)
    }
}
