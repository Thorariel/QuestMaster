import SwiftUI

// MARK: - App Theme Color System
extension Color {
    static let themeBG = Color(hex: 0xF2F4F8)
    static let themeCard = Color.white
    static let themePrimary = Color(hex: 0x5B8DE4)
    static let themePrimaryLight = Color(hex: 0xE8F0FE)
    static let themePrimaryDark = Color(hex: 0x3D6DB5)
    static let themeSecondary = Color(hex: 0x6BC5A0)
    static let themeSecondaryLight = Color(hex: 0xE3F5ED)
    static let themeGold = Color(hex: 0xF0B849)
    static let themeGoldLight = Color(hex: 0xFEF3D6)
    static let themeGoldDark = Color(hex: 0xD49A2A)
    static let themeCoral = Color(hex: 0xFF7E67)
    static let themeCoralLight = Color(hex: 0xFFE8E0)
    static let themePurple = Color(hex: 0xA78BDB)
    static let themePurpleLight = Color(hex: 0xEDE7F6)
    static let themeText = Color(hex: 0x1E2028)
    static let themeTextSecondary = Color(hex: 0x5C5F6E)
    static let themeTextMuted = Color(hex: 0xA0A3B0)
    static let themeBorder = Color(hex: 0xEAECF0)

    init(hex: UInt) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}

// MARK: - ShapeStyle Support (allows .themePrimary etc. in ShapeStyle contexts)
extension ShapeStyle where Self == Color {
    static var themeCard: Color { .white }

    static var themeBG: Color { .themeBG }
    static var themePrimary: Color { .themePrimary }
    static var themePrimaryLight: Color { .themePrimaryLight }
    static var themePrimaryDark: Color { .themePrimaryDark }
    static var themeSecondary: Color { .themeSecondary }
    static var themeSecondaryLight: Color { .themeSecondaryLight }
    static var themeGold: Color { .themeGold }
    static var themeGoldLight: Color { .themeGoldLight }
    static var themeGoldDark: Color { .themeGoldDark }
    static var themeCoral: Color { .themeCoral }
    static var themeCoralLight: Color { .themeCoralLight }
    static var themePurple: Color { .themePurple }
    static var themePurpleLight: Color { .themePurpleLight }
    static var themeText: Color { .themeText }
    static var themeTextSecondary: Color { .themeTextSecondary }
    static var themeTextMuted: Color { .themeTextMuted }
    static var themeBorder: Color { .themeBorder }
}

// MARK: - TaskCategory
enum TaskCategory: String, CaseIterable, Codable {
    case main = "main"
    case side = "side"
    case adventure = "adventure"
    case daily = "daily"
    static let ordered: [TaskCategory] = [.main, .side, .adventure, .daily]

    var emoji: String {
        switch self {
        case .main: return "⚔️"
        case .side: return "📜"
        case .adventure: return "🌈"
        case .daily: return "🔄"
        }
    }

    var label: String {
        switch self {
        case .main: return "主线"
        case .side: return "支线"
        case .adventure: return "奇遇"
        case .daily: return "日常"
        }
    }

    var color: Color {
        switch self {
        case .main: return .themePrimary
        case .side: return .themeSecondary
        case .adventure: return .themePurple
        case .daily: return .themeGold
        }
    }

    var lightColor: Color {
        switch self {
        case .main: return .themePrimaryLight
        case .side: return .themeSecondaryLight
        case .adventure: return .themePurpleLight
        case .daily: return .themeGoldLight
        }
    }

    /// 该类别任务可选的积分范围
    var xpRange: ClosedRange<Double> {
        switch self {
        case .main: return 10...100
        case .side, .adventure: return 1...25
        case .daily: return 1...10
        }
    }

    /// 积分滑块步进
    var xpStep: Double {
        switch self {
        case .main: return 5
        case .side, .adventure: return 1
        case .daily: return 1
        }
    }

    /// 该类别默认积分
    var defaultXP: Int {
        switch self {
        case .main: return 50
        case .side, .adventure: return 10
        case .daily: return 5
        }
    }
}

// MARK: - Level System
let levelTitles: [(level: Int, title: String, subtitle: String)] = [
    (1, "初入江湖", "初出茅庐的少侠"),
    (2, "小有名气", "开始展露头角"),
    (3, "江湖新秀", "已非吴下阿蒙"),
    (4, "独当一面", "可独当一面"),
    (5, "声名鹊起", "名动一方"),
    (6, "武林高手", "武艺精湛"),
    (7, "一代宗师", "开宗立派"),
    (8, "武林盟主", "号令天下"),
    (9, "天下无双", "独孤求败"),
    (10, "飞升", "破碎虚空，证道飞升"),
]

func xpForLevel(_ level: Int) -> Int {
    return level * 100 + (level - 1) * 50
}

// MARK: - Badge System
struct Badge: Identifiable {
    let id: String
    let icon: String
    let name: String
    let check: (AppStateStore) -> Bool

    static let all: [Badge] = [
        Badge(id: "first", icon: "🎯", name: "初试锋芒", check: { $0.totalCompleted >= 1 }),
        Badge(id: "ten", icon: "⚡", name: "小试牛刀", check: { $0.totalCompleted >= 10 }),
        Badge(id: "fifty", icon: "🔥", name: "炉火纯青", check: { $0.totalCompleted >= 50 }),
        Badge(id: "hundred", icon: "💎", name: "百战成神", check: { $0.totalCompleted >= 100 }),
        Badge(id: "level3", icon: "🌟", name: "江湖新秀", check: { $0.level >= 3 }),
        Badge(id: "level5", icon: "👑", name: "声名鹊起", check: { $0.level >= 5 }),
        Badge(id: "level8", icon: "🏆", name: "武林盟主", check: { $0.level >= 8 }),
        Badge(id: "streak3", icon: "📅", name: "三日不违", check: { $0.bestStreak >= 3 }),
        Badge(id: "streak7", icon: "📆", name: "一周之约", check: { $0.bestStreak >= 7 }),
        Badge(id: "streak30", icon: "🗓️", name: "月满江湖", check: { $0.bestStreak >= 30 }),
    ]
}

// MARK: - App State Store
struct AppStateStore: Codable {
    var xp: Int = 0
    var level: Int = 1
    var totalCompleted: Int = 0
    var bestStreak: Int = 0
    var currentStreak: Int = 0
    var todayCompleted: Int = 0
    var lastActiveDate: String = ""
    var history: [HistoryEntry] = []
    var focusQuestID: String? = nil
    var trackedDailyIDs: [String] = []
    var collapsedCategories: [String] = []

    static let defaultsKey = "com.questmaster.appstate"

    static func load() -> AppStateStore {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let state = try? JSONDecoder().decode(AppStateStore.self, from: data)
        else { return AppStateStore() }
        return state
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }

    mutating func addXP(_ amount: Int) {
        xp += amount
        totalCompleted += 1
        todayCompleted += 1
        let needed = xpForLevel(level)
        while xp >= needed && level < 10 {
            xp -= needed
            level += 1
        }
    }
}

struct HistoryEntry: Codable, Identifiable {
    let id: String
    let questID: String
    let title: String
    let xp: Int
    let cat: String
    let completedAt: Date
}

// MARK: - Style Helpers
extension View {
    func cardShadow() -> some View {
        self.shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

struct AppRadius {
    static let `default`: CGFloat = 14
    static let small: CGFloat = 10
    static let extraSmall: CGFloat = 8
}
