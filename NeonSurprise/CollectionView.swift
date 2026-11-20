import SwiftUI
import Foundation

struct CollectionView: View {
    @EnvironmentObject private var progressStore: NeonProgressStore
    @State private var lockedHintMessage: String? = nil

    private let specimenColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                progressStore.selectedTheme.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerBanner
                        statsDashboard
                        skinSelectorSection
                        specimenGridSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("図鑑・記録")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: NeonSpecimen.self) { specimen in
                SpecimenDetailView(specimen: specimen)
            }
        }
    }

    // MARK: - Header Banner

    private var headerBanner: some View {
        let unlockedCount = progressStore.unlockedSpecimenIDs.count
        let totalSpecimens = MissionCatalog.specimens.count
        let clearedMissions = progressStore.completedMissionIDs.count
        let totalMissions = MissionCatalog.missions.count

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [progressStore.selectedTheme.primary.color.opacity(0.45), .clear],
                            center: .center,
                            startRadius: 2,
                            endRadius: 34
                        )
                    )
                    .frame(width: 62, height: 62)

                LotusBloomShape(petals: 6)
                    .stroke(
                        LinearGradient(
                            colors: [progressStore.selectedTheme.primary.color, progressStore.selectedTheme.secondary.color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.6
                    )
                    .frame(width: 36, height: 36)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("ネオン光標本ラボ")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("遊んだ軌跡が光標本としてコレクションされます。解放された標本はタップしてつついて遊べるよ！")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    miniProgressPill(title: "光標本", value: "\(unlockedCount)/\(totalSpecimens)", color: progressStore.selectedTheme.primary.color)
                    miniProgressPill(title: "星座", value: "\(clearedMissions)/\(totalMissions)", color: progressStore.selectedTheme.secondary.color)
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(progressStore.selectedTheme.primary.color.opacity(0.35), lineWidth: 1.2)
                )
        )
    }

    private func miniProgressPill(title: String, value: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.75))
            Text(value)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.black.opacity(0.38)))
    }

    // MARK: - Stats Dashboard

    private var statsDashboard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("プレイレコード")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.9))

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                statCard(title: "ハイスコア", value: "\(progressStore.bestScore)", icon: "trophy.fill", color: RGBAColor.neonGold.color)
                statCard(title: "最大コンボ", value: "×\(progressStore.maxCombo)", icon: "flame.fill", color: progressStore.selectedTheme.secondary.color)
                statCard(title: "弦のはじき回数", value: "\(progressStore.totalPlucks)", icon: "waveform.path", color: progressStore.selectedTheme.primary.color)
                statCard(title: "開花させた花", value: "\(progressStore.totalBlooms)", icon: "camera.macro", color: progressStore.selectedTheme.accent.color)
                statCard(title: "プリズム分裂", value: "\(progressStore.totalPrismSplits)", icon: "rhombus.fill", color: RGBAColor.neonViolet.color)
                statCard(title: "FEVER回数", value: "\(progressStore.feverCount)", icon: "sparkles", color: RGBAColor.neonCyan.color)
            }
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(Circle().fill(color.opacity(0.16)))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.65))
                Text(value)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white)
            }
            Spacer()
        }
        .padding(11)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    // MARK: - Drop Skin Selector

    private var skinSelectorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("しずくスキン")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.9))
                Spacer()
                Text("装備中: \(progressStore.selectedSkin.displayName)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(progressStore.selectedTheme.primary.color)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(DropSkin.allCases) { skin in
                        let unlocked = progressStore.isSkinUnlocked(skin)
                        let equipped = progressStore.selectedSkin == skin
                        Button {
                            if unlocked {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    progressStore.selectedSkin = skin
                                }
                            } else {
                                withAnimation {
                                    lockedHintMessage = "「\(skin.displayName)」解放条件: \(skin.unlockDescription)"
                                }
                            }
                        } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            unlocked
                                                ? progressStore.selectedTheme.primary.color.opacity(equipped ? 0.34 : 0.16)
                                                : Color.white.opacity(0.06)
                                        )
                                        .frame(width: 46, height: 46)
                                    Image(systemName: unlocked ? skin.iconName : "lock.fill")
                                        .font(.system(size: 19, weight: .bold))
                                        .foregroundStyle(unlocked ? progressStore.selectedTheme.primary.color : Color.white.opacity(0.35))
                                }

                                Text(skin.displayName)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(unlocked ? Color.white : Color.white.opacity(0.45))

                                Text(equipped ? "装備中" : (unlocked ? "タップで装備" : skin.unlockDescription))
                                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                                    .foregroundStyle(equipped ? progressStore.selectedTheme.accent.color : Color.white.opacity(0.55))
                                    .lineLimit(1)
                            }
                            .frame(width: 118)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white.opacity(equipped ? 0.12 : 0.06))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(
                                                equipped ? progressStore.selectedTheme.primary.color : Color.white.opacity(0.12),
                                                lineWidth: equipped ? 1.8 : 1
                                            )
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Specimen Grid

    private var specimenGridSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ネオン光標本コレクション")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.9))

            if let hint = lockedHintMessage {
                HStack(spacing: 8) {
                    Image(systemName: "lock.open.trianglebadge.exclamationmark")
                        .foregroundStyle(progressStore.selectedTheme.secondary.color)
                    Text(hint)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white)
                    Spacer()
                    Button {
                        withAnimation { lockedHintMessage = nil }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.10))
                )
                .transition(.opacity)
            }

            LazyVGrid(columns: specimenColumns, spacing: 10) {
                ForEach(MissionCatalog.specimens) { specimen in
                    let unlocked = progressStore.isSpecimenUnlocked(specimen.id)
                    if unlocked {
                        NavigationLink(value: specimen) {
                            specimenCell(specimen: specimen, unlocked: true)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                lockedHintMessage = "「\(specimen.title)」解放条件: \(specimen.unlockHint)"
                            }
                        } label: {
                            specimenCell(specimen: specimen, unlocked: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func specimenCell(specimen: NeonSpecimen, unlocked: Bool) -> some View {
        VStack(spacing: 6) {
            SpecimenArtworkView(specimen: specimen, unlocked: unlocked, size: 58)

            Text(unlocked ? specimen.title : "？？？")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(unlocked ? Color.white : Color.white.opacity(0.42))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(specimen.rarityLabel)
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .foregroundStyle(unlocked ? specimen.primaryColor.color : Color.white.opacity(0.32))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(unlocked ? specimen.primaryColor.color.opacity(0.16) : Color.white.opacity(0.05))
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(unlocked ? 0.08 : 0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            unlocked ? specimen.primaryColor.color.opacity(0.45) : Color.white.opacity(0.08),
                            lineWidth: 1.1
                        )
                )
        )
    }
}
