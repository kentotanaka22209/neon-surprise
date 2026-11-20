import SwiftUI
import Foundation

enum SimulationMode: Equatable, Sendable {
    case mission(Int)
    case endless
    case sandbox
}

@MainActor
final class NeonSimulationEngine: ObservableObject {
    // MARK: - Published State for HUD & View Updates
    @Published var frameTick: UInt64 = 0
    @Published var score: Int = 0
    @Published var currentCombo: Int = 0
    @Published var sessionMaxCombo: Int = 0
    @Published var waveNumber: Int = 1
    @Published var feverGauge: Double = 0.0
    @Published var isFeverActive: Bool = false
    @Published var feverRemaining: Double = 0.0
    @Published var isMissionCleared: Bool = false
    @Published var litBloomCount: Int = 0
    @Published var totalBloomCount: Int = 0
    @Published var activeStringCount: Int = 0
    @Published var maxStringsAllowed: Int = 6
    @Published var dragPreview: DragPreviewLine? = nil
    @Published var shakeOffset: CGSize = .zero
    @Published var screenFlashOpacity: Double = 0.0
    @Published var bannerMessage: String? = nil
    @Published var pluckTrigger: Int = 0
    @Published var bloomTrigger: Int = 0

    // MARK: - Simulation Entities (Read directly by Canvas)
    var drops: [StarDrop] = []
    var strings: [NeonString] = []
    var blooms: [ResonanceBloom] = []
    var prisms: [LightPrism] = []
    var gravityOrbs: [GravityOrb] = []
    var emitters: [EmitterNode] = []
    var sparks: [SparkParticle] = []
    var ripples: [RippleWave] = []
    var floatingScores: [FloatingScore] = []
    let backgroundStars: [BackgroundStar]

    // MARK: - Configuration
    var mode: SimulationMode = .mission(0)
    var theme: NeonTheme = .cyberTokyo
    var dropSkin: DropSkin = .starlight
    var gravityPreset: GravityPreset = .normal
    var dropTempo: DropTempo = .rhythmic
    var elapsedTime: Double = 0.0
    private(set) var canvasSize: CGSize = .zero

    private weak var progressStore: NeonProgressStore?
    private var hasConfiguredScene: Bool = false
    private var lastStepTimestamp: Double = 0.0
    private var spawnAccumulator: Double = 0.0
    private var comboResetTimer: Double = 0.0
    private var shakeIntensity: CGFloat = 0.0
    private var bannerTimer: Double = 0.0
    private var waveTransitionTimer: Double = 0.0
    private var lastBurstTime: Double = 0.0
    private var lastPaintTime: Double = 0.0
    private var pendingSandboxPresetID: String = "trampoline"

    private let maxDropsCap: Int = 34
    private let maxSparksCap: Int = 180

    init(mode: SimulationMode = .mission(0)) {
        self.mode = mode
        var stars: [BackgroundStar] = []
        for idx in 0..<68 {
            let seed = Double(idx) * 1.61803398875
            let nx = CGFloat((seed * 73.1).truncatingRemainder(dividingBy: 1.0))
            let ny = CGFloat((seed * 41.7).truncatingRemainder(dividingBy: 1.0))
            let size = CGFloat(1.0 + (seed * 19.3).truncatingRemainder(dividingBy: 2.2))
            let phase = (seed * 11.1).truncatingRemainder(dividingBy: Double.pi * 2.0)
            let speed = 0.8 + (seed * 5.7).truncatingRemainder(dividingBy: 2.0)
            stars.append(BackgroundStar(id: idx, normX: abs(nx), normY: abs(ny), size: size, phase: phase, speed: speed))
        }
        self.backgroundStars = stars
    }

    func attachProgressStore(_ store: NeonProgressStore) {
        self.progressStore = store
        self.theme = store.selectedTheme
        self.dropSkin = store.selectedSkin
    }

    func syncAppearance(theme: NeonTheme, skin: DropSkin) {
        self.theme = theme
        self.dropSkin = skin
    }

    func resetClock() {
        lastStepTimestamp = Date().timeIntervalSinceReferenceDate
    }

    // MARK: - Canvas Sizing & Scene Setup

    func updateCanvasSize(_ newSize: CGSize) {
        guard newSize.width > 40, newSize.height > 40 else { return }
        if !hasConfiguredScene {
            canvasSize = newSize
            hasConfiguredScene = true
            rebuildCurrentScene()
            return
        }
        let dx = abs(newSize.width - canvasSize.width)
        let dy = abs(newSize.height - canvasSize.height)
        guard dx > 2.0 || dy > 2.0 else { return }

        let sx = newSize.width / max(1.0, canvasSize.width)
        let sy = newSize.height / max(1.0, canvasSize.height)
        rescaleAllEntities(scaleX: sx, scaleY: sy)
        canvasSize = newSize
    }

    private func rescaleAllEntities(scaleX: CGFloat, scaleY: CGFloat) {
        for i in drops.indices {
            drops[i].position = CGPoint(x: drops[i].position.x * scaleX, y: drops[i].position.y * scaleY)
            drops[i].trail = drops[i].trail.map { CGPoint(x: $0.x * scaleX, y: $0.y * scaleY) }
        }
        for i in strings.indices {
            strings[i].start = CGPoint(x: strings[i].start.x * scaleX, y: strings[i].start.y * scaleY)
            strings[i].end = CGPoint(x: strings[i].end.x * scaleX, y: strings[i].end.y * scaleY)
        }
        for i in blooms.indices {
            blooms[i].position = CGPoint(x: blooms[i].position.x * scaleX, y: blooms[i].position.y * scaleY)
        }
        for i in prisms.indices {
            prisms[i].position = CGPoint(x: prisms[i].position.x * scaleX, y: prisms[i].position.y * scaleY)
        }
        for i in gravityOrbs.indices {
            gravityOrbs[i].position = CGPoint(x: gravityOrbs[i].position.x * scaleX, y: gravityOrbs[i].position.y * scaleY)
        }
        for i in emitters.indices {
            emitters[i].position = CGPoint(x: emitters[i].position.x * scaleX, y: emitters[i].position.y * scaleY)
        }
    }

