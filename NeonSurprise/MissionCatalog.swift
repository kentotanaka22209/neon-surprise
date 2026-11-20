import SwiftUI
import Foundation

// MARK: - Normalized Blueprint Structures

struct NormalizedEmitter: Sendable {
    let position: CGPoint
    let launchVelocity: CGPoint
}

struct NormalizedString: Sendable {
    let start: CGPoint
    let end: CGPoint
    let kind: StringKind
}

struct NormalizedBloom: Sendable {
    let position: CGPoint
    let petals: Int
}

struct NormalizedGravity: Sendable {
    let position: CGPoint
    let swirl: CGFloat
}

// MARK: - Constellation Mission Definitions

struct ConstellationMission: Identifiable, Sendable {
    let id: Int
    let title: String
    let subtitle: String
    let hint: String
    let gravity: GravityPreset
    let maxStrings: Int
    let emitters: [NormalizedEmitter]
    let blooms: [NormalizedBloom]
    let prisms: [CGPoint]
    let gravityOrbs: [NormalizedGravity]
    let starterStrings: [NormalizedString]
}

// MARK: - Sandbox Preset Definitions

struct SandboxPreset: Identifiable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let iconName: String
    let gravity: GravityPreset
    let tempo: DropTempo
    let emitters: [NormalizedEmitter]
    let strings: [NormalizedString]
    let prisms: [CGPoint]
    let gravityOrbs: [NormalizedGravity]
    let blooms: [NormalizedBloom]
}

// MARK: - Collectible Neon Specimens

enum SpecimenGlyph: String, CaseIterable, Sendable {
    case lotus = "lotus"
    case harpWave = "harpWave"
    case diamondPrism = "diamondPrism"
    case vortexStar = "vortexStar"
    case starburst = "starburst"
    case infinityLoop = "infinityLoop"
    case sakuraCrown = "sakuraCrown"
    case cometOrb = "cometOrb"
    case twinRings = "twinRings"
    case zeroGravityAtom = "zeroGravityAtom"
    case feverSupernova = "feverSupernova"
    case constellationCrown = "constellationCrown"
}

struct NeonSpecimen: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let rarityLabel: String
    let unlockHint: String
    let poeticNote: String
    let glyph: SpecimenGlyph
    let primaryColor: RGBAColor
    let secondaryColor: RGBAColor
}

// MARK: - Static Catalogs

