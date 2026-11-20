import SwiftUI
import Foundation

private struct SpecimenPulseRing: Identifiable {
    let id = UUID()
    var expanded: Bool = false
}

struct SpecimenDetailView: View {
    let specimen: NeonSpecimen

    @EnvironmentObject private var progressStore: NeonProgressStore
    @State private var pokeCount: Int = 0
    @State private var squashScale: CGFloat = 1.0
    @State private var rotationDegrees: Double = 0.0
    @State private var dragOffset: CGSize = .zero
    @State private var pulsePhase: Double = 0.0
    @State private var pulseRings: [SpecimenPulseRing] = []

    var body: some View {
        ZStack {
            progressStore.selectedTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer(minLength: 8)

                // Interactive pokeable neon specimen stage
                ZStack {
                    // Ambient halo
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    specimen.primaryColor.color.opacity(0.36),
                                    specimen.secondaryColor.color.opacity(0.12),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 150
                            )
                        )
                        .frame(width: 290, height: 290)

                    // Orbiting decorative rings
                    Circle()
                        .stroke(
                            specimen.primaryColor.color.opacity(0.28),
                            style: StrokeStyle(lineWidth: 1.5, dash: [6, 8])
                        )
                        .frame(width: 224, height: 224)
                        .rotationEffect(.degrees(rotationDegrees * 0.4))

                    Circle()
                        .stroke(
                            specimen.secondaryColor.color.opacity(0.22),
                            lineWidth: 1.2
                        )
                        .frame(width: 174, height: 174)

                    // Expanding tactile pulse rings
                    ForEach(pulseRings) { ring in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [specimen.primaryColor.color, specimen.secondaryColor.color],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: ring.expanded ? 1.0 : 4.0
                            )
                            .frame(width: ring.expanded ? 280 : 88, height: ring.expanded ? 280 : 88)
                            .opacity(ring.expanded ? 0.0 : 0.9)
                    }

                    // Interactive specimen artwork
                    SpecimenArtworkView(
                        specimen: specimen,
                        unlocked: true,
                        size: 164,
                        pulsePhase: pulsePhase
                    )
                    .scaleEffect(x: squashScale, y: 2.0 - squashScale)
                    .rotationEffect(.degrees(rotationDegrees))
                    .offset(dragOffset)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                dragOffset = CGSize(
                                    width: max(-45, min(45, value.translation.width * 0.45)),
                                    height: max(-45, min(45, value.translation.height * 0.45))
                                )
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.45)) {
                                    dragOffset = .zero
                                }
                                triggerPoke()
                            }
                    )
                }
                .frame(height: 290)

                // Info card
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Text(specimen.rarityLabel)
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(specimen.primaryColor.color))

                        Text("共鳴タッチ \(pokeCount)回")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.75))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.white.opacity(0.10)))
                    }

                    Text(specimen.title)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(Color.white)

                    Text(specimen.poeticNote)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.84))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 8)

                    Text("解放条件: \(specimen.unlockHint)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(specimen.secondaryColor.color.opacity(0.9))
                        .padding(.top, 2)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(specimen.primaryColor.color.opacity(0.4), lineWidth: 1.2)
                        )
                )
                .padding(.horizontal, 18)

                Button {
                    triggerPoke()
                } label: {
                    Label("光パルスを響かせる", systemImage: "sparkles")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 26)
                        .padding(.vertical, 13)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [specimen.primaryColor.color, specimen.secondaryColor.color],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: specimen.primaryColor.color.opacity(0.55), radius: 14)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 10)
            }
        }
        .navigationTitle(specimen.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            while !Task.isCancelled {
                await MainActor.run {
                    pulsePhase += 0.08
                    rotationDegrees += 0.35
                }
                try? await Task.sleep(nanoseconds: 33_000_000)
            }
        }
        .sensoryFeedback(.impact(weight: .light, intensity: 0.85), trigger: pokeCount)
    }

    private func triggerPoke() {
        pokeCount += 1
        withAnimation(.spring(response: 0.16, dampingFraction: 0.42)) {
            squashScale = 1.22
            rotationDegrees += 24
        }
        Task {
            try? await Task.sleep(nanoseconds: 120_000_000)
            await MainActor.run {
                withAnimation(.spring(response: 0.36, dampingFraction: 0.45)) {
                    squashScale = 1.0
                }
            }
        }

        let newRing = SpecimenPulseRing()
        pulseRings.append(newRing)
        let ringID = newRing.id
        withAnimation(.easeOut(duration: 0.72)) {
            if let idx = pulseRings.firstIndex(where: { $0.id == ringID }) {
                pulseRings[idx].expanded = true
            }
        }
        Task {
            try? await Task.sleep(nanoseconds: 760_000_000)
            await MainActor.run {
                pulseRings.removeAll { $0.id == ringID }
            }
        }
    }
}