    func switchMode(_ newMode: SimulationMode) {
        mode = newMode
        if hasConfiguredScene {
            rebuildCurrentScene()
        }
    }

    func loadMission(index: Int) {
        let clamped = max(0, min(MissionCatalog.missions.count - 1, index))
        mode = .mission(clamped)
        if hasConfiguredScene {
            rebuildCurrentScene()
        }
    }

    func loadSandboxPreset(id: String) {
        pendingSandboxPresetID = id
        mode = .sandbox
        if hasConfiguredScene {
            rebuildCurrentScene()
        }
    }

    func rebuildCurrentScene() {
        drops.removeAll()
        strings.removeAll()
        blooms.removeAll()
        prisms.removeAll()
        gravityOrbs.removeAll()
        emitters.removeAll()
        sparks.removeAll()
        ripples.removeAll()
        floatingScores.removeAll()

        score = 0
        currentCombo = 0
        sessionMaxCombo = 0
        feverGauge = 0.0
        isFeverActive = false
        feverRemaining = 0.0
        isMissionCleared = false
        waveNumber = 1
        waveTransitionTimer = 0.0
        spawnAccumulator = 0.35

        guard canvasSize.width > 40, canvasSize.height > 40 else { return }

        switch mode {
        case .mission(let index):
            setupMissionScene(index: index)
        case .endless:
            setupEndlessScene()
        case .sandbox:
            setupSandboxPresetScene(id: pendingSandboxPresetID)
        }

        syncCounters()
        spawnFromEmitters(isBurst: false)
    }

    private func point(fromNormalized norm: CGPoint) -> CGPoint {
        CGPoint(x: norm.x * canvasSize.width, y: norm.y * canvasSize.height)
    }

    private func setupMissionScene(index: Int) {
        let safeIndex = max(0, min(MissionCatalog.missions.count - 1, index))
        let mission = MissionCatalog.missions[safeIndex]
        gravityPreset = mission.gravity
        dropTempo = .rhythmic
        maxStringsAllowed = mission.maxStrings

        emitters = mission.emitters.map {
            EmitterNode(position: point(fromNormalized: $0.position), launchVelocity: $0.launchVelocity)
        }
        blooms = mission.blooms.enumerated().map { idx, normBloom in
            let color = idx % 2 == 0 ? theme.primary : theme.secondary
            return ResonanceBloom(
                position: point(fromNormalized: normBloom.position),
                radius: 23.0,
                petalCount: normBloom.petals,
                color: color
            )
        }
        prisms = mission.prisms.map {
            LightPrism(position: point(fromNormalized: $0), radius: 22.0)
        }
        gravityOrbs = mission.gravityOrbs.map {
            GravityOrb(position: point(fromNormalized: $0.position), swirlDirection: $0.swirl)
        }
        strings = mission.starterStrings.map {
            NeonString(
                start: point(fromNormalized: $0.start),
                end: point(fromNormalized: $0.end),
                kind: $0.kind
            )
        }
        showBanner("\(mission.subtitle)  \(mission.title)", duration: 1.8)
    }

    private func setupEndlessScene() {
        gravityPreset = .normal
        dropTempo = .rhythmic
        maxStringsAllowed = 7
        waveNumber = 1

        emitters = [
            EmitterNode(position: point(fromNormalized: CGPoint(x: 0.32, y: 0.11)), launchVelocity: CGPoint(x: 24, y: 65)),
            EmitterNode(position: point(fromNormalized: CGPoint(x: 0.68, y: 0.11)), launchVelocity: CGPoint(x: -24, y: 65))
        ]
        strings = [
            NeonString(
                start: point(fromNormalized: CGPoint(x: 0.18, y: 0.66)),
                end: point(fromNormalized: CGPoint(x: 0.48, y: 0.72)),
                kind: .standard
            )
        ]
        populateEndlessWave(wave: 1)
        showBanner("WAVE 1 スタート!", duration: 1.6)
    }

    private func populateEndlessWave(wave: Int) {
        blooms.removeAll()
        prisms.removeAll()
        gravityOrbs.removeAll()

        let bloomCount = min(7, 3 + wave)
        let pattern = (wave - 1) % 4
        for idx in 0..<bloomCount {
            let t = Double(idx) / Double(max(1, bloomCount - 1))
            let normPos: CGPoint
            switch pattern {
            case 0:
                // Sweeping constellation arc
                let x = 0.16 + 0.68 * t
                let y = 0.30 + sin(t * Double.pi) * 0.28 + (idx % 2 == 0 ? 0.0 : 0.12)
                normPos = CGPoint(x: x, y: y)
            case 1:
                // Diamond ring
                let angle = Double(idx) / Double(bloomCount) * Double.pi * 2.0 - Double.pi / 2.0
                let x = 0.50 + cos(angle) * 0.32
                let y = 0.48 + sin(angle) * 0.24
                normPos = CGPoint(x: x, y: y)
            case 2:
                // Zigzag waterfall
                let x = idx % 2 == 0 ? 0.22 + 0.12 * t : 0.78 - 0.12 * t
                let y = 0.24 + 0.52 * t
                normPos = CGPoint(x: x, y: y)
            default:
                // Twin cluster wings
                let side: Double = idx % 2 == 0 ? -1.0 : 1.0
                let row = Double(idx / 2)
                let x = 0.50 + side * (0.18 + row * 0.08)
                let y = 0.28 + row * 0.18
                normPos = CGPoint(x: min(0.86, max(0.14, x)), y: min(0.78, y))
            }

            let color: RGBAColor
            if idx % 3 == 0 { color = theme.primary }
            else if idx % 3 == 1 { color = theme.secondary }
            else { color = theme.accent }

            blooms.append(
                ResonanceBloom(
                    position: point(fromNormalized: normPos),
                    radius: 22.0,
                    petalCount: 5 + (idx % 4),
                    color: color
                )
            )
        }

        if wave >= 2 {
            prisms.append(LightPrism(position: point(fromNormalized: CGPoint(x: 0.50, y: 0.34))))
        }
        if wave >= 4 {
            prisms.append(LightPrism(position: point(fromNormalized: CGPoint(x: 0.50, y: 0.58))))
        }
        if wave >= 3 {
            let swirl: CGFloat = wave % 2 == 0 ? -1.0 : 1.0
            gravityOrbs.append(GravityOrb(position: point(fromNormalized: CGPoint(x: 0.50, y: 0.46)), swirlDirection: swirl))
        }
        syncCounters()
    }