enum MissionCatalog {
    static let missions: [ConstellationMission] = [
        ConstellationMission(
            id: 1,
            title: "一等星のめざめ",
            subtitle: "STAGE 01",
            hint: "光の弦を追加して、3つの共鳴花すべてに光を届けよう",
            gravity: .normal,
            maxStrings: 6,
            emitters: [
                NormalizedEmitter(position: CGPoint(x: 0.28, y: 0.12), launchVelocity: CGPoint(x: 24, y: 60))
            ],
            blooms: [
                NormalizedBloom(position: CGPoint(x: 0.72, y: 0.34), petals: 6),
                NormalizedBloom(position: CGPoint(x: 0.56, y: 0.58), petals: 5),
                NormalizedBloom(position: CGPoint(x: 0.24, y: 0.74), petals: 6)
            ],
            prisms: [],
            gravityOrbs: [],
            starterStrings: [
                NormalizedString(
                    start: CGPoint(x: 0.14, y: 0.44),
                    end: CGPoint(x: 0.46, y: 0.52),
                    kind: .standard
                )
            ]
        ),
        ConstellationMission(
            id: 2,
            title: "双子のプリズム",
            subtitle: "STAGE 02",
            hint: "中央のプリズムに当てるとしずくが2つに分裂！左右の花を咲かせよう",
            gravity: .normal,
            maxStrings: 6,
            emitters: [
                NormalizedEmitter(position: CGPoint(x: 0.50, y: 0.11), launchVelocity: CGPoint(x: 0, y: 70))
            ],
            blooms: [
                NormalizedBloom(position: CGPoint(x: 0.18, y: 0.42), petals: 6),
                NormalizedBloom(position: CGPoint(x: 0.82, y: 0.42), petals: 6),
                NormalizedBloom(position: CGPoint(x: 0.24, y: 0.74), petals: 7),
                NormalizedBloom(position: CGPoint(x: 0.76, y: 0.74), petals: 7)
            ],
            prisms: [
                CGPoint(x: 0.50, y: 0.34)
            ],
            gravityOrbs: [],
            starterStrings: []
        ),
        ConstellationMission(
            id: 3,
            title: "三連ハイジャンプ",
            subtitle: "STAGE 03",
            hint: "「加速弦」に切り替えて、高い天井に浮かぶ花へ撃ち上げよう！",
            gravity: .normal,
            maxStrings: 6,
            emitters: [
                NormalizedEmitter(position: CGPoint(x: 0.22, y: 0.12), launchVelocity: CGPoint(x: 20, y: 65))
            ],
            blooms: [
                NormalizedBloom(position: CGPoint(x: 0.52, y: 0.18), petals: 5),
                NormalizedBloom(position: CGPoint(x: 0.80, y: 0.22), petals: 6),
                NormalizedBloom(position: CGPoint(x: 0.78, y: 0.56), petals: 7),
                NormalizedBloom(position: CGPoint(x: 0.42, y: 0.48), petals: 6)
            ],
            prisms: [
                CGPoint(x: 0.56, y: 0.36)
            ],
            gravityOrbs: [],
            starterStrings: [
                NormalizedString(
                    start: CGPoint(x: 0.10, y: 0.68),
                    end: CGPoint(x: 0.40, y: 0.73),
                    kind: .boost
                )
            ]
        ),
        ConstellationMission(
            id: 4,
            title: "星雲スリングショット",
            subtitle: "STAGE 04",
            hint: "中央の引力玉が光の軌道を曲げるよ。曲線を読んで弦を置こう",
            gravity: .moon,
            maxStrings: 6,
            emitters: [
                NormalizedEmitter(position: CGPoint(x: 0.18, y: 0.14), launchVelocity: CGPoint(x: 75, y: 35))
            ],
            blooms: [
                NormalizedBloom(position: CGPoint(x: 0.80, y: 0.26), petals: 6),
                NormalizedBloom(position: CGPoint(x: 0.82, y: 0.66), petals: 6),
                NormalizedBloom(position: CGPoint(x: 0.20, y: 0.68), petals: 8),
                NormalizedBloom(position: CGPoint(x: 0.50, y: 0.80), petals: 6)
            ],
            prisms: [],
            gravityOrbs: [
                NormalizedGravity(position: CGPoint(x: 0.50, y: 0.46), swirl: 1.0)
            ],
            starterStrings: []
        ),
        ConstellationMission(
            id: 5,
            title: "七色の光の滝",
            subtitle: "STAGE 05",
            hint: "上下2つのプリズムを通過させて光のシャワーを作ろう！",
            gravity: .normal,
            maxStrings: 6,
            emitters: [
                NormalizedEmitter(position: CGPoint(x: 0.50, y: 0.10), launchVelocity: CGPoint(x: 0, y: 65))
            ],
            blooms: [
                NormalizedBloom(position: CGPoint(x: 0.18, y: 0.30), petals: 5),
                NormalizedBloom(position: CGPoint(x: 0.82, y: 0.30), petals: 5),
                NormalizedBloom(position: CGPoint(x: 0.22, y: 0.58), petals: 6),
                NormalizedBloom(position: CGPoint(x: 0.78, y: 0.58), petals: 6),
                NormalizedBloom(position: CGPoint(x: 0.50, y: 0.78), petals: 8)
            ],
            prisms: [
                CGPoint(x: 0.50, y: 0.28),
                CGPoint(x: 0.50, y: 0.55)
            ],
            gravityOrbs: [],
            starterStrings: []
        ),
        ConstellationMission(
            id: 6,
            title: "万華鏡ゲート",
            subtitle: "STAGE 06",
            hint: "2つの発射口から降り注ぐ光を「虹の弦」で交差させよう",
            gravity: .normal,
            maxStrings: 6,
            emitters: [
                NormalizedEmitter(position: CGPoint(x: 0.24, y: 0.11), launchVelocity: CGPoint(x: 30, y: 55)),
                NormalizedEmitter(position: CGPoint(x: 0.76, y: 0.11), launchVelocity: CGPoint(x: -30, y: 55))
            ],
            blooms: [
                NormalizedBloom(position: CGPoint(x: 0.50, y: 0.26), petals: 8),
                NormalizedBloom(position: CGPoint(x: 0.16, y: 0.50), petals: 6),
                NormalizedBloom(position: CGPoint(x: 0.84, y: 0.50), petals: 6),
                NormalizedBloom(position: CGPoint(x: 0.30, y: 0.76), petals: 6),
                NormalizedBloom(position: CGPoint(x: 0.70, y: 0.76), petals: 6)
            ],
            prisms: [
                CGPoint(x: 0.50, y: 0.50)
            ],
            gravityOrbs: [],
            starterStrings: [
                NormalizedString(
                    start: CGPoint(x: 0.36, y: 0.65),
                    end: CGPoint(x: 0.64, y: 0.65),
                    kind: .prism
                )
            ]
        ),
        ConstellationMission(
            id: 7,
            title: "ふわふわ星くず網",
            subtitle: "STAGE 07",
            hint: "低重力ステージ！光の弦でクモの巣のように跳ね回らせよう",
            gravity: .moon,
            maxStrings: 7,
            emitters: [
                NormalizedEmitter(position: CGPoint(x: 0.50, y: 0.12), launchVelocity: CGPoint(x: 42, y: 40))
            ],
            blooms: [
                NormalizedBloom(position: CGPoint(x: 0.20, y: 0.22), petals: 6),
                NormalizedBloom(position: CGPoint(x: 0.80, y: 0.22), petals: 6),
                NormalizedBloom(position: CGPoint(x: 0.16, y: 0.56), petals: 7),
                NormalizedBloom(position: CGPoint(x: 0.84, y: 0.56), petals: 7),
                NormalizedBloom(position: CGPoint(x: 0.34, y: 0.80), petals: 5),
                NormalizedBloom(position: CGPoint(x: 0.66, y: 0.80), petals: 5)
            ],
            prisms: [
                CGPoint(x: 0.32, y: 0.42),
                CGPoint(x: 0.68, y: 0.42)
            ],
            gravityOrbs: [
                NormalizedGravity(position: CGPoint(x: 0.50, y: 0.58), swirl: -1.0)
            ],
            starterStrings: []
        ),
        ConstellationMission(
            id: 8,
            title: "ネオン大花火",
            subtitle: "FINAL STAGE",
            hint: "すべての技を総動員！6つの大輪を咲き誇らせよう",
            gravity: .normal,
            maxStrings: 7,
            emitters: [
                NormalizedEmitter(position: CGPoint(x: 0.30, y: 0.10), launchVelocity: CGPoint(x: 20, y: 70)),
                NormalizedEmitter(position: CGPoint(x: 0.70, y: 0.10), launchVelocity: CGPoint(x: -20, y: 70))
            ],
            blooms: [
                NormalizedBloom(position: CGPoint(x: 0.50, y: 0.20), petals: 8),
                NormalizedBloom(position: CGPoint(x: 0.16, y: 0.34), petals: 6),
                NormalizedBloom(position: CGPoint(x: 0.84, y: 0.34), petals: 6),
                NormalizedBloom(position: CGPoint(x: 0.18, y: 0.68), petals: 7),
                NormalizedBloom(position: CGPoint(x: 0.82, y: 0.68), petals: 7),
                NormalizedBloom(position: CGPoint(x: 0.50, y: 0.80), petals: 8)
            ],
            prisms: [
                CGPoint(x: 0.34, y: 0.44),
                CGPoint(x: 0.66, y: 0.44)
            ],
            gravityOrbs: [
                NormalizedGravity(position: CGPoint(x: 0.50, y: 0.54), swirl: 1.0)
            ],
            starterStrings: []
        )
    ]

