import SwiftUI
import Foundation

struct SandboxView: View {
    let isActiveTab: Bool

    @EnvironmentObject private var progressStore: NeonProgressStore
    @StateObject private var engine = NeonSimulationEngine(mode: .sandbox)

    @State private var activeTool: SandboxTool = .drawString
    @State private var selectedStringKind: StringKind = .standard
    @State private var selectedGravity: GravityPreset = .normal
    @State private var selectedTempo: DropTempo = .rhythmic
    @State private var dragStartPoint: CGPoint? = nil
    @State private var showPresetSheet: Bool = false
    @State private var showThemeSheet: Bool = false

    var body: some View {
        ZStack {
            progressStore.selectedTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 8) {
                headerBar
                physicsStrip
                sandboxCanvas
                bottomToolDock
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 8)
        }
        .onAppear {
            engine.attachProgressStore(progressStore)
            engine.syncAppearance(theme: progressStore.selectedTheme, skin: progressStore.selectedSkin)
            selectedGravity = engine.gravityPreset
            selectedTempo = engine.dropTempo
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
        .sheet(isPresented: $showPresetSheet) {
            SandboxPresetSheet(theme: progressStore.selectedTheme) { preset in
                engine.loadSandboxPreset(id: preset.id)
                selectedGravity = preset.gravity
                selectedTempo = preset.tempo
                showPresetSheet = false
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showThemeSheet) {
            ThemePickerSheet(selectedTheme: progressStore.selectedTheme) { chosen in
                withAnimation(.easeInOut(duration: 0.25)) {
                    progressStore.selectedTheme = chosen
                    engine.syncAppearance(theme: chosen, skin: progressStore.selectedSkin)
                }
                showThemeSheet = false
            }
            .presentationDetents([.medium])
        }
        .sensoryFeedback(.impact(weight: .light, intensity: 0.7), trigger: engine.pluckTrigger)
        .sensoryFeedback(.success, trigger: engine.bloomTrigger)
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text("光の庭園")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(toolHintText)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.68))
                    .lineLimit(1)
            }

            Spacer()

            Button {
                showPresetSheet = true
            } label: {
                Label("造形", systemImage: "square.grid.2x2.fill")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.10))
                            .overlay(Capsule().stroke(progressStore.selectedTheme.primary.color.opacity(0.45), lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)

            Button {
                showThemeSheet = true
            } label: {
                HStack(spacing: 4) {
                    Circle()
                        .fill(progressStore.selectedTheme.primary.color)
                        .frame(width: 9, height: 9)
                    Circle()
                        .fill(progressStore.selectedTheme.secondary.color)
                        .frame(width: 9, height: 9)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.10))
                        .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("カラーテーマ選択")

            Button {
                engine.clearSandboxCanvas()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.10)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("キャンバスをクリア")
        }
    }

    private var toolHintText: String {
        switch activeTool {
        case .drawString: return "ドラッグで光の弦を張り、タップでしずく誕生"
        case .placePrism: return "タップで分裂プリズムを設置 / もう一度タップで削除"
        case .placeGravity: return "タップで引力玉を設置 / 軌道がぐるっと曲がるよ"
        case .placeBloom: return "タップで花火花を設置 / 当たるたび繰り返し開花"
        case .paintDrops: return "タップやなぞりで虹色の光のしずくを自由に散布！"
        }
    }

    // MARK: - Gravity & Tempo Strip

    private var physicsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(GravityPreset.allCases) { preset in
                    let isSelected = selectedGravity == preset
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                            selectedGravity = preset
                            engine.setGravityPreset(preset)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: preset.iconName)
                                .font(.system(size: 11, weight: .bold))
                            Text(preset.label)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(isSelected ? Color.black : Color.white.opacity(0.82))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(isSelected ? progressStore.selectedTheme.primary.color : Color.white.opacity(0.08))
                        )
                    }
                    .buttonStyle(.plain)
                }

                Divider()
                    .frame(height: 16)
                    .overlay(Color.white.opacity(0.2))
                    .padding(.horizontal, 2)

                ForEach(DropTempo.allCases) { tempo in
                    let isSelected = selectedTempo == tempo
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                            selectedTempo = tempo
                            engine.dropTempo = tempo
                        }
                    } label: {
                        Text(tempo.label)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(isSelected ? Color.black : Color.white.opacity(0.78))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(isSelected ? progressStore.selectedTheme.secondary.color : Color.white.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Interactive Sandbox Canvas

    private var sandboxCanvas: some View {
        GeometryReader { geo in
            ZStack {
                NeonCanvasView(engine: engine)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        progressStore.selectedTheme.secondary.color.opacity(0.55),
                                        progressStore.selectedTheme.accent.color.opacity(0.38)
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
                                let current = clampPoint(value.location, in: geo.size)
                                if activeTool == .paintDrops {
                                    engine.handleSandboxPaintDrag(at: current)
                                } else if activeTool == .drawString {
                                    if dragStartPoint == nil {
                                        dragStartPoint = clampPoint(value.startLocation, in: geo.size)
                                    }
                                    if let start = dragStartPoint, start.distance(to: current) >= 14 {
                                        engine.updateDragPreview(start: start, current: current, kind: selectedStringKind)
                                    }
                                }
                            }
                            .onEnded { value in
                                let start = dragStartPoint ?? clampPoint(value.startLocation, in: geo.size)
                                let end = clampPoint(value.location, in: geo.size)
                                dragStartPoint = nil

                                if activeTool == .drawString && start.distance(to: end) >= 14 {
                                    engine.commitDragString(start: start, end: end, kind: selectedStringKind)
                                } else {
                                    engine.dragPreview = nil
                                    engine.handleSandboxTap(at: end, tool: activeTool)
                                }
                            }
                    )
                    .onAppear {
                        engine.updateCanvasSize(geo.size)
                    }
                    .onChange(of: geo.size) { _, newSize in
                        engine.updateCanvasSize(newSize)
                    }

                if let banner = engine.bannerMessage {
                    VStack {
                        Text(banner)
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.65))
                                    .overlay(Capsule().stroke(progressStore.selectedTheme.secondary.color.opacity(0.75), lineWidth: 1.1))
                            )
                            .padding(.top, 12)
                        Spacer()
                    }
                    .allowsHitTesting(false)
                }
            }
        }
    }

    // MARK: - Bottom Tool Dock

    private var bottomToolDock: some View {
        VStack(spacing: 7) {
            if activeTool == .drawString {
                HStack(spacing: 6) {
                    ForEach(StringKind.allCases) { kind in
                        let selected = selectedStringKind == kind
                        let color = progressStore.selectedTheme.colorForStringKind(kind).color
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                selectedStringKind = kind
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: kind.iconName)
                                    .font(.system(size: 11, weight: .bold))
                                Text(kind.label)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(selected ? Color.black : Color.white.opacity(0.84))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(selected ? color : Color.white.opacity(0.08))
                                    .overlay(Capsule().stroke(color.opacity(0.45), lineWidth: 1))
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        engine.undoLastString()
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.white)
                            .frame(width: 34, height: 30)
                            .background(Capsule().fill(Color.white.opacity(0.10)))
                    }
                    .buttonStyle(.plain)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: 6) {
                ForEach(SandboxTool.allCases) { tool in
                    let isSelected = activeTool == tool
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                            activeTool = tool
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tool.iconName)
                                .font(.system(size: 15, weight: .bold))
                            Text(tool.label)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(isSelected ? Color.black : Color.white.opacity(0.84))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isSelected ? progressStore.selectedTheme.primary.color : Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(isSelected ? Color.white.opacity(0.5) : Color.white.opacity(0.12), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
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

// MARK: - Sandbox Preset Sheet

struct SandboxPresetSheet: View {
    let theme: NeonTheme
    let onSelect: (SandboxPreset) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(MissionCatalog.sandboxPresets) { preset in
                            Button {
                                onSelect(preset)
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(theme.primary.color.opacity(0.18))
                                            .frame(width: 46, height: 46)
                                        Image(systemName: preset.iconName)
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundStyle(theme.primary.color)
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(preset.title)
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)
                                        Text(preset.subtitle)
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(Color.white.opacity(0.7))
                                    }
                                    Spacer()
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(theme.secondary.color)
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.white.opacity(0.07))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("プリセット造形")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Theme Picker Sheet

struct ThemePickerSheet: View {
    let selectedTheme: NeonTheme
    let onSelect: (NeonTheme) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                selectedTheme.backgroundGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(NeonTheme.allCases) { item in
                            let isSelected = item == selectedTheme
                            Button {
                                onSelect(item)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: item.iconName)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(item.primary.color)
                                        .frame(width: 36, height: 36)
                                        .background(Circle().fill(item.primary.color.opacity(0.18)))

                                    Text(item.displayName)
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)

                                    Spacer()

                                    HStack(spacing: 6) {
                                        Circle().fill(item.primary.color).frame(width: 14, height: 14)
                                        Circle().fill(item.secondary.color).frame(width: 14, height: 14)
                                        Circle().fill(item.accent.color).frame(width: 14, height: 14)
                                    }

                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(item.primary.color)
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(item.backgroundGradient)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(isSelected ? item.primary.color : Color.white.opacity(0.18), lineWidth: isSelected ? 2 : 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("ネオンカラーテーマ")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