    private func setupSandboxPresetScene(id: String) {
        let preset = MissionCatalog.sandboxPresets.first(where: { $0.id == id }) ?? MissionCatalog.sandboxPresets[0]
        gravityPreset = preset.gravity
        dropTempo = preset.tempo
        maxStringsAllowed = 10

        if gravityPreset == .zeroG {
            progressStore?.recordZeroGravityUsed()
        }

        emitters = preset.emitters.map {
            EmitterNode(position: point(fromNormalized: $0.position), launchVelocity: $0.launchVelocity)
        }
        strings = preset.strings.map {
            NeonString(
                start: point(fromNormalized: $0.start),
                end: point(fromNormalized: $0.end),
                kind: $0.kind
            )
        }
        prisms = preset.prisms.map {
            LightPrism(position: point(fromNormalized: $0))
        }
        gravityOrbs = preset.gravityOrbs.map {
            GravityOrb(position: point(fromNormalized: $0.position), swirlDirection: $0.swirl)
        }
        blooms = preset.blooms.enumerated().map { idx, b in
            let color = idx % 2 == 0 ? theme.primary : theme.secondary
            return ResonanceBloom(position: point(fromNormalized: b.position), radius: 22.0, petalCount: b.petals, color: color)
        }
        showBanner("プリセット「\(preset.title)」", duration: 1.5)
    }

    // MARK: - User Interactions

    func updateDragPreview(start: CGPoint, current: CGPoint, kind: StringKind) {
        dragPreview = DragPreviewLine(start: start, end: current, kind: kind)
    }

    func commitDragString(start: CGPoint, end: CGPoint, kind: StringKind) {
        dragPreview = nil
        let length = start.distance(to: end)
        guard length >= 28.0 else { return }

        if strings.count >= maxStringsAllowed, let oldest = strings.first {
            spawnSparkBurst(at: oldest.midpoint, color: theme.colorForStringKind(oldest.kind), count: 8, speed: 95)
            strings.removeFirst()
        }

        let newString = NeonString(start: start, end: end, kind: kind)
        strings.append(newString)
        let color = theme.colorForStringKind(kind)
        ripples.append(RippleWave(center: start, maxRadius: 28, color: color, lineWidth: 2.2, maxLife: 0.35))
        ripples.append(RippleWave(center: end, maxRadius: 28, color: color, lineWidth: 2.2, maxLife: 0.35))
        spawnSparkBurst(at: newString.midpoint, color: color, count: 10, speed: 120)
        pluckTrigger += 1
        syncCounters()
    }

    func undoLastString() {
        guard let removed = strings.popLast() else { return }
        let color = theme.colorForStringKind(removed.kind)
        spawnSparkBurst(at: removed.midpoint, color: color, count: 12, speed: 110)
        ripples.append(RippleWave(center: removed.midpoint, maxRadius: 48, color: color, lineWidth: 2.0, maxLife: 0.4))
        syncCounters()
    }

    func clearAllStrings() {
        for s in strings {
            spawnSparkBurst(at: s.midpoint, color: theme.colorForStringKind(s.kind), count: 8, speed: 100)
        }
        strings.removeAll()
        syncCounters()
    }

    func clearSandboxCanvas() {
        drops.removeAll()
        strings.removeAll()
        prisms.removeAll()
        gravityOrbs.removeAll()
        blooms.removeAll()
        if emitters.isEmpty && canvasSize.width > 40 {
            emitters = [EmitterNode(position: point(fromNormalized: CGPoint(x: 0.50, y: 0.12)), launchVelocity: CGPoint(x: 0, y: 65))]
        }
        ripples.append(RippleWave(center: CGPoint(x: canvasSize.width * 0.5, y: canvasSize.height * 0.5), maxRadius: 180, color: theme.primary, lineWidth: 2.4, maxLife: 0.6))
        syncCounters()
    }

    func launchBurst() {
        let now = Date().timeIntervalSinceReferenceDate
        guard now - lastBurstTime > 0.32 else { return }
        lastBurstTime = now
        spawnFromEmitters(isBurst: true)
        addScreenShake(4.2)
        pluckTrigger += 1
    }

    func setGravityPreset(_ preset: GravityPreset) {
        gravityPreset = preset
        if preset == .zeroG {
            progressStore?.recordZeroGravityUsed()
            // Give stationary drops a gentle push in zero-g
            for i in drops.indices {
                if drops[i].velocity.magnitude < 90 {
                    let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
                    drops[i].velocity = CGPoint(x: cos(angle) * 160, y: sin(angle) * 160)
                }
            }
        }
    }

    func handlePlayTap(at location: CGPoint) {
        if pluckStringNear(location) {
            return
        }
        ripples.append(RippleWave(center: location, maxRadius: 56, color: theme.primary.withAlpha(0.8), lineWidth: 2.0, maxLife: 0.45))
        nudgeNearbyDrops(from: location, radius: 95, force: 110)
    }