    static let sandboxPresets: [SandboxPreset] = [
        SandboxPreset(
            id: "trampoline",
            title: "無限トランポリン",
            subtitle: "加速弦で永遠に跳ね続ける光のループ",
            iconName: "arrow.triangle.2.circlepath",
            gravity: .normal,
            tempo: .rhythmic,
            emitters: [
                NormalizedEmitter(position: CGPoint(x: 0.30, y: 0.12), launchVelocity: CGPoint(x: 45, y: 40))
            ],
            strings: [
                NormalizedString(start: CGPoint(x: 0.14, y: 0.68), end: CGPoint(x: 0.48, y: 0.76), kind: .boost),
                NormalizedString(start: CGPoint(x: 0.52, y: 0.76), end: CGPoint(x: 0.86, y: 0.68), kind: .boost),
                NormalizedString(start: CGPoint(x: 0.34, y: 0.34), end: CGPoint(x: 0.66, y: 0.34), kind: .prism)
            ],
            prisms: [
                CGPoint(x: 0.50, y: 0.52)
            ],
            gravityOrbs: [],
            blooms: [
                NormalizedBloom(position: CGPoint(x: 0.22, y: 0.42), petals: 6),
                NormalizedBloom(position: CGPoint(x: 0.78, y: 0.42), petals: 6)
            ]
        ),
        SandboxPreset(
            id: "rainbowWaterfall",
            title: "虹の滝",
            subtitle: "プリズム連鎖で光があふれ出す滝",
            iconName: "sparkles",
            gravity: .normal,
            tempo: .rhythmic,
            emitters: [
                NormalizedEmitter(position: CGPoint(x: 0.50, y: 0.10), launchVelocity: CGPoint(x: 0, y: 60))
            ],
            strings: [
                NormalizedString(start: CGPoint(x: 0.10, y: 0.46), end: CGPoint(x: 0.36, y: 0.56), kind: .prism),
                NormalizedString(start: CGPoint(x: 0.90, y: 0.46), end: CGPoint(x: 0.64, y: 0.56), kind: .prism),
                NormalizedString(start: CGPoint(x: 0.28, y: 0.80), end: CGPoint(x: 0.72, y: 0.80), kind: .boost)
            ],
            prisms: [
                CGPoint(x: 0.50, y: 0.28),
                CGPoint(x: 0.34, y: 0.48),
                CGPoint(x: 0.66, y: 0.48)
            ],
            gravityOrbs: [],
            blooms: [
                NormalizedBloom(position: CGPoint(x: 0.18, y: 0.68), petals: 7),
                NormalizedBloom(position: CGPoint(x: 0.82, y: 0.68), petals: 7),
                NormalizedBloom(position: CGPoint(x: 0.50, y: 0.66), petals: 8)
            ]
        ),
        SandboxPreset(
            id: "orbitalMusicBox",
            title: "無重力オルゴール",
            subtitle: "双子の引力玉を星が周回する幻想空間",
            iconName: "atom",
            gravity: .zeroG,
            tempo: .calm,
            emitters: [
                NormalizedEmitter(position: CGPoint(x: 0.20, y: 0.20), launchVelocity: CGPoint(x: 140, y: 55)),
                NormalizedEmitter(position: CGPoint(x: 0.80, y: 0.78), launchVelocity: CGPoint(x: -140, y: -55))
            ],
            strings: [
                NormalizedString(start: CGPoint(x: 0.14, y: 0.38), end: CGPoint(x: 0.14, y: 0.62), kind: .standard),
                NormalizedString(start: CGPoint(x: 0.86, y: 0.38), end: CGPoint(x: 0.86, y: 0.62), kind: .standard)
            ],
            prisms: [
                CGPoint(x: 0.50, y: 0.50)
            ],
            gravityOrbs: [
                NormalizedGravity(position: CGPoint(x: 0.36, y: 0.36), swirl: 1.0),
                NormalizedGravity(position: CGPoint(x: 0.64, y: 0.64), swirl: -1.0)
            ],
            blooms: [
                NormalizedBloom(position: CGPoint(x: 0.70, y: 0.28), petals: 6),
                NormalizedBloom(position: CGPoint(x: 0.30, y: 0.72), petals: 6)
            ]
        ),
        SandboxPreset(
            id: "kaleidoscope",
            title: "万華鏡ピンボール",
            subtitle: "ひし形の光の壁の中で弾け飛ぶ花火",
            iconName: "diamond.fill",
            gravity: .moon,
            tempo: .meteor,
            emitters: [
                NormalizedEmitter(position: CGPoint(x: 0.50, y: 0.14), launchVelocity: CGPoint(x: 35, y: 80))
            ],
            strings: [
                NormalizedString(start: CGPoint(x: 0.50, y: 0.84), end: CGPoint(x: 0.12, y: 0.54), kind: .boost),
                NormalizedString(start: CGPoint(x: 0.50, y: 0.84), end: CGPoint(x: 0.88, y: 0.54), kind: .boost),
                NormalizedString(start: CGPoint(x: 0.16, y: 0.36), end: CGPoint(x: 0.38, y: 0.22), kind: .prism),
                NormalizedString(start: CGPoint(x: 0.84, y: 0.36), end: CGPoint(x: 0.62, y: 0.22), kind: .prism)
            ],
            prisms: [
                CGPoint(x: 0.50, y: 0.44),
                CGPoint(x: 0.50, y: 0.62)
            ],
            gravityOrbs: [],
            blooms: [
                NormalizedBloom(position: CGPoint(x: 0.26, y: 0.50), petals: 6),
                NormalizedBloom(position: CGPoint(x: 0.74, y: 0.50), petals: 6),
                NormalizedBloom(position: CGPoint(x: 0.50, y: 0.28), petals: 8)
            ]
        )
    ]

