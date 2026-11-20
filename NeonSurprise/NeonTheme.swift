import SwiftUI
import Foundation

// MARK: - Pure SwiftUI RGBA Color Helper

struct RGBAColor: Equatable, Hashable, Sendable {
    var r: Double
    var g: Double
    var b: Double
    var a: Double

    init(r: Double, g: Double, b: Double, a: Double = 1.0) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    var color: Color {
        Color(red: r, green: g, blue: b, opacity: a)
    }

    func withAlpha(_ alpha: Double) -> RGBAColor {
        RGBAColor(r: r, g: g, b: b, a: max(0.0, min(1.0, alpha)))
    }

    func lerped(to other: RGBAColor, t: Double) -> RGBAColor {
        let clamped = max(0.0, min(1.0, t))
        return RGBAColor(
            r: r + (other.r - r) * clamped,
            g: g + (other.g - g) * clamped,
            b: b + (other.b - b) * clamped,
            a: a + (other.a - a) * clamped
        )
    }

    static func rainbow(phase: Double) -> RGBAColor {
        let wrapped = phase.truncatingRemainder(dividingBy: 1.0)
        let hue = wrapped < 0 ? wrapped + 1.0 : wrapped
        let sector = hue * 6.0
        let i = Int(floor(sector)) % 6
        let f = sector - floor(sector)
        switch i {
        case 0: return RGBAColor(r: 1.0, g: 0.25 + 0.75 * f, b: 0.35)
        case 1: return RGBAColor(r: 1.0 - 0.75 * f, g: 1.0, b: 0.35)
        case 2: return RGBAColor(r: 0.25, g: 1.0, b: 0.35 + 0.65 * f)
        case 3: return RGBAColor(r: 0.25, g: 1.0 - 0.7 * f, b: 1.0)
        case 4: return RGBAColor(r: 0.25 + 0.75 * f, g: 0.3, b: 1.0)
        default: return RGBAColor(r: 1.0, g: 0.25, b: 1.0 - 0.65 * f)
        }
    }

    static let pureWhite = RGBAColor(r: 1.0, g: 1.0, b: 1.0)
    static let neonCyan = RGBAColor(r: 0.16, g: 0.94, b: 1.0)
    static let neonMagenta = RGBAColor(r: 1.0, g: 0.24, b: 0.78)
    static let neonGold = RGBAColor(r: 1.0, g: 0.84, b: 0.24)
    static let neonLime = RGBAColor(r: 0.45, g: 1.0, b: 0.56)
    static let neonViolet = RGBAColor(r: 0.68, g: 0.42, b: 1.0)
}

// MARK: - CGPoint Geometry Helpers

extension CGPoint {
    func adding(_ other: CGPoint) -> CGPoint {
        CGPoint(x: x + other.x, y: y + other.y)
    }

    func subtracting(_ other: CGPoint) -> CGPoint {
        CGPoint(x: x - other.x, y: y - other.y)
    }

    func scaled(by factor: CGFloat) -> CGPoint {
        CGPoint(x: x * factor, y: y * factor)
    }

    var magnitudeSquared: CGFloat {
        x * x + y * y
    }

    var magnitude: CGFloat {
        hypot(x, y)
    }

    func distance(to other: CGPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }

    func dot(_ other: CGPoint) -> CGFloat {
        x * other.x + y * other.y
    }

    func normalized() -> CGPoint {
        let len = magnitude
        guard len > 0.0001 else { return CGPoint(x: 0, y: -1) }
        return CGPoint(x: x / len, y: y / len)
    }

    func rotated(by radians: CGFloat) -> CGPoint {
        let c = cos(radians)
        let s = sin(radians)
        return CGPoint(x: x * c - y * s, y: x * s + y * c)
    }

    static func lerp(_ a: CGPoint, _ b: CGPoint, t: CGFloat) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }
}

// MARK: - Neon Themes

