import SwiftUI
import Foundation

@MainActor
final class NeonProgressStore: ObservableObject {
    @AppStorage("neon_best_score") var bestScore: Int = 0
    @AppStorage("neon_max_combo") var maxCombo: Int = 0
    @AppStorage("neon_total_plucks") var totalPlucks: Int = 0
    @AppStorage("neon_total_blooms") var totalBlooms: Int = 0
    @AppStorage("neon_total_prism_splits") var totalPrismSplits: Int = 0
    @AppStorage("neon_fever_count") var feverCount: Int = 0
    @AppStorage("neon_tried_zero_g") var triedZeroGravity: Bool = false
    @AppStorage("neon_completed_missions") private var completedMissionsRaw: String = ""
    @AppStorage("neon_unlocked_specimens") private var unlockedSpecimensRaw: String = ""
    @AppStorage("neon_selected_theme") private var selectedThemeRaw: String = NeonTheme.cyberTokyo.rawValue
    @AppStorage("neon_selected_skin") private var selectedSkinRaw: String = DropSkin.starlight.rawValue

    @Published var recentUnlockBanner: String? = nil
    @Published private(set) var changeCounter: Int = 0

    var selectedTheme: NeonTheme {
        get { NeonTheme(rawValue: selectedThemeRaw) ?? .cyberTokyo }
        set {
            selectedThemeRaw = newValue.rawValue
            changeCounter += 1
            objectWillChange.send()
        }
    }

    var selectedSkin: DropSkin {
        get { DropSkin(rawValue: selectedSkinRaw) ?? .starlight }
        set {
            guard isSkinUnlocked(newValue) else { return }
            selectedSkinRaw = newValue.rawValue
            changeCounter += 1
            objectWillChange.send()
        }
    }

    var completedMissionIDs: Set<Int> {
        Set(
            completedMissionsRaw
                .split(separator: ",")
                .compactMap { Int($0) }
        )
    }

    var unlockedSpecimenIDs: Set<String> {
        Set(
            unlockedSpecimensRaw
                .split(separator: ",")
                .map(String.init)
                .filter { !$0.isEmpty }
        )
    }

    func isMissionCompleted(_ id: Int) -> Bool {
        completedMissionIDs.contains(id)
    }

    func isSpecimenUnlocked(_ id: String) -> Bool {
        unlockedSpecimenIDs.contains(id)
    }

    func isSkinUnlocked(_ skin: DropSkin) -> Bool {
        switch skin {
        case .starlight:
            return true
        case .diamond:
            return totalPlucks >= 15
        case .sakura:
            return totalBlooms >= 5
        case .comet:
            return maxCombo >= 5
        case .heartNova:
            return completedMissionIDs.count >= 3 || bestScore >= 1200
        }
    }

    func recordPluck(combo: Int) {
        totalPlucks += 1
        if combo > maxCombo {
            maxCombo = combo
        }
        evaluateUnlocks()
    }

    func recordBloomLit(score: Int, combo: Int) {
        totalBlooms += 1
        if score > bestScore {
            bestScore = score
        }
        if combo > maxCombo {
            maxCombo = combo
        }
        evaluateUnlocks()
    }

    func recordScore(_ score: Int) {
        if score > bestScore {
            bestScore = score
            objectWillChange.send()
        }
    }

    func recordPrismSplit() {
        totalPrismSplits += 1
        evaluateUnlocks()
    }

    func recordFeverTriggered() {
        feverCount += 1
        evaluateUnlocks()
    }

    func recordZeroGravityUsed() {
        if !triedZeroGravity {
            triedZeroGravity = true
            evaluateUnlocks()
        }
    }

    func markMissionCompleted(_ id: Int) {
        var ids = completedMissionIDs
        let inserted = ids.insert(id).inserted
        if inserted {
            completedMissionsRaw = ids.sorted().map(String.init).joined(separator: ",")
            evaluateUnlocks()
        }
    }

    func dismissBanner() {
        recentUnlockBanner = nil
    }

    private func unlockSpecimen(_ id: String, title: String) {
        var ids = unlockedSpecimenIDs
        guard !ids.contains(id) else { return }
        ids.insert(id)
        unlockedSpecimensRaw = ids.sorted().joined(separator: ",")
        recentUnlockBanner = "図鑑解放「\(title)」"
    }

    private func evaluateUnlocks() {
        if totalPlucks >= 1 {
            unlockSpecimen("first_pluck", title: "初音のひとすじ")
        }
        if totalBlooms >= 1 {
            unlockSpecimen("first_bloom", title: "共鳴のつぼみ")
        }
        if totalPrismSplits >= 1 {
            unlockSpecimen("prism_spark", title: "双子の分光晶")
        }
        if maxCombo >= 5 {
            unlockSpecimen("combo_five", title: "五連星の残光")
        }
        if maxCombo >= 10 {
            unlockSpecimen("combo_ten", title: "十重の無限環")
        }
        if totalPlucks >= 100 {
            unlockSpecimen("pluck_hundred", title: "百弦の調律師")
        }
        if totalBlooms >= 30 {
            unlockSpecimen("bloom_thirty", title: "夜桜ネオン冠")
        }
        if totalPrismSplits >= 20 {
            unlockSpecimen("prism_twenty", title: "七色スペクトル核")
        }
        if triedZeroGravity {
            unlockSpecimen("zero_gravity", title: "無重力の旅人")
        }
        if feverCount >= 1 {
            unlockSpecimen("fever_master", title: "フィーバー超新星")
        }
        if completedMissionIDs.count >= 4 {
            unlockSpecimen("mission_four", title: "彗星ランタン")
        }
        if completedMissionIDs.count >= MissionCatalog.missions.count {
            unlockSpecimen("all_missions", title: "星穹のグランドクラウン")
        }

        changeCounter += 1
        objectWillChange.send()
    }
}