    func handleSandboxTap(at location: CGPoint, tool: SandboxTool) {
        switch tool {
        case .drawString:
            if pluckStringNear(location) { return }
            spawnDrop(
                at: location,
                velocity: CGPoint(x: CGFloat.random(in: -75...75), y: CGFloat.random(in: -140 ... -40)),
                color: theme.primary,
                isRainbow: Bool.random()
            )
            ripples.append(RippleWave(center: location, maxRadius: 48, color: theme.primary, lineWidth: 2.0, maxLife: 0.42))

        case .placePrism:
            if let existingIndex = prisms.firstIndex(where: { $0.position.distance(to: location) < 34 }) {
                let pos = prisms[existingIndex].position
                prisms.remove(at: existingIndex)
                spawnSparkBurst(at: pos, color: theme.accent, count: 12, speed: 120)
            } else {
                if prisms.count >= 6 { prisms.removeFirst() }
                prisms.append(LightPrism(position: location))
                ripples.append(RippleWave(center: location, maxRadius: 54, color: theme.accent, lineWidth: 2.5, maxLife: 0.45))
            }
            pluckTrigger += 1

        case .placeGravity:
            if let existingIndex = gravityOrbs.firstIndex(where: { $0.position.distance(to: location) < 38 }) {
                let pos = gravityOrbs[existingIndex].position
                gravityOrbs.remove(at: existingIndex)
                spawnSparkBurst(at: pos, color: .neonViolet, count: 14, speed: 120)
            } else {
                if gravityOrbs.count >= 4 { gravityOrbs.removeFirst() }
                let swirl: CGFloat = gravityOrbs.count % 2 == 0 ? 1.0 : -1.0
                gravityOrbs.append(GravityOrb(position: location, swirlDirection: swirl))
                ripples.append(RippleWave(center: location, maxRadius: 72, color: .neonViolet, lineWidth: 2.4, maxLife: 0.5))
            }
            pluckTrigger += 1

        case .placeBloom:
            if let existingIndex = blooms.firstIndex(where: { $0.position.distance(to: location) < 36 }) {
                let pos = blooms[existingIndex].position
                blooms.remove(at: existingIndex)
                spawnSparkBurst(at: pos, color: theme.secondary, count: 14, speed: 130)
            } else {
                if blooms.count >= 10 { blooms.removeFirst() }
                let color = blooms.count % 2 == 0 ? theme.primary : theme.secondary
                blooms.append(ResonanceBloom(position: location, radius: 22.0, petalCount: Int.random(in: 5...8), color: color))
                ripples.append(RippleWave(center: location, maxRadius: 58, color: color, lineWidth: 2.4, maxLife: 0.45))
            }
            pluckTrigger += 1

        case .paintDrops:
            let count = 5
            for idx in 0..<count {
                let angle = (CGFloat(idx) / CGFloat(count)) * CGFloat.pi * 2.0 + CGFloat.random(in: -0.2...0.2)
                let speed = CGFloat.random(in: 110...200)
                let vel = CGPoint(x: cos(angle) * speed, y: sin(angle) * speed)
                let color = RGBAColor.rainbow(phase: Double(idx) / Double(count) + elapsedTime * 0.25)
                spawnDrop(at: location, velocity: vel, color: color, isRainbow: true)
            }
            ripples.append(RippleWave(center: location, maxRadius: 64, color: theme.secondary, lineWidth: 2.6, maxLife: 0.48))
            bloomTrigger += 1
        }
        syncCounters()
    }

    func handleSandboxPaintDrag(at location: CGPoint) {
        let now = Date().timeIntervalSinceReferenceDate
        guard now - lastPaintTime > 0.085 else { return }
        lastPaintTime = now
        let vel = CGPoint(x: CGFloat.random(in: -90...90), y: CGFloat.random(in: -120...40))
        let color = RGBAColor.rainbow(phase: elapsedTime * 0.5)
        spawnDrop(at: location, velocity: vel, color: color, isRainbow: true)
        spawnSparkBurst(at: location, color: color, count: 3, speed: 70)
    }

    private func pluckStringNear(_ point: CGPoint) -> Bool {
        for i in strings.indices {
            let result = closestPointOnSegment(point: point, a: strings[i].start, b: strings[i].end)
            if result.distance < 24.0 {
                let dir = strings[i].end.subtracting(strings[i].start).normalized()
                strings[i].pluckedT = max(0.15, min(0.85, result.t))
                strings[i].vibrationAmplitude = 22.0
                strings[i].vibrationPhase = 0.0
                strings[i].vibrationNormal = CGPoint(x: -dir.y, y: dir.x)
                strings[i].glowIntensity = 1.0
                strings[i].pluckCount += 1

                let color = theme.colorForStringKind(strings[i].kind)
                ripples.append(RippleWave(center: result.closest, maxRadius: 68, color: color, lineWidth: 2.6, maxLife: 0.48))
                spawnSparkBurst(at: result.closest, color: color, count: 14, speed: 150)
                nudgeNearbyDrops(from: result.closest, radius: 105, force: 165)
                pluckTrigger += 1
                progressStore?.recordPluck(combo: max(1, currentCombo))
                return true
            }
        }
        return false
    }

    private func nudgeNearbyDrops(from center: CGPoint, radius: CGFloat, force: CGFloat) {
        for i in drops.indices {
            let diff = drops[i].position.subtracting(center)
            let dist = diff.magnitude
            if dist < radius && dist > 1.0 {
                let strength = (1.0 - dist / radius) * force
                let push = diff.normalized().scaled(by: strength)
                drops[i].velocity = drops[i].velocity.adding(push)
            }
        }
    }

    // MARK: - Main 60Hz Physics Step

