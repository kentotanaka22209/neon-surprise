import SwiftUI
import Foundation

struct ContentView: View {
    @EnvironmentObject private var progressStore: NeonProgressStore
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                PlayView(isActiveTab: selectedTab == 0)
                    .tabItem {
                        Label("プレイ", systemImage: "sparkles")
                    }
                    .tag(0)

                SandboxView(isActiveTab: selectedTab == 1)
                    .tabItem {
                        Label("光の庭園", systemImage: "wand.and.stars")
                    }
                    .tag(1)

                CollectionView()
                    .tabItem {
                        Label("図鑑・記録", systemImage: "books.vertical.fill")
                    }
                    .tag(2)
            }
            .tint(progressStore.selectedTheme.primary.color)

            // Floating achievement unlock banner
            if let banner = progressStore.recentUnlockBanner {
                HStack(spacing: 8) {
                    Image(systemName: "sparkle")
                        .foregroundStyle(RGBAColor.neonGold.color)
                    Text(banner)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.84))
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [RGBAColor.neonGold.color, progressStore.selectedTheme.primary.color],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 1.4
                                )
                        )
                )
                .shadow(color: RGBAColor.neonGold.color.opacity(0.45), radius: 12)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onTapGesture {
                    withAnimation { progressStore.dismissBanner() }
                }
                .task(id: banner) {
                    try? await Task.sleep(nanoseconds: 2_800_000_000)
                    await MainActor.run {
                        withAnimation(.easeOut(duration: 0.25)) {
                            progressStore.dismissBanner()
                        }
                    }
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selectedTab)
    }
}