enum NeonTheme: String, CaseIterable, Identifiable, Hashable, Sendable {
    case cyberTokyo = "cyberTokyo"
    case yozakura = "yozakura"
    case deepFirefly = "deepFirefly"
    case summerHanabi = "summerHanabi"
    case auroraGlacier = "auroraGlacier"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cyberTokyo: return "サイバー東京"
        case .yozakura: return "夜桜ネオン"
        case .deepFirefly: return "深海ホタル"
        case .summerHanabi: return "夏祭り花火"
        case .auroraGlacier: return "オーロラ氷河"
        }
    }

    var iconName: String {
        switch self {
        case .cyberTokyo: return "sparkles"
        case .yozakura: return "camera.macro"
        case .deepFirefly: return "drop.fill"
        case .summerHanabi: return "flame.fill"
        case .auroraGlacier: return "snowflake"
        }
    }

    var backgroundTop: RGBAColor {
        switch self {
        case .cyberTokyo: return RGBAColor(r: 0.03, g: 0.03, b: 0.09)
        case .yozakura: return RGBAColor(r: 0.07, g: 0.02, b: 0.09)
        case .deepFirefly: return RGBAColor(r: 0.01, g: 0.05, b: 0.10)
        case .summerHanabi: return RGBAColor(r: 0.06, g: 0.03, b: 0.08)
        case .auroraGlacier: return RGBAColor(r: 0.02, g: 0.06, b: 0.11)
        }
    }

    var backgroundBottom: RGBAColor {
        switch self {
        case .cyberTokyo: return RGBAColor(r: 0.09, g: 0.04, b: 0.18)
        case .yozakura: return RGBAColor(r: 0.16, g: 0.05, b: 0.16)
        case .deepFirefly: return RGBAColor(r: 0.02, g: 0.13, b: 0.17)
        case .summerHanabi: return RGBAColor(r: 0.14, g: 0.05, b: 0.11)
        case .auroraGlacier: return RGBAColor(r: 0.06, g: 0.13, b: 0.21)
        }
    }

    var primary: RGBAColor {
        switch self {
        case .cyberTokyo: return RGBAColor(r: 0.16, g: 0.94, b: 1.0)
        case .yozakura: return RGBAColor(r: 1.0, g: 0.48, b: 0.78)
        case .deepFirefly: return RGBAColor(r: 0.20, g: 1.0, b: 0.80)
        case .summerHanabi: return RGBAColor(r: 1.0, g: 0.44, b: 0.26)
        case .auroraGlacier: return RGBAColor(r: 0.42, g: 0.96, b: 0.90)
        }
    }

    var secondary: RGBAColor {
        switch self {
        case .cyberTokyo: return RGBAColor(r: 1.0, g: 0.24, b: 0.78)
        case .yozakura: return RGBAColor(r: 1.0, g: 0.82, b: 0.36)
        case .deepFirefly: return RGBAColor(r: 0.36, g: 0.68, b: 1.0)
        case .summerHanabi: return RGBAColor(r: 0.22, g: 0.92, b: 0.94)
        case .auroraGlacier: return RGBAColor(r: 0.66, g: 0.56, b: 1.0)
        }
    }

    var accent: RGBAColor {
        switch self {
        case .cyberTokyo: return RGBAColor(r: 0.52, g: 1.0, b: 0.48)
        case .yozakura: return RGBAColor(r: 0.72, g: 0.44, b: 1.0)
        case .deepFirefly: return RGBAColor(r: 0.80, g: 1.0, b: 0.34)
        case .summerHanabi: return RGBAColor(r: 1.0, g: 0.86, b: 0.28)
        case .auroraGlacier: return RGBAColor(r: 0.96, g: 0.56, b: 0.94)
        }
    }

    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundTop.color, backgroundBottom.color],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func colorForStringKind(_ kind: StringKind) -> RGBAColor {
        switch kind {
        case .standard: return primary
        case .boost: return secondary
        case .prism: return accent
        }
    }
}

// MARK: - String Types

enum StringKind: String, CaseIterable, Identifiable, Hashable, Sendable {
    case standard = "standard"
    case boost = "boost"
    case prism = "prism"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .standard: return "共鳴弦"
        case .boost: return "加速弦"
        case .prism: return "虹の弦"
        }
    }

    var shortHint: String {
        switch self {
        case .standard: return "軽やかに反発"
        case .boost: return "高くスーパー加速"
        case .prism: return "しずくを虹色強化"
        }
    }

    var iconName: String {
        switch self {
        case .standard: return "waveform.path"
        case .boost: return "bolt.fill"
        case .prism: return "rainbow"
        }
    }
}

// MARK: - Drop Skins

enum DropSkin: String, CaseIterable, Identifiable, Hashable, Sendable {
    case starlight = "starlight"
    case diamond = "diamond"
    case sakura = "sakura"
    case comet = "comet"
    case heartNova = "heartNova"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .starlight: return "星のしずく"
        case .diamond: return "ダイヤ結晶"
        case .sakura: return "ネオン桜びら"
        case .comet: return "彗星スパーク"
        case .heartNova: return "ハート花火"
        }
    }

    var unlockDescription: String {
        switch self {
        case .starlight: return "初期装備"
        case .diamond: return "弦を15回はじく"
        case .sakura: return "共鳴花を5回咲かせる"
        case .comet: return "5コンボを達成する"
        case .heartNova: return "星座ミッションを3つクリア"
        }
    }

    var iconName: String {
        switch self {
        case .starlight: return "sparkle"
        case .diamond: return "diamond.fill"
        case .sakura: return "camera.macro"
        case .comet: return "star.fill"
        case .heartNova: return "heart.fill"
        }
    }
}

// MARK: - Sandbox Controls

enum SandboxTool: String, CaseIterable, Identifiable, Hashable, Sendable {
    case drawString = "drawString"
    case placePrism = "placePrism"
    case placeGravity = "placeGravity"
    case placeBloom = "placeBloom"
    case paintDrops = "paintDrops"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .drawString: return "光の弦"
        case .placePrism: return "プリズム"
        case .placeGravity: return "引力玉"
        case .placeBloom: return "花火花"
        case .paintDrops: return "しずく"
        }
    }

    var iconName: String {
        switch self {
        case .drawString: return "line.diagonal"
        case .placePrism: return "rhombus.fill"
        case .placeGravity: return "hurricane"
        case .placeBloom: return "sun.max.fill"
        case .paintDrops: return "wand.and.stars"
        }
    }
}

enum GravityPreset: String, CaseIterable, Identifiable, Hashable, Sendable {
    case normal = "normal"
    case moon = "moon"
    case zeroG = "zeroG"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .normal: return "通常重力"
        case .moon: return "ふわふわ"
        case .zeroG: return "無重力"
        }
    }

    var acceleration: CGFloat {
        switch self {
        case .normal: return 390.0
        case .moon: return 145.0
        case .zeroG: return 0.0
        }
    }

    var iconName: String {
        switch self {
        case .normal: return "arrow.down.circle"
        case .moon: return "moon.stars"
        case .zeroG: return "atom"
        }
    }
}

enum DropTempo: String, CaseIterable, Identifiable, Hashable, Sendable {
    case calm = "calm"
    case rhythmic = "rhythmic"
    case meteor = "meteor"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .calm: return "ゆったり"
        case .rhythmic: return "リズミカル"
        case .meteor: return "流星群"
        }
    }

    var spawnInterval: Double {
        switch self {
        case .calm: return 1.25
        case .rhythmic: return 0.68
        case .meteor: return 0.34
        }
    }
}