    func step() {
        let now = Date().timeIntervalSinceReferenceDate
        let rawDt = lastStepTimestamp == 0 ? 0.016 : (now - lastStepTimestamp)
        lastStepTimestamp = now
        let dt = min(max(rawDt, 0.004), 0.033)
        elapsedTime += dt

        guard canvasSize.width > 40, canvasSize.height > 40 else {
            frameTick &+= 1
            return
        }

        // Update Fever timer
        if isFeverActive {
            feverRemaining -= dt
            feverGauge = max(0.0, feverRemaining / 9.0)
            if feverRemaining <= 0 {
                isFeverActive = false
                feverGauge = 0.0
            }
        }

        // Update banner timer
        if bannerTimer > 0 {
            bannerTimer -= dt
            if bannerTimer <= 0 {
                bannerMessage = nil
            }
        }

        // Update combo decay in Endless / Mission
        if comboResetTimer > 0 {
            comboResetTimer -= dt
            if comboResetTimer <= 0 && currentCombo > 0 {
                currentCombo = 0
            }
        }

        // Update screen recoil & flash
        if shakeIntensity > 0.1 {
            shakeIntensity *= CGFloat(exp(-14.0 * dt))
            let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            shakeOffset = CGSize(width: cos(angle) * shakeIntensity, height: sin(angle) * shakeIntensity)
        } else if shakeOffset != .zero {
            shakeIntensity = 0
            shakeOffset = .zero
        }

        if screenFlashOpacity > 0.005 {
            screenFlashOpacity = max(0.0, screenFlashOpacity - dt * 1.9)
        }

        // Endless wave transition timer
        if waveTransitionTimer > 0 {
            waveTransitionTimer -= dt
            if waveTransitionTimer <= 0 && mode == .endless {
                waveNumber += 1
                populateEndlessWave(wave: waveNumber)
                showBanner("WAVE \(waveNumber) スタート!", duration: 1.5)
            }
        }

        // Auto spawn drops from emitters
        let effectiveInterval: Double
        if isFeverActive {
            effectiveInterval = 0.28
        } else {
            effectiveInterval = dropTempo.spawnInterval
        }

        spawnAccumulator += dt
        if spawnAccumulator >= effectiveInterval && !isMissionCleared {
            spawnAccumulator = 0.0
            spawnFromEmitters(isBurst: false)
        }

        // Update static / animated field elements
        updateEmitters(dt: dt)
        updateStrings(dt: dt)
        updatePrisms(dt: dt)
        updateGravityOrbs(dt: dt)
        updateBlooms(dt: dt)

        // Two physics substeps for zero-tunneling segment collisions
        let substeps = 2
        let subDt = dt / Double(substeps)
        for _ in 0..<substeps {
            updateDrops(dt: subDt)
        }

        // Visual FX
        updateSparks(dt: dt)
        updateRipples(dt: dt)
        updateFloatingScores(dt: dt)

        frameTick &+= 1
    }

    // MARK: - Spawning

    private func spawnFromEmitters(isBurst: Bool) {
        guard !emitters.isEmpty else { return }
        for i in emitters.indices {
            emitters[i].pulse = 1.0
            let emitter = emitters[i]
            let count = isBurst ? 3 : 1
            for shot in 0..<count {
                let spread: CGFloat = isBurst ? CGFloat(shot - 1) * 0.26 : CGFloat.random(in: -0.08...0.08)
                let speedBoost: CGFloat = isBurst ? 1.18 : 1.0
                let baseVel = emitter.launchVelocity.rotated(by: spread).scaled(by: speedBoost)
                let color: RGBAColor
                if isFeverActive {
                    color = RGBAColor.rainbow(phase: elapsedTime * 0.7 + Double(shot) * 0.2)
                } else {
                    color = (i + shot) % 2 == 0 ? theme.primary : theme.secondary
                }
                spawnDrop(
                    at: emitter.position,
                    velocity: baseVel,
                    color: color,
                    isRainbow: isFeverActive
                )
            }
            ripples.append(RippleWave(center: emitter.position, maxRadius: isBurst ? 44 : 26, color: theme.primary.withAlpha(0.75), lineWidth: 1.8, maxLife: 0.35))
        }
    }

    private func spawnDrop(at position: CGPoint, velocity: CGPoint, color: RGBAColor, combo: Int = 0, isRainbow: Bool = false) {
        if drops.count >= maxDropsCap {
            drops.removeFirst()
        }
        let maxAge: Double = (gravityPreset == .zeroG) ? 20.0 : 13.0
        drops.append(
            StarDrop(
                position: position,
                velocity: velocity,
                radius: 8.5,
                color: color,
                combo: combo,
                isRainbow: isRainbow,
                maxAge: maxAge
            )
        )
    }

    // MARK: - Entity Updates

    private func updateEmitters(dt: Double) {
        for i in emitters.indices {
            emitters[i].phase += dt * 2.4
            emitters[i].pulse = max(0.0, emitters[i].pulse - dt * 3.0)
        }
    }

    private func updateStrings(dt: Double) {
        for i in strings.indices {
            if strings[i].appearProgress < 1.0 {
                strings[i].appearProgress = min(1.0, strings[i].appearProgress + dt * 6.5)
            }
            if strings[i].vibrationAmplitude > 0.08 {
                strings[i].vibrationAmplitude *= CGFloat(exp(-5.4 * dt))
                strings[i].vibrationPhase += 44.0 * dt
            } else {
                strings[i].vibrationAmplitude = 0
            }
            if strings[i].glowIntensity > 0 {
                strings[i].glowIntensity = max(0.0, strings[i].glowIntensity - dt * 2.1)
            }
        }
    }

    private func updatePrisms(dt: Double) {
        for i in prisms.indices {
            prisms[i].rotation += dt * 1.15
            if prisms[i].pulse > 0 {
                prisms[i].pulse = max(0.0, prisms[i].pulse - dt * 2.6)
            }
        }
    }

    private func updateGravityOrbs(dt: Double) {
        for i in gravityOrbs.indices {
            gravityOrbs[i].phase += dt * 2.2 * Double(gravityOrbs[i].swirlDirection)
        }
    }

    private func updateBlooms(dt: Double) {
        for i in blooms.indices {
            blooms[i].pulsePhase += dt * 2.6
            if blooms[i].isLit {
                if blooms[i].bloomProgress < 1.0 {
                    blooms[i].bloomProgress = min(1.0, blooms[i].bloomProgress + dt * 4.2)
                }
                if mode == .sandbox {
                    blooms[i].rearmTimer -= dt
                    if blooms[i].rearmTimer <= 0 {
                        blooms[i].isLit = false
                        blooms[i].bloomProgress = 0.0
                    }
                }
            }
        }
    }