    static let specimens: [NeonSpecimen] = [
        NeonSpecimen(
            id: "first_pluck",
            title: "初音のひとすじ",
            rarityLabel: "COMMON",
            unlockHint: "光の弦を1回はじく",
            poeticNote: "暗闇にはじめて張られた一本の光の糸。触れるたびに淡い余韻が星くずとなってほどけていく。",
            glyph: .harpWave,
            primaryColor: .neonCyan,
            secondaryColor: .neonViolet
        ),
        NeonSpecimen(
            id: "first_bloom",
            title: "共鳴のつぼみ",
            rarityLabel: "COMMON",
            unlockHint: "共鳴花を1回咲かせる",
            poeticNote: "しずくの鼓動を受け止めた瞬間、音もなく六枚の花びらがネオンの火花となって開く。",
            glyph: .lotus,
            primaryColor: .neonMagenta,
            secondaryColor: .neonGold
        ),
        NeonSpecimen(
            id: "prism_spark",
            title: "双子の分光晶",
            rarityLabel: "COMMON",
            unlockHint: "プリズムで1回分裂させる",
            poeticNote: "ひとつの光をふたつの未来へ分かつ透明な結晶。覗き込む角度で七色の記憶が揺らぐ。",
            glyph: .diamondPrism,
            primaryColor: RGBAColor(r: 0.4, g: 0.95, b: 1.0),
            secondaryColor: RGBAColor(r: 1.0, g: 0.55, b: 0.92)
        ),
        NeonSpecimen(
            id: "combo_five",
            title: "五連星の残光",
            rarityLabel: "RARE",
            unlockHint: "5コンボを達成する",
            poeticNote: "休む間もなく跳ね続けたしずくが紡ぐ五角形の軌跡。指先がなくても踊り続ける。",
            glyph: .starburst,
            primaryColor: .neonGold,
            secondaryColor: .neonMagenta
        ),
        NeonSpecimen(
            id: "combo_ten",
            title: "十重の無限環",
            rarityLabel: "EPIC",
            unlockHint: "10コンボを達成する",
            poeticNote: "光を10度重ねた者だけが見るメビウスの光輪。中心を突くと心地よく震える。",
            glyph: .infinityLoop,
            primaryColor: .neonLime,
            secondaryColor: .neonCyan
        ),
        NeonSpecimen(
            id: "pluck_hundred",
            title: "百弦の調律師",
            rarityLabel: "RARE",
            unlockHint: "弦を合計100回はじく",
            poeticNote: "百回の振動を記憶した音のいらない琴。指でつつくだけで静かな波紋が広がる。",
            glyph: .twinRings,
            primaryColor: RGBAColor(r: 0.58, g: 0.52, b: 1.0),
            secondaryColor: .neonCyan
        ),
        NeonSpecimen(
            id: "bloom_thirty",
            title: "夜桜ネオン冠",
            rarityLabel: "RARE",
            unlockHint: "共鳴花を合計30回咲かせる",
            poeticNote: "満開のネオン花びらが寄り集まった光の冠。春の夜風のようにやわらかく脈打つ。",
            glyph: .sakuraCrown,
            primaryColor: RGBAColor(r: 1.0, g: 0.52, b: 0.80),
            secondaryColor: RGBAColor(r: 1.0, g: 0.84, b: 0.44)
        ),
        NeonSpecimen(
            id: "prism_twenty",
            title: "七色スペクトル核",
            rarityLabel: "EPIC",
            unlockHint: "プリズムで合計20回分裂させる",
            poeticNote: "光の滝から生まれた高密度プリズム。触れれば触れるほど虹の粒子を散らす。",
            glyph: .vortexStar,
            primaryColor: RGBAColor(r: 0.25, g: 1.0, b: 0.84),
            secondaryColor: RGBAColor(r: 1.0, g: 0.35, b: 0.72)
        ),
        NeonSpecimen(
            id: "zero_gravity",
            title: "無重力の旅人",
            rarityLabel: "RARE",
            unlockHint: "光の庭園で「無重力」を試す",
            poeticNote: "重力から解き放たれたしずくの結晶。壁から壁へと永遠に軌道を描き続ける。",
            glyph: .zeroGravityAtom,
            primaryColor: RGBAColor(r: 0.36, g: 0.82, b: 1.0),
            secondaryColor: RGBAColor(r: 0.74, g: 0.50, b: 1.0)
        ),
        NeonSpecimen(
            id: "fever_master",
            title: "フィーバー超新星",
            rarityLabel: "EPIC",
            unlockHint: "エンドレスでFEVERを発動する",
            poeticNote: "連鎖のエネルギーが臨界を超えた瞬間に生まれる虹の超新星。見るだけで胸が弾む。",
            glyph: .feverSupernova,
            primaryColor: RGBAColor(r: 1.0, g: 0.56, b: 0.22),
            secondaryColor: RGBAColor(r: 1.0, g: 0.22, b: 0.72)
        ),
        NeonSpecimen(
            id: "mission_four",
            title: "彗星ランタン",
            rarityLabel: "EPIC",
            unlockHint: "星座ミッションを4つクリアする",
            poeticNote: "4つの星座をつないだ旅人の灯火。長い尾を引く彗星がガラス玉の中で眠っている。",
            glyph: .cometOrb,
            primaryColor: RGBAColor(r: 0.42, g: 0.96, b: 0.90),
            secondaryColor: .neonGold
        ),
        NeonSpecimen(
            id: "all_missions",
            title: "星穹のグランドクラウン",
            rarityLabel: "LEGEND",
            unlockHint: "全8つの星座ミッションをクリアする",
            poeticNote: "すべての星座を光で満たした証。ネオン光弦の宇宙で最もまばゆく輝く至宝。",
            glyph: .constellationCrown,
            primaryColor: .neonGold,
            secondaryColor: .neonCyan
        )
    ]
}
