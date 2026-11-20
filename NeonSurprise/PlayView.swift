import SwiftUI
import Foundation

enum PlaySubMode: String, CaseIterable, Identifiable {
    case mission = "mission"
    case endless = "endless"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .mission: return "星座ミッション"
        case .endless: return "エンドレス"
        }
    }
}

struct PlayView: View {
    let isActiveTab: Bool

    @EnvironmentObject private var progressStore: NeonProgressStore
    @StateObject private var engine = NeonSimulationEngine(mode: .mission(0))
    @State private var subMode: PlaySubMode = .mission
    @State private var currentMissionIndex: Int = 0
    @State private var selectedStringKind: StringKind = .standard
    @State private var dragStartPoint: CGPoint? = nil
    @State private var showMissionPicker: Bool = false
    @State private var hasDrawnFirstString: Bool = false

    private var currentMission: ConstellationMission {
        MissionCatalog.missions[max(0, min(MissionCatalog.missions.count - 1, currentMissionIndex))]
    }

    var body: some View {
        ZStack {
            progressStore.selectedTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 8) {
                topHeaderBar
                hudSummaryBar
                interactiveStage
                bottomControlDock
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 8)
        }
        .onAppear {
            engine.attachProgressStore(progressStore)
            engine.syncAppearance(theme: progressStore.selectedTheme, skin: progressStore.selectedSkin)
        }
        .onChange(of: progressStore.changeCounter) { _, _ in
            engine.syncAppearance(theme: progressStore.selectedTheme, skin: progressStore.selectedSkin)
        }
        .task(id: isActiveTab) {
            guard isActiveTab else { return }
            await MainActor.run { engine.resetClock() }
            while !Task.isCancelled {
                await MainActor.run { engine.step() }
                try? await Task.sleep(nanoseconds: 16_000_000)
            }
        }
        .sheet(isPresented: $showMissionPicker) {
            MissionPickerSheet(
                selectedIndex: currentMissionIndex,
                completedIDs: progressStore.completedMissionIDs,
                theme: progressStore.selectedTheme
            ) { chosenIndex in
                currentMissionIndex = chosenIndex
                subMode = .mission
                engine.loadMission(index: chosenIndex)
                showMissionPicker = false
            }
            .presentationDetents([.medium, .large])
        }
        .sensoryFeedback(.impact(weight: .light, intensity: 0.75), trigger: engine.pluckTrigger)
        .sensoryFeedback(.success, trigger: engine.bloomTrigger)
    }

    // MARK: - Top Header Bar

    private var topHeaderBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(PlaySubMode.allCases) { item in
                    let isSelected = subMode == item
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                            subMode = item
                            if item == .mission {
                                engine.loadMission(index: currentMissionIndex)
                            } else {
                                engine.switchMode(.endless)
                            }
                        }
                    } label: {
                        Text(item.label)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(isSelected ? Color.black : Color.white.opacity(0.78))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(isSelected ? progressStore.selectedTheme.primary.color : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 1))
            )

            Spacer()

            if subMode == .mission {
                Button {
                    showMissionPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "list.star")
                        Text("\(currentMissionIndex + 1)/\(MissionCatalog.missions.count)")
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.10))
                            .overlay(Capsule().stroke(progressStore.selectedTheme.primary.color.opacity(0.45), lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
            }

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    engine.rebuildCurrentScene()
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.10))
                            .overlay(Circle().stroke(Color.white.opacity(0.16), lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("リスタート")
        }
    }

    // MARK: - HUD Summary Bar

    private var hudSummaryBar: some View {
        VStack(spacing: 6) {
            if subMode == .mission {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(currentMission.subtitle)
                                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                .foregroundStyle(progressStore.selectedTheme.primary.color)
                            Text(currentMission.title)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        Text(currentMission.hint)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.72))
                            .lineLimit(1)
                    }
                    Spacer()
                    HStack(spacing: 10) {
                        hudBadge(
                            icon: "camera.macro",
                            text: "\(engine.litBloomCount)/\(engine.totalBloomCount)",
                            color: progressStore.selectedTheme.secondary.color
                        )
                        hudBadge(
                            icon: "waveform.path",
                            text: "\(engine.activeStringCount)/\(engine.maxStringsAllowed)",
                            color: progressStore.selectedTheme.primary.color
                        )
                    }
                }
            } else {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("SCORE")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.55))
                        Text("\(engine.score)")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("BEST")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.55))
                        Text("\(progressStore.bestScore)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(progressStore.selectedTheme.primary.color)
                    }

                    Spacer()

                    if engine.currentCombo >= 2 {
                        Text("\(engine.currentCombo) COMBO!")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(progressStore.selectedTheme.accent.color)
                            )
                            .scaleEffect(engine.currentCombo >= 5 ? 1.08 : 1.0)
                            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: engine.currentCombo)
                    }

                    hudBadge(
                        icon: "sparkles",
                        text: "W\(engine.waveNumber)",
                        color: progressStore.selectedTheme.secondary.color
                    )
                }

                // Fever gauge bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.10))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: engine.isFeverActive
                                        ? [Color.pink, Color.yellow, Color.mint, Color.cyan]
                                        : [progressStore.selectedTheme.primary.color, progressStore.selectedTheme.secondary.color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geo.size.width * CGFloat(engine.feverGauge)))
                            .animation(.easeOut(duration: 0.18), value: engine.feverGauge)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private func hudBadge(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color.white.opacity(0.09)))
    }

    // MARK: - Interactive Canvas Stage

    private var interactiveStage: some View {
        GeometryReader { geo in
            ZStack {
                NeonCanvasView(engine: engine)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        progressStore.selectedTheme.primary.color.opacity(0.55),
                                        progressStore.selectedTheme.secondary.color.opacity(0.35)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.4
                            )
                    )
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onChanged { value in
                                if dragStartPoint == nil {
                                    dragStartPoint = value.startLocation
                                }
                                if let start = dragStartPoint {
                                    let clamped = clampPoint(value.location, in: geo.size)
                                    if start.distance(to: clamped) >= 14 {
                                        engine.updateDragPreview(start: start, current: clamped, kind: selectedStringKind)
                                    }
                                }
                            }
                            .onEnded { value in
                                let start = dragStartPoint ?? value.startLocation
                                let end = clampPoint(value.location, in: geo.size)
                                dragStartPoint = nil
                                if start.distance(to: end) < 14 {
                                    engine.dragPreview = nil
                                    engine.handlePlayTap(at: end)
                                } else {
                                    engine.commitDragString(start: start, end: end, kind: selectedStringKind)
                                    hasDrawnFirstString = true
                                }
                            }
                    )
                    .onAppear {
                        engine.updateCanvasSize(geo.size)
                    }
                    .onChange(of: geo.size) { _, newSize in
                        engine.updateCanvasSize(newSize)
                    }

                // Floating top banner inside stage
                if let banner = engine.bannerMessage {
                    VStack {
                        Text(banner)
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.65))
                                    .overlay(
                                        Capsule()
                                            .stroke(progressStore.selectedTheme.primary.color.opacity(0.75), lineWidth: 1.2)
                                    )
                            )
                            .shadow(color: progressStore.selectedTheme.primary.color.opacity(0.5), radius: 10)
                            .padding(.top, 14)
                        Spacer()
                    }
                    .transition(.scale.combined(with: .opacity))
                    .allowsHitTesting(false)
                }

                // First-time onboarding tip
                if !hasDrawnFirstString && !engine.isMissionCleared {
                    VStack {
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "hand.draw.fill")
                                .foregroundStyle(progressStore.selectedTheme.primary.color)
                            Text("画面を指でなぞって光の弦を張ろう ✨")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.62))
                                .overlay(Capsule().stroke(progressStore.selectedTheme.primary.color.opacity(0.6), lineWidth: 1))
                        )
                        .padding(.bottom, 14)
                    }
                    .allowsHitTesting(false)
                }

                // Mission Cleared Overlay
                if engine.isMissionCleared && subMode == .mission {
                    missionClearOverlay
                        .transition(.scale(scale: 0.86).combined(with: .opacity))
                }
            }
        }
    }

    private var missionClearOverlay: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [progressStore.selectedTheme.primary.color.opacity(0.4), .clear],
                            center: .center,
                            startRadius: 4,
                            endRadius: 50
                        )
                    )
                    .frame(width: 96, height: 96)

                StarPolygonShape(points: 6, innerRatio: 0.45)
                    .fill(
                        LinearGradient(
                            colors: [RGBAColor.neonGold.color, progressStore.selectedTheme.secondary.color],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: RGBAColor.neonGold.color.opacity(0.8), radius: 12)
            }

            Text("星座コンプリート!")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text(currentMission.title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(progressStore.selectedTheme.primary.color)

            HStack(spacing: 18) {
                VStack(spacing: 2) {
                    Text("SCORE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.6))
                    Text("\(engine.score)")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.white)
                }
                VStack(spacing: 2) {
                    Text("MAX COMBO")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.6))
                    Text("×\(max(1, engine.sessionMaxCombo))")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(progressStore.selectedTheme.accent.color)
                }
                VStack(spacing: 2) {
                    Text("STRINGS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.6))
                    Text("\(engine.activeStringCount)")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(progressStore.selectedTheme.secondary.color)
                }
            }
            .padding(.vertical, 6)

            HStack(spacing: 10) {
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                        engine.rebuildCurrentScene()
                    }
                } label: {
                    Text("もう一度")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 11)
                        .background(Capsule().fill(Color.white.opacity(0.14)))
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                        if currentMissionIndex + 1 < MissionCatalog.missions.count {
                            currentMissionIndex += 1
                            engine.loadMission(index: currentMissionIndex)
                        } else {
                            subMode = .endless
                            engine.switchMode(.endless)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(currentMissionIndex + 1 < MissionCatalog.missions.count ? "次の星座へ" : "エンドレスへ挑戦")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 11)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [progressStore.selectedTheme.primary.color, progressStore.selectedTheme.accent.color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.black.opacity(0.84))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(progressStore.selectedTheme.primary.color.opacity(0.7), lineWidth: 1.6)
                )
        )
        .shadow(color: progressStore.selectedTheme.primary.color.opacity(0.35), radius: 22)
        .padding(.horizontal, 22)
    }

    // MARK: - Bottom Control Dock

    private var bottomControlDock: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(StringKind.allCases) { kind in
                    let isSelected = selectedStringKind == kind
                    let color = progressStore.selectedTheme.colorForStringKind(kind).color
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                            selectedStringKind = kind
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: kind.iconName)
                                .font(.system(size: 13, weight: .bold))
                            Text(kind.label)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(isSelected ? Color.black : Color.white.opacity(0.86))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isSelected ? color : Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(color.opacity(isSelected ? 1.0 : 0.35), lineWidth: 1.2)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 8) {
                Button {
                    engine.undoLastString()
                } label: {
                    Label("1本戻す", systemImage: "arrow.uturn.backward")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(engine.activeStringCount > 0 ? 0.92 : 0.38))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .disabled(engine.activeStringCount == 0)

                Button {
                    engine.clearAllStrings()
                } label: {
                    Label("弦クリア", systemImage: "trash")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(engine.activeStringCount > 0 ? 0.92 : 0.38))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .disabled(engine.activeStringCount == 0)

                Button {
                    engine.launchBurst()
                } label: {
                    Label("バースト!", systemImage: "sparkles")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [progressStore.selectedTheme.secondary.color, RGBAColor.neonGold.color],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func clampPoint(_ pt: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: max(12, min(size.width - 12, pt.x)),
            y: max(12, min(size.height - 12, pt.y))
        )
    }
}