    private func updateDrops(dt: Double) {
        let gravity = gravityPreset.acceleration
        var newlySplitDrops: [StarDrop] = []
        var indicesToRemove: [Int] = []

        for i in drops.indices {
            drops[i].age += dt
            drops[i].rotation += dt * 3.2
            if drops[i].stringCooldown > 0 { drops[i].stringCooldown -= dt }
            if drops[i].prismCooldown > 0 { drops[i].prismCooldown -= dt }

            if drops[i].isRainbow {
                drops[i].rainbowPhase += dt * 0.9
                drops[i].color = RGBAColor.rainbow(phase: drops[i].rainbowPhase)
            }

            // Apply gravity
            drops[i].velocity.y += gravity * CGFloat(dt)

            // Apply Gravity Orbs
            for orb in gravityOrbs {
                let toOrb = orb.position.subtracting(drops[i].position)
                let dist = toOrb.magnitude
                if dist < orb.influenceRadius && dist > 6.0 {
                    let clampedDist = max(dist, 34.0)
                    let pullMag = orb.strength / (clampedDist * clampedDist)
                    let dir = toOrb.normalized()
                    let tangent = CGPoint(x: -dir.y * orb.swirlDirection, y: dir.x * orb.swirlDirection)
                    let pull = dir.scaled(by: pullMag * CGFloat(dt))
                    let swirl = tangent.scaled(by: pullMag * 0.42 * CGFloat(dt))
                    drops[i].velocity = drops[i].velocity.adding(pull).adding(swirl)
                }
            }

            // Gentle aerodynamic drag at extreme speed
            let speed = drops[i].velocity.magnitude
            let maxSpeed: CGFloat = 760.0
            if speed > maxSpeed {
                drops[i].velocity = drops[i].velocity.normalized().scaled(by: maxSpeed)
            }

            // Integrate position
            drops[i].position = drops[i].position.adding(drops[i].velocity.scaled(by: CGFloat(dt)))

            // Trail recording
            if let lastTrail = drops[i].trail.last {
                if lastTrail.distance(to: drops[i].position) > 4.5 {
                    drops[i].trail.append(drops[i].position)
                    if drops[i].trail.count > 11 {
                        drops[i].trail.removeFirst()
                    }
                }
            }

            // Wall reflections
            let r = drops[i].radius
            if drops[i].position.x < r {
                drops[i].position.x = r
                drops[i].velocity.x = abs(drops[i].velocity.x) * 0.88
                spawnSparkBurst(at: drops[i].position, color: drops[i].color, count: 4, speed: 80)
            } else if drops[i].position.x > canvasSize.width - r {
                drops[i].position.x = canvasSize.width - r
                drops[i].velocity.x = -abs(drops[i].velocity.x) * 0.88
                spawnSparkBurst(at: drops[i].position, color: drops[i].color, count: 4, speed: 80)
            }

            if drops[i].position.y < r {
                drops[i].position.y = r
                drops[i].velocity.y = abs(drops[i].velocity.y) * 0.86
                spawnSparkBurst(at: drops[i].position, color: drops[i].color, count: 4, speed: 80)
            }

            if gravityPreset == .zeroG && drops[i].position.y > canvasSize.height - r {
                drops[i].position.y = canvasSize.height - r
                drops[i].velocity.y = -abs(drops[i].velocity.y) * 0.96
                spawnSparkBurst(at: drops[i].position, color: drops[i].color, count: 4, speed: 80)
            }

            // Neon String collisions
            handleStringCollisions(dropIndex: i)

            // Prism collisions
            if let splitDrop = handlePrismCollisions(dropIndex: i) {
                newlySplitDrops.append(splitDrop)
            }

            // Bloom collisions
            if let bonusDrop = handleBloomCollisions(dropIndex: i) {
                newlySplitDrops.append(bonusDrop)
            }

            // Lifetime & off-screen cull
            let offBottom = gravityPreset != .zeroG && drops[i].position.y > canvasSize.height + 36
            if offBottom || drops[i].age > drops[i].maxAge {
                indicesToRemove.append(i)
            }
        }

        for idx in indicesToRemove.reversed() {
            drops.remove(at: idx)
        }

        for extra in newlySplitDrops {
            if drops.count < maxDropsCap {
                drops.append(extra)
            }
        }
    }

    private func handleStringCollisions(dropIndex: Int) {
        let dropPos = drops[dropIndex].position
        let hitRadius = drops[dropIndex].radius + 5.0

        for sIdx in strings.indices {
            if drops[dropIndex].lastHitStringID == strings[sIdx].id && drops[dropIndex].stringCooldown > 0 {
                continue
            }

            let closestResult = closestPointOnSegment(point: dropPos, a: strings[sIdx].start, b: strings[sIdx].end)
            guard closestResult.distance < hitRadius else { continue }

            let diff = dropPos.subtracting(closestResult.closest)
            var normal: CGPoint
            if closestResult.distance > 0.001 {
                normal = diff.scaled(by: 1.0 / closestResult.distance)
            } else {
                let segDir = strings[sIdx].end.subtracting(strings[sIdx].start).normalized()
                normal = CGPoint(x: -segDir.y, y: segDir.x)
            }

            let vel = drops[dropIndex].velocity
            let vn = vel.dot(normal)
            if vn > 0 {
                normal = normal.scaled(by: -1.0)
            }

            let incomingSpeed = vel.magnitude
            let dotVN = vel.dot(normal)
            var reflected = vel.subtracting(normal.scaled(by: 2.0 * dotVN))

            let stringKind = strings[sIdx].kind
            switch stringKind {
            case .standard:
                reflected = reflected.scaled(by: 1.05)
                let minSpeed: CGFloat = 230.0
                if reflected.magnitude < minSpeed {
                    reflected = reflected.normalized().scaled(by: minSpeed)
                }
            case .boost:
                reflected = reflected.scaled(by: 1.38)
                let minBoost: CGFloat = 460.0
                if reflected.magnitude < minBoost {
                    reflected = reflected.normalized().scaled(by: minBoost)
                }
            case .prism:
                reflected = reflected.scaled(by: 1.12)
                let minPrism: CGFloat = 260.0
                if reflected.magnitude < minPrism {
                    reflected = reflected.normalized().scaled(by: minPrism)
                }
                drops[dropIndex].isRainbow = true
            }

            if reflected.magnitude > 760.0 {
                reflected = reflected.normalized().scaled(by: 760.0)
            }

            drops[dropIndex].position = closestResult.closest.adding(normal.scaled(by: hitRadius + 1.5))
            drops[dropIndex].velocity = reflected
            drops[dropIndex].lastHitStringID = strings[sIdx].id
            drops[dropIndex].stringCooldown = 0.085
            drops[dropIndex].combo += 1

            let stringColor = theme.colorForStringKind(stringKind)
            if !drops[dropIndex].isRainbow {
                drops[dropIndex].color = stringColor
            }

            // Pluck the string physically!
            strings[sIdx].pluckedT = max(0.12, min(0.88, closestResult.t))
            strings[sIdx].vibrationAmplitude = min(28.0, 11.0 + incomingSpeed * 0.036)
            strings[sIdx].vibrationPhase = 0.0
            strings[sIdx].vibrationNormal = normal.scaled(by: -1.0)
            strings[sIdx].glowIntensity = 1.0
            strings[sIdx].pluckCount += 1

            // Scoring & Combo feedback
            currentCombo += 1
            comboResetTimer = 2.6
            if currentCombo > sessionMaxCombo {
                sessionMaxCombo = currentCombo
            }

            if mode != .sandbox {
                let pts = 20 * min(10, drops[dropIndex].combo) * (isFeverActive ? 2 : 1)
                score += pts
                progressStore?.recordScore(score)
                addFever(0.065)
            }

            progressStore?.recordPluck(combo: max(currentCombo, drops[dropIndex].combo))
            pluckTrigger += 1

            // Visual haptics!
            let rippleColor = drops[dropIndex].isRainbow ? RGBAColor.rainbow(phase: drops[dropIndex].rainbowPhase) : stringColor
            ripples.append(
                RippleWave(
                    center: closestResult.closest,
                    maxRadius: stringKind == .boost ? 76.0 : 54.0,
                    color: rippleColor,
                    lineWidth: stringKind == .boost ? 3.2 : 2.2,
                    maxLife: 0.45
                )
            )
            spawnSparkBurst(
                at: closestResult.closest,
                color: rippleColor,
                count: stringKind == .boost ? 14 : 9,
                speed: stringKind == .boost ? 190 : 130
            )

            if drops[dropIndex].combo >= 3 {
                floatingScores.append(
                    FloatingScore(
                        text: "×\(drops[dropIndex].combo)",
                        position: closestResult.closest.adding(CGPoint(x: 0, y: -14)),
                        color: rippleColor,
                        fontSize: 16.0,
                        maxLife: 0.78
                    )
                )
            }
            if stringKind == .boost {
                addScreenShake(3.2)
            }
            break
        }
    }

    private func handlePrismCollisions(dropIndex: Int) -> StarDrop? {
        let dropPos = drops[dropIndex].position
        for pIdx in prisms.indices {
            if drops[dropIndex].lastHitPrismID == prisms[pIdx].id && drops[dropIndex].prismCooldown > 0 {
                continue
            }
            let dist = dropPos.distance(to: prisms[pIdx].position)
            guard dist < prisms[pIdx].radius + drops[dropIndex].radius else { continue }

            prisms[pIdx].pulse = 1.0
            let baseVel = drops[dropIndex].velocity.magnitude < 160
                ? drops[dropIndex].velocity.normalized().scaled(by: 240)
                : drops[dropIndex].velocity

            let leftVel = baseVel.rotated(by: -0.46)
            let rightVel = baseVel.rotated(by: 0.46)

            drops[dropIndex].velocity = leftVel
            drops[dropIndex].isRainbow = true
            drops[dropIndex].lastHitPrismID = prisms[pIdx].id
            drops[dropIndex].prismCooldown = 0.28

            var twin = StarDrop(
                position: prisms[pIdx].position,
                velocity: rightVel,
                radius: drops[dropIndex].radius,
                color: RGBAColor.rainbow(phase: drops[dropIndex].rainbowPhase + 0.35),
                combo: drops[dropIndex].combo + 1,
                isRainbow: true,
                maxAge: drops[dropIndex].maxAge
            )
            twin.lastHitPrismID = prisms[pIdx].id
            twin.prismCooldown = 0.28

            let prismColor = RGBAColor.rainbow(phase: elapsedTime * 0.8)
            ripples.append(RippleWave(center: prisms[pIdx].position, maxRadius: 72, color: prismColor, lineWidth: 2.8, maxLife: 0.5))
            spawnSparkBurst(at: prisms[pIdx].position, color: prismColor, count: 16, speed: 175)
            progressStore?.recordPrismSplit()
            pluckTrigger += 1
            addScreenShake(2.8)
            return twin
        }
        return nil
    }