// MARK: - Mission Picker Sheet

struct MissionPickerSheet: View {
    let selectedIndex: Int
    let completedIDs: Set<Int>
    let theme: NeonTheme
    let onSelect: (Int) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(MissionCatalog.missions.enumerated()), id: \.element.id) { idx, mission in
                            let cleared = completedIDs.contains(mission.id)
                            let active = idx == selectedIndex
                            Button {
                                onSelect(idx)
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(cleared ? theme.accent.color.opacity(0.24) : Color.white.opacity(0.08))
                                            .frame(width: 42, height: 42)
                                        if cleared {
                                            Image(systemName: "checkmark.seal.fill")
                                                .font(.system(size: 20))
                                                .foregroundStyle(theme.accent.color)
                                        } else {
                                            Text("\(mission.id)")
                                                .font(.system(size: 16, weight: .black, design: .monospaced))
                                                .foregroundStyle(theme.primary.color)
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 6) {
                                            Text(mission.subtitle)
                                                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                                .foregroundStyle(theme.primary.color)
                                            if active {
                                                Text("プレイ中")
                                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                                    .foregroundStyle(.black)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Capsule().fill(theme.primary.color))
                                            }
                                        }
                                        Text(mission.title)
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)
                                        Text(mission.hint)
                                            .font(.system(size: 11, design: .rounded))
                                            .foregroundStyle(Color.white.opacity(0.68))
                                            .lineLimit(2)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Color.white.opacity(0.4))
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.white.opacity(active ? 0.12 : 0.06))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(active ? theme.primary.color.opacity(0.8) : Color.white.opacity(0.10), lineWidth: 1.2)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("星座ミッション一覧")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