    private func handleBloomCollisions(dropIndex: Int) -> StarDrop? {
        let dropPos = drops[dropIndex].position
        var bonusDrop: StarDrop? = nil

        for bIdx in blooms.indices {
            guard !blooms[bIdx].isLit else { continue }
            let dist = dropPos.distance(to: blooms[bIdx].position)
            guard dist < blooms[bIdx].radius + drops[dropIndex].radius + 3.0 else { continue }

            blooms[bIdx].isLit = true
            blooms[bIdx].bloomProgress = 0.05
            blooms[bIdx].rearmTimer = 1.35

            currentCombo += 1
            comboResetTimer = 3.2
            if currentCombo > sessionMaxCombo {
                sessionMaxCombo = currentCombo
            }

            let multiplier = max(1, drops[dropIndex].combo + 1)
            let feverFactor = isFeverActive ? 2 : 1
            let earned = 120 * multiplier * feverFactor

            if mode != .sandbox {
                score += earned
                addFever(0.18)
            }

            let bloomPos = blooms[bIdx].position
            let burstColor = drops[dropIndex].isRainbow ? RGBAColor.rainbow(phase: drops[dropIndex].rainbowPhase) : blooms[bIdx].color

            // Firework celebration!
            ripples.append(RippleWave(center: bloomPos, maxRadius: 112, color: burstColor, lineWidth: 3.6, maxLife: 0.65))
            ripples.append(RippleWave(center: bloomPos, maxRadius: 68, color: .pureWhite, lineWidth: 2.0, maxLife: 0.42))
            spawnSparkBurst(at: bloomPos, color: burstColor, count: 24, speed: 240)
            spawnSparkBurst(at: bloomPos, color: .neonGold, count: 10, speed: 150)

            let label = mode == .sandbox ? "✨ BLOOM!" : "+\(earned)"
            floatingScores.append(
                FloatingScore(
                    text: label,
                    position: bloomPos.adding(CGPoint(x: 0, y: -20)),
                    color: burstColor,
                    fontSize: multiplier >= 3 ? 22.0 : 18.0,
                    maxLife: 1.1
                )
            )

            addScreenShake(5.5)
            screenFlashOpacity = min(0.24, screenFlashOpacity + 0.14)
            bloomTrigger += 1
            progressStore?.recordBloomLit(score: score, combo: currentCombo)

            // Rainbow charged drops burst an extra celebratory drop!
            if drops[dropIndex].isRainbow {
                let angle = CGFloat.random(in: -CGFloat.pi ... 0)
                let bonusVel = CGPoint(x: cos(angle) * 260, y: sin(angle) * 260)
                bonusDrop = StarDrop(
                    position: bloomPos,
                    velocity: bonusVel,
                    color: RGBAColor.rainbow(phase: elapsedTime * 0.9),
                    combo: drops[dropIndex].combo + 1,
                    isRainbow: true
                )
            }

            checkObjectiveCompletion()
            syncCounters()
            break
        }
        return bonusDrop
    }

    private func addFever(_ amount: Double) {
        guard mode == .endless, !isFeverActive else { return }
        feverGauge = min(1.0, feverGauge + amount)
        if feverGauge >= 1.0 {
            isFeverActive = true
            feverRemaining = 9.0
            screenFlashOpacity = 0.30
            addScreenShake(8.0)
            showBanner("🌈 FEVER TIME!! SCORE ×2", duration: 2.2)
            progressStore?.recordFeverTriggered()
        }
    }

    private func checkObjectiveCompletion() {
        let allLit = !blooms.isEmpty && blooms.allSatisfy { $0.isLit }
        guard allLit else { return }

        switch mode {
        case .mission(let index):
            if !isMissionCleared {
                isMissionCleared = true
                let missionID = MissionCatalog.missions[index].id
                score += 500
                progressStore?.recordScore(score)
                progressStore?.markMissionCompleted(missionID)
                screenFlashOpacity = 0.28
                addScreenShake(7.0)
                for b in blooms {
                    spawnSparkBurst(at: b.position, color: .neonGold, count: 16, speed: 210)
                    ripples.append(RippleWave(center: b.position, maxRadius: 120, color: .neonGold, lineWidth: 3.0, maxLife: 0.75))
                }
            }
        case .endless:
            if waveTransitionTimer <= 0 {
                waveTransitionTimer = 0.95
                let bonus = 300 * waveNumber
                score += bonus
                progressStore?.recordScore(score)
                showBanner("✨ WAVE \(waveNumber) CLEAR! +\(bonus)", duration: 1.3)
                screenFlashOpacity = 0.25
                addScreenShake(6.5)
            }
        case .sandbox:
            break
        }
    }

    // MARK: - FX Updates

    private func updateSparks(dt: Double) {
        for i in sparks.indices {
            sparks[i].life += dt
            sparks[i].position = sparks[i].position.adding(sparks[i].velocity.scaled(by: CGFloat(dt)))
            sparks[i].velocity = sparks[i].velocity.scaled(by: CGFloat(exp(-3.4 * dt)))
            sparks[i].velocity.y += 90.0 * CGFloat(dt)
        }
        sparks.removeAll { $0.life >= $0.maxLife }
    }

    private func updateRipples(dt: Double) {
        for i in ripples.indices {
            ripples[i].life += dt
        }
        ripples.removeAll { $0.life >= $0.maxLife }
    }

    private func updateFloatingScores(dt: Double) {
        for i in floatingScores.indices {
            floatingScores[i].life += dt
            floatingScores[i].position.y -= CGFloat(38.0 * dt)
        }
        floatingScores.removeAll { $0.life >= $0.maxLife }
    }

    private func spawnSparkBurst(at point: CGPoint, color: RGBAColor, count: Int, speed: CGFloat) {
        for _ in 0..<count {
            if sparks.count >= maxSparksCap {
                sparks.removeFirst()
            }
            let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let mag = CGFloat.random(in: speed * 0.35 ... speed)
            let vel = CGPoint(x: cos(angle) * mag, y: sin(angle) * mag)
            let size = CGFloat.random(in: 2.2...4.8)
            let life = Double.random(in: 0.32...0.72)
            let sparkColor = Bool.random() ? color : color.lerped(to: .pureWhite, t: 0.45)
            sparks.append(SparkParticle(position: point, velocity: vel, size: size, color: sparkColor, maxLife: life))
        }
    }

    private func addScreenShake(_ intensity: CGFloat) {
        shakeIntensity = min(11.0, max(shakeIntensity, intensity))
    }

    private func showBanner(_ text: String, duration: Double) {
        bannerMessage = text
        bannerTimer = duration
    }

    private func syncCounters() {
        litBloomCount = blooms.filter { $0.isLit }.count
        totalBloomCount = blooms.count
        activeStringCount = strings.count
    }

    // MARK: - Segment Math Helper

    private func closestPointOnSegment(point: CGPoint, a: CGPoint, b: CGPoint) -> (closest: CGPoint, t: CGFloat, distance: CGFloat) {
        let ab = b.subtracting(a)
        let lenSq = ab.magnitudeSquared
        guard lenSq > 0.0001 else {
            return (a, 0.0, point.distance(to: a))
        }
        let ap = point.subtracting(a)
        let rawT = ap.dot(ab) / lenSq
        let clampedT = max(0.0, min(1.0, rawT))
        let closest = CGPoint(x: a.x + ab.x * clampedT, y: a.y + ab.y * clampedT)
        return (closest, clampedT, point.distance(to: closest))
    }
}
