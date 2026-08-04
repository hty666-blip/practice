import SwiftUI
import PhotosUI
import UserNotifications
import HealthKit
import Security
import Charts
import UIKit

@main
struct GymCoachApp: App {
    @StateObject private var store = FitnessStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}

// MARK: - Models

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast = "早餐"
    case lunch = "午餐"
    case dinner = "晚餐"
    case snack = "加餐"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "fork.knife"
        case .dinner: return "moon.stars.fill"
        case .snack: return "takeoutbag.and.cup.and.straw.fill"
        }
    }
}

enum MealEstimateSource: String, Codable {
    case local
    case ai
    case manual

    var label: String {
        switch self {
        case .local: return "本地估算"
        case .ai: return "AI 估算"
        case .manual: return "手动填写"
        }
    }
}

struct NutritionEstimate: Codable, Equatable {
    var calories: Int
    var protein: Int
    var carbs: Int
    var fat: Int
    var confidence: Double
    var note: String

    static let empty = NutritionEstimate(calories: 0, protein: 0, carbs: 0, fat: 0, confidence: 0, note: "")

    func adding(_ other: NutritionEstimate) -> NutritionEstimate {
        NutritionEstimate(
            calories: calories + other.calories,
            protein: protein + other.protein,
            carbs: carbs + other.carbs,
            fat: fat + other.fat,
            confidence: 0,
            note: ""
        )
    }
}

struct MealLog: Codable, Identifiable {
    var id = UUID()
    var date = Date()
    var type: MealType
    var description: String
    var nutrition: NutritionEstimate
    var imageData: Data?
    var source: MealEstimateSource
}

struct WeightEntry: Codable, Identifiable {
    var id = UUID()
    var date = Date()
    var kilograms: Double
    var waistCentimeters: Double?
}

struct DailyCheckIn: Codable, Identifiable {
    var id = UUID()
    var date = Date()
    var waterGlasses = 0
    var sleepHours: Double?
    var steps: Int?
}

enum BiologicalSex: String, Codable, CaseIterable, Identifiable {
    case male = "男性"
    case female = "女性"
    var id: String { rawValue }
}

struct FitnessProfile: Codable {
    var heightCentimeters = 185.0
    var age = 23
    var sex: BiologicalSex = .male
    var startingWeight = 100.0
    var currentWeightGoal = 75.0
    var dailyCaloriesGoal = 2200
    var dailyProteinGoal = 150
    var dailyStepsGoal = 8000
    var dailyWaterGoal = 8
}

struct AIConfiguration: Codable {
    var endpoint = ""
    var model = ""
    var useImageAnalysis = true
    var customInstruction = ""
}

struct ReminderItem: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var body: String
    var hour: Int
    var minute: Int
    var enabled: Bool

    var time: Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }

    mutating func setTime(_ date: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        hour = components.hour ?? hour
        minute = components.minute ?? minute
    }

    static let defaults = [
        ReminderItem(title: "晨起称重", body: "上完厕所、进食饮水前记录体重，看趋势而不是单日波动。", hour: 7, minute: 30, enabled: true),
        ReminderItem(title: "午餐选择", body: "先选一份蛋白质和两份蔬菜，米饭半份起。", hour: 10, minute: 0, enabled: true),
        ReminderItem(title: "下班训练", body: "先到健身房，完成最低训练量也算赢。", hour: 17, minute: 50, enabled: true),
        ReminderItem(title: "晚间复盘", body: "补记晚餐、饮水和今天的完成情况。", hour: 21, minute: 30, enabled: true)
    ]
}

struct Exercise: Codable, Identifiable {
    var id: String { name }
    var name: String
    var target: String
    var cue: String
}

struct WorkoutPlan: Codable, Identifiable {
    var id: String
    var weekday: Int
    var title: String
    var subtitle: String
    var exercises: [Exercise]
    var cardio: String?

    static let weekly: [WorkoutPlan] = [
        WorkoutPlan(id: "sun", weekday: 1, title: "主动恢复", subtitle: "走路、拉伸或完全休息。", exercises: [], cardio: "轻松走路 30–40 分钟（可选）"),
        WorkoutPlan(id: "mon", weekday: 2, title: "全身力量 A", subtitle: "下肢、推、拉和核心。", exercises: [
            Exercise(name: "腿举", target: "3 组 × 8–12 次", cue: "腰背贴稳靠垫，膝盖跟脚尖同向。"),
            Exercise(name: "坐姿推胸", target: "3 组 × 8–12 次", cue: "肩胛轻微后收，下放时别耸肩。"),
            Exercise(name: "高位下拉", target: "3 组 × 8–12 次", cue: "先沉肩，再把肘拉向身体两侧。"),
            Exercise(name: "坐姿腿弯举", target: "3 组 × 10–15 次", cue: "全程控制，不借惯性甩。"),
            Exercise(name: "坐姿划船", target: "3 组 × 10–12 次", cue: "胸口微抬，肘向后，不含胸耸肩。"),
            Exercise(name: "反向蝴蝶机", target: "2 组 × 12–15 次", cue: "轻重量，感受后肩和上背。"),
            Exercise(name: "平板支撑", target: "3 组 × 20–40 秒", cue: "收肋骨、夹臀，不塌腰。")
        ], cardio: "训练后坡走 15 分钟"),
        WorkoutPlan(id: "tue", weekday: 3, title: "有氧＋体态", subtitle: "提高活动量，改善前倾与圆肩。", exercises: [
            Exercise(name: "下巴微收", target: "2 组 × 10 次", cue: "像把后脑勺轻轻向后推，不低头。"),
            Exercise(name: "靠墙滑手", target: "2 组 × 10 次", cue: "肋骨别外翻，动作慢。"),
            Exercise(name: "臀桥", target: "2 组 × 15 次", cue: "骨盆后倾，顶端夹臀 1 秒。"),
            Exercise(name: "胸肌拉伸", target: "每侧 2 组 × 30 秒", cue: "只拉到轻微紧张，不疼。")
        ], cardio: "跑步机坡走 30–40 分钟，可说完整句子为宜"),
        WorkoutPlan(id: "wed", weekday: 4, title: "全身力量 B", subtitle: "臀腿、上胸、背部与抗旋转。", exercises: [
            Exercise(name: "哈克深蹲或史密斯深蹲", target: "3 组 × 8–12 次", cue: "核心收紧，膝盖顺着脚尖。"),
            Exercise(name: "臀推机", target: "3 组 × 10–12 次", cue: "顶端不仰腰，感受臀部发力。"),
            Exercise(name: "上斜推胸机", target: "3 组 × 8–12 次", cue: "肩胛稳定，手肘不过度打开。"),
            Exercise(name: "窄握高位下拉", target: "3 组 × 8–12 次", cue: "避免借腰后仰。"),
            Exercise(name: "胸托划船", target: "3 组 × 10–12 次", cue: "收肩胛后再拉肘。"),
            Exercise(name: "绳索面拉", target: "2 组 × 12–15 次", cue: "拉向眉眼高度，手肘打开。"),
            Exercise(name: "Pallof 抗旋转推", target: "每侧 2 组 × 12 次", cue: "身体不跟着绳索转。")
        ], cardio: "训练后坡走 15 分钟"),
        WorkoutPlan(id: "thu", weekday: 5, title: "有氧＋体态", subtitle: "巩固日常消耗和姿态习惯。", exercises: [
            Exercise(name: "靠墙滑手", target: "2 组 × 10 次", cue: "慢速、肋骨收住。"),
            Exercise(name: "髋屈肌拉伸", target: "每侧 2 组 × 30 秒", cue: "骨盆微微后倾。"),
            Exercise(name: "臀桥", target: "2 组 × 15 次", cue: "顶端夹臀，不顶腰。"),
            Exercise(name: "平板支撑", target: "3 组 × 20–40 秒", cue: "保持呼吸，不憋气。")
        ], cardio: "跑步机坡走 30–40 分钟"),
        WorkoutPlan(id: "fri", weekday: 6, title: "全身力量 A", subtitle: "复习动作，优先保证动作质量。", exercises: [
            Exercise(name: "腿举", target: "3 组 × 8–12 次", cue: "控制下放，膝盖稳定。"),
            Exercise(name: "坐姿推胸", target: "3 组 × 8–12 次", cue: "肩膀远离耳朵。"),
            Exercise(name: "高位下拉", target: "3 组 × 8–12 次", cue: "肘向下、胸口自然抬起。"),
            Exercise(name: "坐姿腿弯举", target: "3 组 × 10–15 次", cue: "顶端停半秒。"),
            Exercise(name: "坐姿划船", target: "3 组 × 10–12 次", cue: "不耸肩，不借力后仰。"),
            Exercise(name: "反向蝴蝶机", target: "2 组 × 12–15 次", cue: "后肩发力，不甩手。"),
            Exercise(name: "平板支撑", target: "3 组 × 20–40 秒", cue: "腹部持续收紧。")
        ], cardio: "训练后坡走 15 分钟"),
        WorkoutPlan(id: "sat", weekday: 7, title: "主动恢复", subtitle: "不补偿性训练，轻松活动即可。", exercises: [], cardio: "户外走路 60 分钟（可选）")
    ]
}

struct WorkoutExerciseLog: Codable, Identifiable {
    var id = UUID()
    var exerciseName: String
    var target: String
    var sets: Int
    var loadKilograms: Double?
    var reps: Int?
    var completed: Bool
}

struct WorkoutSession: Codable, Identifiable {
    var id = UUID()
    var date = Date()
    var planID: String
    var planTitle: String
    var exercises: [WorkoutExerciseLog]
    var cardioMinutes: Int
    var perceivedEffort: Int
    var note: String
    var durationMinutes: Int
}

struct ChatMessage: Codable, Identifiable {
    var id = UUID()
    var date = Date()
    var isUser: Bool
    var content: String
}

// MARK: - Local storage

@MainActor
final class FitnessStore: ObservableObject {
    @Published private(set) var meals: [MealLog]
    @Published private(set) var weights: [WeightEntry]
    @Published private(set) var checkIns: [DailyCheckIn]
    @Published private(set) var sessions: [WorkoutSession]
    @Published private(set) var chatMessages: [ChatMessage]
    @Published var profile: FitnessProfile { didSet { save(profile, key: Keys.profile) } }
    @Published var aiConfiguration: AIConfiguration { didSet { save(aiConfiguration, key: Keys.aiConfiguration) } }
    @Published var reminders: [ReminderItem] { didSet { save(reminders, key: Keys.reminders) } }

    private enum Keys {
        static let meals = "gymcoach.meals.v2"
        static let weights = "gymcoach.weights.v2"
        static let checkIns = "gymcoach.checkins.v2"
        static let sessions = "gymcoach.sessions.v2"
        static let chatMessages = "gymcoach.chat.v2"
        static let profile = "gymcoach.profile.v2"
        static let aiConfiguration = "gymcoach.ai.v2"
        static let reminders = "gymcoach.reminders.v2"
    }

    init() {
        meals = Self.load([MealLog].self, key: Keys.meals) ?? []
        weights = Self.load([WeightEntry].self, key: Keys.weights) ?? []
        checkIns = Self.load([DailyCheckIn].self, key: Keys.checkIns) ?? []
        sessions = Self.load([WorkoutSession].self, key: Keys.sessions) ?? []
        chatMessages = Self.load([ChatMessage].self, key: Keys.chatMessages) ?? []
        profile = Self.load(FitnessProfile.self, key: Keys.profile) ?? FitnessProfile()
        aiConfiguration = Self.load(AIConfiguration.self, key: Keys.aiConfiguration) ?? AIConfiguration()
        reminders = Self.load([ReminderItem].self, key: Keys.reminders) ?? ReminderItem.defaults
    }

    var todayPlan: WorkoutPlan {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return WorkoutPlan.weekly.first(where: { $0.weekday == weekday }) ?? WorkoutPlan.weekly[0]
    }

    var todayMeals: [MealLog] {
        meals.filter { Calendar.current.isDateInToday($0.date) }
    }

    var todayNutrition: NutritionEstimate {
        todayMeals.reduce(.empty) { $0.adding($1.nutrition) }
    }

    var currentWeight: Double? {
        weights.max(by: { $0.date < $1.date })?.kilograms
    }

    var latestWaist: Double? {
        weights.sorted { $0.date > $1.date }.compactMap(\.waistCentimeters).first
    }

    var sevenDayAverage: Double? {
        let recent = weights.sorted { $0.date > $1.date }.prefix(7)
        guard !recent.isEmpty else { return nil }
        return recent.map(\.kilograms).reduce(0, +) / Double(recent.count)
    }

    var goalProgress: Double {
        guard let currentWeight, profile.startingWeight > profile.currentWeightGoal else { return 0 }
        let progress = (profile.startingWeight - currentWeight) / (profile.startingWeight - profile.currentWeightGoal)
        return min(max(progress, 0), 1)
    }

    var weeklyTrainingCount: Int {
        sessions.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }.count
    }

    var todayCheckIn: DailyCheckIn {
        checkIns.first(where: { Calendar.current.isDateInToday($0.date) }) ?? DailyCheckIn()
    }

    var hasAIKey: Bool { KeychainStore.read(account: "ai-api-key") != nil }
    var canUseAI: Bool {
        !aiConfiguration.endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !aiConfiguration.model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && hasAIKey
    }

    var aiKey: String? { KeychainStore.read(account: "ai-api-key") }

    func meal(for type: MealType, on date: Date = Date()) -> MealLog? {
        meals.filter { Calendar.current.isDate($0.date, inSameDayAs: date) && $0.type == type }
            .max(by: { $0.date < $1.date })
    }

    func upsertMeal(_ meal: MealLog) {
        meals.removeAll { Calendar.current.isDate($0.date, inSameDayAs: meal.date) && $0.type == meal.type }
        meals.append(meal)
        meals.sort { $0.date > $1.date }
        save(meals, key: Keys.meals)
    }

    func deleteMeal(_ meal: MealLog) {
        meals.removeAll { $0.id == meal.id }
        save(meals, key: Keys.meals)
    }

    func addWeight(kilograms: Double, waist: Double?, date: Date = Date()) {
        weights.removeAll { Calendar.current.isDate($0.date, inSameDayAs: date) }
        weights.append(WeightEntry(date: date, kilograms: kilograms, waistCentimeters: waist))
        weights.sort { $0.date > $1.date }
        save(weights, key: Keys.weights)
    }

    func updateTodayCheckIn(water: Int, sleepHours: Double?, steps: Int?) {
        let today = Date()
        if let index = checkIns.firstIndex(where: { Calendar.current.isDateInToday($0.date) }) {
            checkIns[index].waterGlasses = water
            checkIns[index].sleepHours = sleepHours
            if let steps { checkIns[index].steps = steps }
        } else {
            checkIns.append(DailyCheckIn(date: today, waterGlasses: water, sleepHours: sleepHours, steps: steps))
        }
        save(checkIns, key: Keys.checkIns)
    }

    func addSession(_ session: WorkoutSession) {
        sessions.append(session)
        sessions.sort { $0.date > $1.date }
        save(sessions, key: Keys.sessions)
    }

    func saveAI(configuration: AIConfiguration, apiKey: String) {
        aiConfiguration = configuration
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedKey.isEmpty {
            KeychainStore.save(trimmedKey, account: "ai-api-key")
        }
    }

    func clearAIKey() {
        KeychainStore.delete(account: "ai-api-key")
        objectWillChange.send()
    }

    func appendChat(isUser: Bool, content: String) {
        chatMessages.append(ChatMessage(isUser: isUser, content: content))
        chatMessages = Array(chatMessages.suffix(60))
        save(chatMessages, key: Keys.chatMessages)
    }

    func clearChat() {
        chatMessages = []
        save(chatMessages, key: Keys.chatMessages)
    }

    var coachContext: String {
        let nutrition = todayNutrition
        let weightText = currentWeight.map { String(format: "%.1f kg", $0) } ?? "今日未记录"
        return "用户资料：23 岁男性，身高 \(Int(profile.heightCentimeters))cm，起始体重 \(String(format: "%.1f", profile.startingWeight))kg，目标 \(String(format: "%.1f", profile.currentWeightGoal))kg。当前体重：\(weightText)。今日已记录：\(nutrition.calories) kcal，蛋白质 \(nutrition.protein)g，碳水 \(nutrition.carbs)g，脂肪 \(nutrition.fat)g。今日训练：\(todayPlan.title)。每日报告目标：\(profile.dailyCaloriesGoal) kcal、蛋白质 \(profile.dailyProteinGoal)g、步数 \(profile.dailyStepsGoal)。"
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

enum KeychainStore {
    private static let service = "com.hty666.gymcoach"

    static func save(_ value: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var item = query
        item[kSecValueData as String] = Data(value.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(item as CFDictionary, nil)
    }

    static func read(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Nutrition estimation

enum FoodEstimator {
    private struct FoodRule {
        let term: String
        let label: String
        let nutrition: NutritionEstimate
    }

    private static let rules: [FoodRule] = [
        FoodRule(term: "无糖豆浆", label: "无糖豆浆（约 300ml）", nutrition: NutritionEstimate(calories: 95, protein: 9, carbs: 6, fat: 4, confidence: 0, note: "")),
        FoodRule(term: "煮鸡蛋", label: "煮鸡蛋", nutrition: NutritionEstimate(calories: 70, protein: 6, carbs: 0, fat: 5, confidence: 0, note: "")),
        FoodRule(term: "鸡蛋", label: "鸡蛋", nutrition: NutritionEstimate(calories: 70, protein: 6, carbs: 0, fat: 5, confidence: 0, note: "")),
        FoodRule(term: "八宝粥", label: "八宝粥（约 1 罐）", nutrition: NutritionEstimate(calories: 250, protein: 4, carbs: 52, fat: 2, confidence: 0, note: "")),
        FoodRule(term: "全麦面包", label: "全麦面包（约 2 片）", nutrition: NutritionEstimate(calories: 160, protein: 6, carbs: 28, fat: 3, confidence: 0, note: "")),
        FoodRule(term: "面包", label: "面包（约 2 片）", nutrition: NutritionEstimate(calories: 190, protein: 6, carbs: 34, fat: 4, confidence: 0, note: "")),
        FoodRule(term: "豆浆", label: "豆浆（约 300ml）", nutrition: NutritionEstimate(calories: 150, protein: 8, carbs: 20, fat: 5, confidence: 0, note: "")),
        FoodRule(term: "牛奶", label: "牛奶（约 300ml）", nutrition: NutritionEstimate(calories: 150, protein: 9, carbs: 14, fat: 6, confidence: 0, note: "")),
        FoodRule(term: "香蕉", label: "香蕉", nutrition: NutritionEstimate(calories: 105, protein: 1, carbs: 27, fat: 0, confidence: 0, note: "")),
        FoodRule(term: "苹果", label: "苹果", nutrition: NutritionEstimate(calories: 95, protein: 1, carbs: 25, fat: 0, confidence: 0, note: "")),
        FoodRule(term: "米饭", label: "米饭（约 1 小碗）", nutrition: NutritionEstimate(calories: 230, protein: 5, carbs: 52, fat: 0, confidence: 0, note: "")),
        FoodRule(term: "鸡胸", label: "鸡胸肉（约 100g）", nutrition: NutritionEstimate(calories: 165, protein: 31, carbs: 0, fat: 4, confidence: 0, note: "")),
        FoodRule(term: "炒鸡", label: "炒鸡（约 1 掌心）", nutrition: NutritionEstimate(calories: 240, protein: 25, carbs: 3, fat: 14, confidence: 0, note: "")),
        FoodRule(term: "鸡胗", label: "炒鸡胗（约 1 掌心）", nutrition: NutritionEstimate(calories: 180, protein: 25, carbs: 4, fat: 7, confidence: 0, note: "")),
        FoodRule(term: "牛肉", label: "牛肉菜（约 1 掌心）", nutrition: NutritionEstimate(calories: 250, protein: 26, carbs: 3, fat: 15, confidence: 0, note: "")),
        FoodRule(term: "黑鱼", label: "黑鱼菜（约 1 掌心）", nutrition: NutritionEstimate(calories: 180, protein: 25, carbs: 2, fat: 8, confidence: 0, note: "")),
        FoodRule(term: "鱼", label: "鱼类菜（约 1 掌心）", nutrition: NutritionEstimate(calories: 180, protein: 25, carbs: 2, fat: 8, confidence: 0, note: "")),
        FoodRule(term: "豆腐", label: "豆腐（约 150g）", nutrition: NutritionEstimate(calories: 160, protein: 12, carbs: 5, fat: 10, confidence: 0, note: "")),
        FoodRule(term: "酸奶", label: "高蛋白酸奶（约 1 杯）", nutrition: NutritionEstimate(calories: 120, protein: 10, carbs: 15, fat: 3, confidence: 0, note: "")),
        FoodRule(term: "蛋白粉", label: "蛋白粉（约 1 勺）", nutrition: NutritionEstimate(calories: 120, protein: 24, carbs: 3, fat: 2, confidence: 0, note: "")),
        FoodRule(term: "麦香鸡", label: "麦香鸡", nutrition: NutritionEstimate(calories: 400, protein: 14, carbs: 43, fat: 19, confidence: 0, note: "")),
        FoodRule(term: "汉堡", label: "汉堡（约 1 个）", nutrition: NutritionEstimate(calories: 450, protein: 20, carbs: 42, fat: 22, confidence: 0, note: "")),
        FoodRule(term: "薯条", label: "薯条（中份）", nutrition: NutritionEstimate(calories: 320, protein: 4, carbs: 42, fat: 15, confidence: 0, note: ""))
    ]

    static func estimate(text: String) -> NutritionEstimate {
        let normalized = text.replacingOccurrences(of: " ", with: "").lowercased()
        guard !normalized.isEmpty else {
            return NutritionEstimate(calories: 350, protein: 15, carbs: 40, fat: 14, confidence: 0.2, note: "没有文字描述，给出保守默认值；建议补充食物名称和大致份量。")
        }

        var total = NutritionEstimate.empty
        var matched: [String] = []
        var foundEgg = false
        var foundBread = false
        var foundFish = false

        for rule in rules where normalized.contains(rule.term) {
            if rule.term == "鸡蛋" && foundEgg { continue }
            if rule.term == "煮鸡蛋" { foundEgg = true }
            if rule.term == "面包" && foundBread { continue }
            if rule.term == "全麦面包" { foundBread = true }
            if rule.term == "鱼" && foundFish { continue }
            if rule.term == "黑鱼" { foundFish = true }
            if rule.term == "豆浆" && normalized.contains("无糖豆浆") { continue }

            let amount = quantity(for: rule.term, in: normalized)
            total.calories += rule.nutrition.calories * amount
            total.protein += rule.nutrition.protein * amount
            total.carbs += rule.nutrition.carbs * amount
            total.fat += rule.nutrition.fat * amount
            matched.append("\(rule.label) × \(amount)")
        }

        guard !matched.isEmpty else {
            return NutritionEstimate(calories: 350, protein: 15, carbs: 40, fat: 14, confidence: 0.25, note: "未识别到明确食物，已给出保守默认值。可补充份量，或配置 AI 后上传菜品照片复核。")
        }

        total.confidence = min(0.8, 0.38 + Double(matched.count) * 0.1)
        total.note = "本地估算：\(matched.joined(separator: "、"))。油、酱汁和实际份量会带来误差。"
        return total
    }

    private static func quantity(for term: String, in text: String) -> Int {
        let values: [(String, Int)] = [("五", 5), ("四", 4), ("三", 3), ("两", 2), ("二", 2), ("一", 1), ("5", 5), ("4", 4), ("3", 3), ("2", 2), ("1", 1)]
        for (symbol, number) in values {
            if text.contains("\(symbol)个\(term)") || text.contains("\(symbol)份\(term)") || text.contains("\(symbol)杯\(term)") || text.contains("\(symbol)片\(term)") || text.contains("\(symbol)碗\(term)") || text.contains("\(symbol)\(term)") {
                return number
            }
        }
        return 1
    }
}

// MARK: - AI service

enum AIService {
    static func refineMeal(text: String, imageData: Data?, configuration: AIConfiguration, apiKey: String) async throws -> NutritionEstimate {
        let prompt = """
        你是一位谨慎的中文健身饮食助手。根据用户提供的一餐文字和可选图片，估算热量与宏量营养素。
        只返回一个 JSON 对象，不要 Markdown：
        {"calories":整数,"protein":整数,"carbs":整数,"fat":整数,"confidence":0到1的小数,"note":"中文简短说明，写明主要误差来源"}
        餐食描述：\(text)
        """
        let response = try await send(
            prompt: prompt,
            imageData: configuration.useImageAnalysis ? imageData : nil,
            configuration: configuration,
            apiKey: apiKey,
            systemPrompt: "只输出符合要求的 JSON。不要提供药物剂量、诊断或医疗建议。"
        )
        let json = extractJSON(from: response)
        guard let data = json.data(using: .utf8) else { throw AIError.unreadableResponse }
        return try JSONDecoder().decode(NutritionEstimate.self, from: data)
    }

    static func coachReply(question: String, context: String, configuration: AIConfiguration, apiKey: String) async throws -> String {
        let prompt = """
        你是用户的中文健身教练。给出务实、简短、可执行的减脂与训练建议；不提供药物剂量、疾病诊断或替代医生意见。
        当前数据：\(context)
        用户问题：\(question)
        """
        return try await send(
            prompt: prompt,
            imageData: nil,
            configuration: configuration,
            apiKey: apiKey,
            systemPrompt: configuration.customInstruction.isEmpty ? "用中文回答，先给结论，再给不超过 3 条行动建议。" : configuration.customInstruction
        )
    }

    static func testConnection(configuration: AIConfiguration, apiKey: String) async throws {
        _ = try await send(
            prompt: "回复“连接成功”。",
            imageData: nil,
            configuration: configuration,
            apiKey: apiKey,
            systemPrompt: "只需简短回答。"
        )
    }

    private static func send(prompt: String, imageData: Data?, configuration: AIConfiguration, apiKey: String, systemPrompt: String) async throws -> String {
        guard let url = URL(string: configuration.endpoint.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme == "https" || url.scheme == "http" else {
            throw AIError.invalidEndpoint
        }

        let userContent: Any
        if let imageData {
            let dataURL = "data:image/jpeg;base64,\(imageData.base64EncodedString())"
            userContent = [
                ["type": "text", "text": prompt],
                ["type": "image_url", "image_url": ["url": dataURL]]
            ]
        } else {
            userContent = prompt
        }

        let payload: [String: Any] = [
            "model": configuration.model,
            "temperature": 0.2,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userContent]
            ]
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AIError.requestFailed("没有收到有效服务器响应") }
        guard 200..<300 ~= http.statusCode else {
            let detail = String(data: data, encoding: .utf8) ?? ""
            throw AIError.requestFailed("HTTP \(http.statusCode)：\(detail.prefix(160))")
        }
        return try responseText(from: data)
    }

    private static func responseText(from data: Data) throws -> String {
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = object["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any] else {
            throw AIError.unreadableResponse
        }
        if let content = message["content"] as? String { return content }
        if let content = message["content"] as? [[String: Any]] {
            let text = content.compactMap { $0["text"] as? String }.joined(separator: "\n")
            if !text.isEmpty { return text }
        }
        throw AIError.unreadableResponse
    }

    private static func extractJSON(from text: String) -> String {
        guard let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}") else { return text }
        return String(text[start...end])
    }

    enum AIError: LocalizedError {
        case invalidEndpoint
        case requestFailed(String)
        case unreadableResponse

        var errorDescription: String? {
            switch self {
            case .invalidEndpoint: return "AI 接口地址无效，请填写完整的 http(s) Chat Completions 地址。"
            case .requestFailed(let detail): return "AI 请求失败：\(detail)"
            case .unreadableResponse: return "AI 没有返回可识别的数据。"
            }
        }
    }
}

enum ImageCompressor {
    static func compress(_ data: Data) -> Data {
        guard let image = UIImage(data: data) else { return data }
        let maxSide: CGFloat = 1440
        let longest = max(image.size.width, image.size.height)
        let scale = min(1, maxSide / max(longest, 1))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        return resized.jpegData(compressionQuality: 0.72) ?? data
    }
}

// MARK: - Notifications and Health

enum NotificationManager {
    static func requestAndSchedule(_ reminders: [ReminderItem]) async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        guard granted else { return }
        center.removePendingNotificationRequests(withIdentifiers: reminders.map { $0.id.uuidString })
        for reminder in reminders where reminder.enabled {
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default
            let components = DateComponents(hour: reminder.hour, minute: reminder.minute)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            try await center.add(UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger))
        }
    }
}

@MainActor
final class HealthManager: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var steps = 0
    @Published var errorMessage: String?

    func refreshSteps() async {
        guard HKHealthStore.isHealthDataAvailable(),
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        do {
            try await healthStore.requestAuthorization(toShare: [], read: [stepType])
            let start = Calendar.current.startOfDay(for: Date())
            let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
            let descriptor = HKStatisticsQueryDescriptor(predicate: .quantitySample(type: stepType, predicate: predicate), options: .cumulativeSum)
            let result = try await descriptor.result(for: healthStore)
            steps = Int(result.sumQuantity()?.doubleValue(for: .count()) ?? 0)
            errorMessage = nil
        } catch {
            errorMessage = "未能读取步数，可在健康 App 授权后重试。"
        }
    }
}

// MARK: - Root and today

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack { TodayView() }
                .tabItem { Label("今日", systemImage: "sun.max.fill") }
            NavigationStack { FoodHomeView() }
                .tabItem { Label("饮食", systemImage: "fork.knife") }
            NavigationStack { WorkoutHomeView() }
                .tabItem { Label("训练", systemImage: "dumbbell.fill") }
            NavigationStack { ProgressDashboardView() }
                .tabItem { Label("进度", systemImage: "chart.line.uptrend.xyaxis") }
            NavigationStack { SettingsView() }
                .tabItem { Label("我的", systemImage: "person.crop.circle") }
        }
        .tint(.green)
    }
}

struct TodayView: View {
    @EnvironmentObject private var store: FitnessStore
    @StateObject private var health = HealthManager()
    @State private var showingWeight = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("今天，先完成一件事")
                        .font(.largeTitle.bold())
                    Text("不追求完美；按计划出现，就在变强。")
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    MetricCard(title: "最新体重", value: store.currentWeight.map { String(format: "%.1f kg", $0) } ?? "去记录", icon: "scalemass.fill", color: .blue) {
                        showingWeight = true
                    }
                    MetricCard(title: "今日步数", value: "\(health.steps)", icon: "figure.walk", color: .orange) {
                        Task { await health.refreshSteps() }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("今日营养", systemImage: "chart.pie.fill")
                            .font(.headline)
                        Spacer()
                        Text("\(store.todayNutrition.calories) / \(store.profile.dailyCaloriesGoal) kcal")
                            .font(.subheadline.weight(.semibold))
                    }
                    NutrientProgress(title: "热量", value: store.todayNutrition.calories, target: store.profile.dailyCaloriesGoal, unit: "kcal", color: .orange)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        MacroValue(title: "蛋白质", value: store.todayNutrition.protein, target: store.profile.dailyProteinGoal, color: .green)
                        MacroValue(title: "碳水", value: store.todayNutrition.carbs, target: nil, color: .blue)
                        MacroValue(title: "脂肪", value: store.todayNutrition.fat, target: nil, color: .pink)
                    }
                }
                .cardStyle()

                DailyCheckInCard(healthSteps: health.steps)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("今天吃什么", systemImage: "fork.knife")
                            .font(.headline)
                        Spacer()
                        NavigationLink("去记录") { FoodHomeView() }
                            .font(.subheadline.weight(.semibold))
                    }
                    ForEach(MealType.allCases) { type in
                        NavigationLink { MealLogEditor(initialType: type) } label: {
                            MealStatusRow(type: type, meal: store.meal(for: type))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 9) {
                    Label("今日训练", systemImage: "dumbbell.fill")
                        .font(.headline)
                    Text(store.todayPlan.title).font(.title3.bold())
                    Text(store.todayPlan.subtitle).foregroundStyle(.secondary)
                    if let cardio = store.todayPlan.cardio {
                        Label(cardio, systemImage: "figure.walk")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                    NavigationLink { WorkoutSessionView(plan: store.todayPlan) } label: {
                        Text("开始今天的训练")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                .cardStyle()

                CoachAdviceCard()
            }
            .padding()
        }
        .navigationTitle("练了么")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink { CoachChatView() } label: {
                    Image(systemName: "sparkles")
                }
            }
        }
        .onAppear {
            Task { await health.refreshSteps() }
        }
        .sheet(isPresented: $showingWeight) { WeightEntryView() }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 7) {
                Image(systemName: icon).foregroundStyle(color)
                Text(value).font(.title3.bold()).foregroundStyle(.primary)
                Text(title).font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

struct NutrientProgress: View {
    let title: String
    let value: Int
    let target: Int
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            ProgressView(value: min(Double(value) / Double(max(target, 1)), 1))
                .tint(color)
            Text("\(value) / \(target) \(unit)").font(.subheadline.weight(.semibold))
        }
    }
}

struct MacroValue: View {
    let title: String
    let value: Int
    let target: Int?
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text("\(value)g").font(.headline).foregroundStyle(color)
            if let target { Text("目标 \(target)g").font(.caption2).foregroundStyle(.secondary) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MealStatusRow: View {
    let type: MealType
    let meal: MealLog?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon).frame(width: 24).foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 3) {
                Text(type.rawValue).foregroundStyle(.primary)
                Text(meal.map { "\($0.nutrition.calories) kcal · 蛋白质 \($0.nutrition.protein)g" } ?? "点击记录")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: meal == nil ? "plus.circle" : "checkmark.circle.fill")
                .foregroundStyle(meal == nil ? Color.secondary : Color.green)
        }
    }
}

struct DailyCheckInCard: View {
    @EnvironmentObject private var store: FitnessStore
    let healthSteps: Int
    @State private var water = 0
    @State private var sleep = 7.0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("饮水与恢复", systemImage: "drop.fill")
                .font(.headline)
            HStack {
                Stepper("饮水 \(water) / \(store.profile.dailyWaterGoal) 杯", value: $water, in: 0...20)
                Spacer()
                Image(systemName: water >= store.profile.dailyWaterGoal ? "checkmark.seal.fill" : "drop")
                    .foregroundStyle(water >= store.profile.dailyWaterGoal ? .green : .blue)
            }
            HStack {
                Text("昨晚睡眠 \(String(format: "%.1f", sleep)) 小时")
                Slider(value: $sleep, in: 3...10, step: 0.5)
            }
            HStack {
                Text("步数：\(healthSteps > 0 ? "\(healthSteps)" : "未同步")")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("保存打卡") {
                    store.updateTodayCheckIn(water: water, sleepHours: sleep, steps: healthSteps > 0 ? healthSteps : nil)
                }
                .buttonStyle(.bordered)
            }
        }
        .cardStyle()
        .onAppear {
            let checkIn = store.todayCheckIn
            water = checkIn.waterGlasses
            sleep = checkIn.sleepHours ?? 7
        }
    }
}

struct CoachAdviceCard: View {
    @EnvironmentObject private var store: FitnessStore

    private var tips: [String] {
        var items: [String] = []
        if store.currentWeight == nil { items.append("明早称一次体重；以后看 7 日平均，不用被单日波动影响。") }
        let proteinGap = store.profile.dailyProteinGoal - store.todayNutrition.protein
        if proteinGap > 25 { items.append("今天还差约 \(proteinGap)g 蛋白质：晚餐优先鸡肉、鱼、牛肉、豆腐或酸奶。") }
        if store.todayNutrition.calories > store.profile.dailyCaloriesGoal { items.append("热量已接近或超过目标，晚餐选高蛋白和蔬菜，主食减半。") }
        if store.weeklyTrainingCount < 3 { items.append("本周已记录 \(store.weeklyTrainingCount) 次训练；下班到健身房完成最低训练量就够。") }
        if items.isEmpty { items.append("记录做得不错。训练日保持正常进食，不要为了补偿而极端节食。") }
        return Array(items.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("今日策略", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            ForEach(tips, id: \.self) { tip in
                Label(tip, systemImage: "checkmark")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
    }
}

// MARK: - Food logging

struct FoodHomeView: View {
    @EnvironmentObject private var store: FitnessStore
    @State private var showingMealPicker = false

    var body: some View {
        List {
            Section("今天的饮食") {
                ForEach(MealType.allCases) { type in
                    NavigationLink { MealLogEditor(initialType: type) } label: {
                        MealStatusRow(type: type, meal: store.meal(for: type))
                    }
                }
            }
            Section("营养汇总") {
                LabeledContent("热量", value: "\(store.todayNutrition.calories) kcal")
                LabeledContent("蛋白质", value: "\(store.todayNutrition.protein) g")
                LabeledContent("碳水", value: "\(store.todayNutrition.carbs) g")
                LabeledContent("脂肪", value: "\(store.todayNutrition.fat) g")
            }
            Section("最近记录") {
                if store.meals.isEmpty {
                    Text("从早餐开始记。写下食物和大概份量即可，之后可用 AI 图片复核。")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.meals.prefix(20)) { meal in
                        NavigationLink { MealLogEditor(initialType: meal.type, existing: meal) } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(meal.type.rawValue).font(.headline)
                                    Spacer()
                                    Text(meal.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Text(meal.description).lineLimit(1).foregroundStyle(.secondary)
                                Text("\(meal.nutrition.calories) kcal · 蛋白质 \(meal.nutrition.protein)g · \(meal.source.label)")
                                    .font(.caption).foregroundStyle(.green)
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) { store.deleteMeal(meal) } label: { Label("删除", systemImage: "trash") }
                        }
                    }
                }
            }
        }
        .navigationTitle("饮食")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingMealPicker = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingMealPicker) { MealTypePicker() }
    }
}

struct MealTypePicker: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(MealType.allCases) { type in
                NavigationLink { MealLogEditor(initialType: type) } label: {
                    Label(type.rawValue, systemImage: type.icon)
                }
            }
            .navigationTitle("新增饮食")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("关闭") { dismiss() } }
            }
        }
    }
}

struct MealLogEditor: View {
    @EnvironmentObject private var store: FitnessStore
    @Environment(\.dismiss) private var dismiss
    private let existing: MealLog?
    @State private var mealType: MealType
    @State private var description: String
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var estimate: NutritionEstimate?
    @State private var source: MealEstimateSource
    @State private var isEstimating = false
    @State private var errorText: String?
    @State private var showingManual = false
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""

    init(initialType: MealType, existing: MealLog? = nil) {
        self.existing = existing
        _mealType = State(initialValue: existing?.type ?? initialType)
        _description = State(initialValue: existing?.description ?? "")
        _photoData = State(initialValue: existing?.imageData)
        _estimate = State(initialValue: existing?.nutrition)
        _source = State(initialValue: existing?.source ?? .local)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Picker("餐次", selection: $mealType) {
                    ForEach(MealType.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 6) {
                    Text(mealType == .breakfast ? "早餐吃了什么？" : "这餐吃了什么？")
                        .font(.title3.bold())
                    Text("例如：两个煮鸡蛋、无糖豆浆 300ml、两片全麦面包。盒饭可直接粘贴你实际选的菜。")
                        .font(.subheadline).foregroundStyle(.secondary)
                }

                TextEditor(text: $description)
                    .frame(minHeight: 120)
                    .padding(8)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary))

                if let photoData, let image = UIImage(data: photoData) {
                    Image(uiImage: image)
                        .resizable().scaledToFill().frame(maxHeight: 220).clipShape(RoundedRectangle(cornerRadius: 14))
                }
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label(photoData == nil ? "添加餐食或菜单照片（可选）" : "更换照片", systemImage: "photo")
                }
                .buttonStyle(.bordered)
                .onChange(of: photoItem) { _, item in
                    Task {
                        guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
                        photoData = ImageCompressor.compress(data)
                    }
                }

                Button {
                    Task { await estimateMeal() }
                } label: {
                    HStack {
                        if isEstimating { ProgressView().tint(.white) }
                        Text(store.canUseAI ? "AI 分析并估算" : "立即估算")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled((description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && photoData == nil) || isEstimating)

                Button(showingManual ? "收起手动调整" : "手动填写营养数据") { showingManual.toggle() }
                    .buttonStyle(.bordered)

                if showingManual {
                    ManualNutritionEditor(calories: $calories, protein: $protein, carbs: $carbs, fat: $fat) {
                        applyManualEstimate()
                    }
                }

                if let estimate {
                    NutritionCard(estimate: estimate, source: source)
                    Button("保存\(mealType.rawValue)记录") {
                        let meal = MealLog(
                            id: existing?.id ?? UUID(),
                            date: existing?.date ?? Date(),
                            type: mealType,
                            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                            nutrition: estimate,
                            imageData: photoData,
                            source: source
                        )
                        store.upsertMeal(meal)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }

                if let errorText {
                    Text(errorText).font(.footnote).foregroundStyle(.red)
                }

                if !store.canUseAI {
                    Label("当前使用本地快速估算。到“我的 → AI 接口与教练”填写自己的 API 后，可结合文字和图片复核。", systemImage: "info.circle")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle(existing == nil ? "记录\(mealType.rawValue)" : "编辑饮食")
        .onAppear { syncManualFields() }
    }

    @MainActor
    private func estimateMeal() async {
        isEstimating = true
        errorText = nil
        let text = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let usableText = text.isEmpty ? "\(mealType.rawValue)，请根据图片估算。" : text
        let localEstimate = FoodEstimator.estimate(text: usableText)
        guard store.canUseAI, let key = store.aiKey else {
            estimate = localEstimate
            source = .local
            syncManualFields()
            isEstimating = false
            return
        }
        do {
            estimate = try await AIService.refineMeal(text: usableText, imageData: photoData, configuration: store.aiConfiguration, apiKey: key)
            source = .ai
        } catch {
            estimate = localEstimate
            source = .local
            errorText = "AI 分析失败，已保留本地估算：\(error.localizedDescription)"
        }
        syncManualFields()
        isEstimating = false
    }

    private func applyManualEstimate() {
        let result = NutritionEstimate(
            calories: Int(calories) ?? 0,
            protein: Int(protein) ?? 0,
            carbs: Int(carbs) ?? 0,
            fat: Int(fat) ?? 0,
            confidence: 1,
            note: "手动填写的营养数据。"
        )
        estimate = result
        source = .manual
    }

    private func syncManualFields() {
        guard let estimate else { return }
        calories = "\(estimate.calories)"
        protein = "\(estimate.protein)"
        carbs = "\(estimate.carbs)"
        fat = "\(estimate.fat)"
    }
}

struct ManualNutritionEditor: View {
    @Binding var calories: String
    @Binding var protein: String
    @Binding var carbs: String
    @Binding var fat: String
    let apply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("手动营养调整").font(.headline)
            HStack {
                TextField("热量 kcal", text: $calories).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                TextField("蛋白质 g", text: $protein).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
            }
            HStack {
                TextField("碳水 g", text: $carbs).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                TextField("脂肪 g", text: $fat).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
            }
            Button("应用手动数据", action: apply).buttonStyle(.bordered)
        }
        .cardStyle()
    }
}

struct NutritionCard: View {
    let estimate: NutritionEstimate
    let source: MealEstimateSource

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("营养估算").font(.headline)
                Spacer()
                Text(source.label).font(.caption.weight(.semibold)).foregroundStyle(.green)
            }
            HStack {
                NutritionValue(title: "热量", value: "\(estimate.calories)", unit: "kcal")
                NutritionValue(title: "蛋白质", value: "\(estimate.protein)", unit: "g")
                NutritionValue(title: "碳水", value: "\(estimate.carbs)", unit: "g")
                NutritionValue(title: "脂肪", value: "\(estimate.fat)", unit: "g")
            }
            Text(estimate.note).font(.footnote).foregroundStyle(.secondary)
            Text("可信度：\(Int(estimate.confidence * 100))%（为估算值，油、酱汁与实际份量会造成误差）")
                .font(.caption).foregroundStyle(.secondary)
        }
        .cardStyle()
    }
}

struct NutritionValue: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline) + Text(" \(unit)").font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Workouts and posture

struct WorkoutHomeView: View {
    @EnvironmentObject private var store: FitnessStore

    var body: some View {
        List {
            Section("今天") {
                NavigationLink { WorkoutSessionView(plan: store.todayPlan) } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(store.todayPlan.title).font(.headline)
                        Text(store.todayPlan.subtitle).font(.subheadline).foregroundStyle(.secondary)
                        if let cardio = store.todayPlan.cardio { Text(cardio).font(.caption).foregroundStyle(.green) }
                    }
                }
            }
            Section("体态改善") {
                NavigationLink { PostureGuideView() } label: {
                    Label("前倾、圆肩与久坐改善", systemImage: "figure.stand")
                }
            }
            Section("本周安排") {
                ForEach(WorkoutPlan.weekly) { plan in
                    NavigationLink { WorkoutSessionView(plan: plan) } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(plan.title)
                            Text(plan.subtitle).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section("训练记录") {
                if store.sessions.isEmpty {
                    Text("完成一次训练后，这里会留下重量、次数和主观强度。")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.sessions.prefix(10)) { session in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(session.planTitle).font(.headline)
                            Text("\(session.date.formatted(date: .abbreviated, time: .shortened)) · \(session.exercises.filter(\.completed).count) 个动作完成 · RPE \(session.perceivedEffort)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("训练")
    }
}

private struct ExerciseDraft: Identifiable {
    let id = UUID()
    let exercise: Exercise
    var sets: Int = 3
    var load = ""
    var reps = ""
    var completed = false
}

struct WorkoutSessionView: View {
    @EnvironmentObject private var store: FitnessStore
    @Environment(\.dismiss) private var dismiss
    let plan: WorkoutPlan
    @State private var drafts: [ExerciseDraft]
    @State private var cardioMinutes = ""
    @State private var effort = 7
    @State private var note = ""
    @State private var startedAt = Date()

    init(plan: WorkoutPlan) {
        self.plan = plan
        _drafts = State(initialValue: plan.exercises.map { ExerciseDraft(exercise: $0) })
    }

    var body: some View {
        List {
            if let cardio = plan.cardio {
                Section("有氧") {
                    Label(cardio, systemImage: "figure.walk")
                    TextField("实际有氧分钟数", text: $cardioMinutes).keyboardType(.numberPad)
                }
            }
            if drafts.isEmpty {
                Section { Text("今天以轻松走路或休息为主。恢复也是计划的一部分。") }
            } else {
                Section("力量动作") {
                    ForEach($drafts) { $draft in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(draft.exercise.name).font(.headline)
                                Spacer()
                                Toggle("完成", isOn: $draft.completed).labelsHidden()
                            }
                            Text(draft.exercise.target).font(.caption).foregroundStyle(.secondary)
                            Text(draft.exercise.cue).font(.caption).foregroundStyle(.green)
                            Stepper("组数 \(draft.sets)", value: $draft.sets, in: 1...6)
                            HStack {
                                TextField("重量 kg", text: $draft.load).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                                TextField("最佳次数", text: $draft.reps).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            Section("训练感受") {
                Stepper("主观强度 RPE：\(effort)/10", value: $effort, in: 1...10)
                TextField("备注，例如：最后一组还能做 2 次", text: $note, axis: .vertical)
            }
            Section {
                Button("完成并保存训练") {
                    let logs = drafts.map {
                        WorkoutExerciseLog(
                            exerciseName: $0.exercise.name,
                            target: $0.exercise.target,
                            sets: $0.sets,
                            loadKilograms: Double($0.load),
                            reps: Int($0.reps),
                            completed: $0.completed
                        )
                    }
                    let duration = max(1, Int(Date().timeIntervalSince(startedAt) / 60))
                    store.addSession(WorkoutSession(
                        planID: plan.id,
                        planTitle: plan.title,
                        exercises: logs,
                        cardioMinutes: Int(cardioMinutes) ?? 0,
                        perceivedEffort: effort,
                        note: note,
                        durationMinutes: duration
                    ))
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(.green)
            }
        }
        .navigationTitle(plan.title)
        .onAppear { startedAt = Date() }
    }
}

struct PostureGuideView: View {
    private let guides = [
        ("前倾头位", "下巴微收 2 组 × 10 次", "像把后脑勺轻轻推向后方，不低头，也不要用力仰头。"),
        ("圆肩／含胸", "靠墙滑手、面拉", "胸椎自然伸展，肩膀远离耳朵；以轻重量、慢动作优先。"),
        ("骨盆前倾感", "臀桥、髋屈肌拉伸", "先轻微收肋骨和骨盆，再夹臀；避免靠腰部硬顶。"),
        ("久坐", "每小时起身 2–3 分钟", "走几步、做 10 次下巴微收或靠墙站立，比一次性拉很久更容易坚持。")
    ]

    var body: some View {
        List {
            Section("先说明") {
                Text("这些是一般训练提示，不用于诊断。如果有持续疼痛、麻木或明显不对称，请先咨询医生或康复专业人员。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("每天 8–10 分钟") {
                ForEach(guides, id: \.0) { item in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(item.0).font(.headline)
                        Text(item.1).foregroundStyle(.green)
                        Text(item.2).font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("体态改善")
    }
}

// MARK: - Progress

struct ProgressDashboardView: View {
    @EnvironmentObject private var store: FitnessStore
    @State private var showingWeight = false

    private var chartEntries: [WeightEntry] {
        Array(store.weights.sorted { $0.date < $1.date }.suffix(30))
    }

    private var chartDomain: ClosedRange<Double> {
        let values = chartEntries.map(\.kilograms) + [store.profile.currentWeightGoal]
        let low = (values.min() ?? 70) - 1
        let high = (values.max() ?? 90) + 1
        return low...max(high, low + 2)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    SummaryMetric(title: "最新体重", value: store.currentWeight.map { String(format: "%.1f kg", $0) } ?? "未记录", color: .blue)
                    SummaryMetric(title: "7 日平均", value: store.sevenDayAverage.map { String(format: "%.1f kg", $0) } ?? "数据不足", color: .green)
                    SummaryMetric(title: "最新腰围", value: store.latestWaist.map { String(format: "%.0f cm", $0) } ?? "未记录", color: .orange)
                    SummaryMetric(title: "本周训练", value: "\(store.weeklyTrainingCount) 次", color: .purple)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("体重趋势").font(.headline)
                        Spacer()
                        Text("目标 \(String(format: "%.0f", store.profile.currentWeightGoal)) kg")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if chartEntries.isEmpty {
                        Text("至少记录一次体重后显示趋势。建议晨起、如厕后、进食饮水前称重。")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 180, alignment: .leading)
                    } else {
                        Chart(chartEntries) { entry in
                            LineMark(x: .value("日期", entry.date), y: .value("体重", entry.kilograms))
                                .foregroundStyle(.green)
                                .interpolationMethod(.catmullRom)
                            PointMark(x: .value("日期", entry.date), y: .value("体重", entry.kilograms))
                                .foregroundStyle(.green)
                        }
                        .chartYScale(domain: chartDomain)
                        .frame(height: 190)
                    }
                    ProgressView(value: store.goalProgress)
                        .tint(.green)
                    Text("从 \(String(format: "%.1f", store.profile.startingWeight)) kg 到 \(String(format: "%.1f", store.profile.currentWeightGoal)) kg：已完成 \(Int(store.goalProgress * 100))%")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 8) {
                    Text("趋势解读").font(.headline)
                    Text(trendAdvice).font(.subheadline).foregroundStyle(.secondary)
                }
                .cardStyle()

                Button { showingWeight = true } label: {
                    Label("记录体重和腰围", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                if !store.weights.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("最近记录").font(.headline)
                        ForEach(store.weights.sorted { $0.date > $1.date }.prefix(14)) { entry in
                            HStack {
                                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                Spacer()
                                Text(String(format: "%.1f kg", entry.kilograms)).bold()
                                if let waist = entry.waistCentimeters {
                                    Text(String(format: "腰围 %.0fcm", waist)).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            Divider()
                        }
                    }
                    .cardStyle()
                }
            }
            .padding()
        }
        .navigationTitle("进度")
        .sheet(isPresented: $showingWeight) { WeightEntryView() }
    }

    private var trendAdvice: String {
        guard let average = store.sevenDayAverage else { return "先连续记录 7 天体重。日常水分、盐分和训练后的炎症都会让单日体重波动。" }
        if average <= store.profile.currentWeightGoal { return "你已经到达或低于设定目标。接下来把重点放在维持、力量训练和体态改善上。" }
        return "目前 7 日平均为 \(String(format: "%.1f", average)) kg。只要周均趋势缓慢下降、训练能恢复，就不必频繁大幅调整饮食。"
    }
}

struct SummaryMetric: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

struct WeightEntryView: View {
    @EnvironmentObject private var store: FitnessStore
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()
    @State private var weight = ""
    @State private var waist = ""
    @State private var validationMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("身体数据") {
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                    TextField("体重（kg）", text: $weight).keyboardType(.decimalPad)
                    TextField("腰围（cm，可选）", text: $waist).keyboardType(.decimalPad)
                }
                Section {
                    Text("建议在晨起、如厕后、进食饮水前称重；腰围固定在同一位置测量。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if !validationMessage.isEmpty {
                    Section { Text(validationMessage).foregroundStyle(.red) }
                }
            }
            .navigationTitle("记录体重")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let value = Double(weight.replacingOccurrences(of: ",", with: ".")), value > 0 else {
                            validationMessage = "请填写有效的体重。"
                            return
                        }
                        let waistValue = Double(waist.replacingOccurrences(of: ",", with: "."))
                        store.addWeight(kilograms: value, waist: waistValue, date: date)
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let entry = store.weights.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                    weight = String(format: "%.1f", entry.kilograms)
                    waist = entry.waistCentimeters.map { String(format: "%.0f", $0) } ?? ""
                }
            }
        }
    }
}

// MARK: - AI coach and settings

struct CoachChatView: View {
    @EnvironmentObject private var store: FitnessStore
    @State private var question = ""
    @State private var isSending = false
    @State private var errorText: String?

    var body: some View {
        VStack(spacing: 0) {
            if !store.canUseAI {
                ContentUnavailableView("尚未配置 AI", systemImage: "sparkles", description: Text("到“我的 → AI 接口与教练”填写你自己的接口、模型和 API Key。"))
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            if store.chatMessages.isEmpty {
                                Text("可以问：今晚吃什么更适合减脂？今天的训练怎么做？蛋白质还差多少？")
                                    .font(.subheadline).foregroundStyle(.secondary)
                                    .padding(.top)
                            }
                            ForEach(store.chatMessages) { message in
                                HStack {
                                    if message.isUser { Spacer(minLength: 42) }
                                    Text(message.content)
                                        .padding(11)
                                        .background(message.isUser ? Color.green.opacity(0.18) : Color(uiColor: .secondarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                    if !message.isUser { Spacer(minLength: 42) }
                                }
                                .id(message.id)
                            }
                            if isSending { ProgressView("AI 正在思考…") }
                        }
                        .padding()
                    }
                    .onChange(of: store.chatMessages.count) { _, _ in
                        if let id = store.chatMessages.last?.id { proxy.scrollTo(id, anchor: .bottom) }
                    }
                }
            }
            if let errorText { Text(errorText).font(.caption).foregroundStyle(.red).padding(.horizontal) }
            HStack(alignment: .bottom, spacing: 8) {
                TextField("问问你的减脂计划…", text: $question, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                Button {
                    Task { await send() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill").font(.title2)
                }
                .disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending || !store.canUseAI)
            }
            .padding()
        }
        .navigationTitle("AI 教练")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("清空", role: .destructive) { store.clearChat() }
                    .disabled(store.chatMessages.isEmpty)
            }
        }
    }

    @MainActor
    private func send() async {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let key = store.aiKey else { return }
        store.appendChat(isUser: true, content: trimmed)
        question = ""
        isSending = true
        errorText = nil
        do {
            let reply = try await AIService.coachReply(question: trimmed, context: store.coachContext, configuration: store.aiConfiguration, apiKey: key)
            store.appendChat(isUser: false, content: reply)
        } catch {
            errorText = error.localizedDescription
        }
        isSending = false
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: FitnessStore

    var body: some View {
        Form {
            Section("个人目标") {
                TextField("身高（cm）", value: $store.profile.heightCentimeters, format: .number).keyboardType(.decimalPad)
                Stepper("年龄：\(store.profile.age) 岁", value: $store.profile.age, in: 16...80)
                Picker("性别", selection: $store.profile.sex) {
                    ForEach(BiologicalSex.allCases) { Text($0.rawValue).tag($0) }
                }
                TextField("开始体重（kg）", value: $store.profile.startingWeight, format: .number).keyboardType(.decimalPad)
                TextField("目标体重（kg）", value: $store.profile.currentWeightGoal, format: .number).keyboardType(.decimalPad)
            }
            Section("每日目标") {
                Stepper("热量：\(store.profile.dailyCaloriesGoal) kcal", value: $store.profile.dailyCaloriesGoal, in: 1500...4000, step: 50)
                Stepper("蛋白质：\(store.profile.dailyProteinGoal) g", value: $store.profile.dailyProteinGoal, in: 80...240, step: 5)
                Stepper("步数：\(store.profile.dailyStepsGoal)", value: $store.profile.dailyStepsGoal, in: 3000...15000, step: 500)
                Stepper("饮水：\(store.profile.dailyWaterGoal) 杯", value: $store.profile.dailyWaterGoal, in: 4...16)
            }
            Section("智能与提醒") {
                NavigationLink { AISettingsView() } label: {
                    Label(store.canUseAI ? "AI 接口与教练（已连接）" : "AI 接口与教练", systemImage: "sparkles")
                }
                NavigationLink { ReminderSettingsView() } label: {
                    Label("自定义提醒", systemImage: "bell.badge")
                }
            }
            Section("健康数据") {
                Label("首页可读取当日步数", systemImage: "heart.text.square")
                Text("首次点击步数会请求 HealthKit 授权；你可以只允许读取步数。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("数据与安全") {
                Text("饮食、训练和体重数据只保存在本机。API Key 仅保存于本机 Keychain，不会写入 GitHub 或代码。")
                    .font(.footnote).foregroundStyle(.secondary)
                Text("这是个人训练工具，不提供药物剂量或疾病诊断。出现持续疼痛或不适时，请咨询医生或康复专业人员。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("我的")
    }
}

struct AISettingsView: View {
    @EnvironmentObject private var store: FitnessStore
    @State private var endpoint = ""
    @State private var model = ""
    @State private var apiKey = ""
    @State private var useImageAnalysis = true
    @State private var instruction = ""
    @State private var message = ""
    @State private var isTesting = false

    var body: some View {
        Form {
            Section("连接信息") {
                TextField("完整 Chat Completions 地址", text: $endpoint)
                    .textInputAutocapitalization(.never).keyboardType(.URL).autocorrectionDisabled()
                TextField("模型名称", text: $model)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                SecureField("API Key（留空则保留当前 Key）", text: $apiKey)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                Menu("填入常见示例") {
                    Button("OpenAI Chat Completions") {
                        endpoint = "https://api.openai.com/v1/chat/completions"
                        if model.isEmpty { model = "gpt-4o-mini" }
                    }
                    Button("清空") {
                        endpoint = ""
                        model = ""
                    }
                }
            }
            Section("AI 行为") {
                Toggle("餐食分析时发送图片", isOn: $useImageAnalysis)
                TextEditor(text: $instruction)
                    .frame(minHeight: 88)
                Text("上方可填写额外教练风格要求，例如“语气直接、每次只给三条建议”。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("密钥状态") {
                HStack {
                    Label(store.hasAIKey ? "已保存本机 Key" : "未保存 Key", systemImage: store.hasAIKey ? "checkmark.shield.fill" : "key.slash")
                    Spacer()
                    if store.hasAIKey {
                        Button("删除 Key", role: .destructive) {
                            store.clearAIKey()
                            message = "已从本机 Keychain 删除 API Key。"
                        }
                    }
                }
                Text("个人自用可直连；不要把共享或付费 API Key 写进 App 源码。若以后给他人使用，必须改为服务端代理。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section {
                Button("保存 AI 配置") {
                    store.saveAI(configuration: AIConfiguration(endpoint: endpoint.trimmingCharacters(in: .whitespacesAndNewlines), model: model.trimmingCharacters(in: .whitespacesAndNewlines), useImageAnalysis: useImageAnalysis, customInstruction: instruction.trimmingCharacters(in: .whitespacesAndNewlines)), apiKey: apiKey)
                    apiKey = ""
                    message = store.canUseAI ? "已保存。饮食记录和 AI 教练现在会使用你的接口。" : "已保存地址和模型；还需要填写 API Key 才能调用。"
                }
                .disabled(endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button {
                    Task { await testConnection() }
                } label: {
                    if isTesting { ProgressView() } else { Text("测试连接") }
                }
                .disabled(!store.canUseAI || isTesting)
            }
            if !message.isEmpty {
                Section { Text(message).font(.footnote).foregroundStyle(.secondary) }
            }
        }
        .navigationTitle("AI 接口与教练")
        .onAppear {
            endpoint = store.aiConfiguration.endpoint
            model = store.aiConfiguration.model
            useImageAnalysis = store.aiConfiguration.useImageAnalysis
            instruction = store.aiConfiguration.customInstruction
        }
    }

    @MainActor
    private func testConnection() async {
        guard let key = store.aiKey else { return }
        isTesting = true
        message = "正在测试连接…"
        do {
            try await AIService.testConnection(configuration: store.aiConfiguration, apiKey: key)
            message = "连接成功。"
        } catch {
            message = "连接失败：\(error.localizedDescription)"
        }
        isTesting = false
    }
}

struct ReminderSettingsView: View {
    @EnvironmentObject private var store: FitnessStore
    @State private var drafts: [ReminderItem] = []
    @State private var showingAdd = false
    @State private var message = ""

    var body: some View {
        List {
            Section("提醒") {
                ForEach($drafts) { $reminder in
                    ReminderEditor(reminder: $reminder)
                }
                .onDelete { drafts.remove(atOffsets: $0) }
                Button { showingAdd = true } label: { Label("新增提醒", systemImage: "plus.circle") }
            }
            Section {
                Text("保存后会请求通知权限。每一条提醒都可以独立开关、改名称和修改时间。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            if !message.isEmpty { Section { Text(message).font(.footnote).foregroundStyle(.secondary) } }
        }
        .navigationTitle("自定义提醒")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("保存") { save() }
            }
        }
        .onAppear { drafts = store.reminders }
        .sheet(isPresented: $showingAdd) {
            NewReminderView { reminder in
                drafts.append(reminder)
            }
        }
    }

    private func save() {
        store.reminders = drafts
        Task {
            do {
                try await NotificationManager.requestAndSchedule(drafts)
                message = "提醒已更新。"
            } catch {
                message = "无法开启提醒：\(error.localizedDescription)"
            }
        }
    }
}

struct ReminderEditor: View {
    @Binding var reminder: ReminderItem

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                TextField("提醒名称", text: $reminder.title)
                Toggle("启用", isOn: $reminder.enabled).labelsHidden()
            }
            TextField("提醒内容", text: $reminder.body, axis: .vertical)
                .font(.subheadline)
            DatePicker("时间", selection: Binding(get: { reminder.time }, set: { reminder.setTime($0) }), displayedComponents: .hourAndMinute)
                .disabled(!reminder.enabled)
        }
        .padding(.vertical, 5)
    }
}

struct NewReminderView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var reminder = ReminderItem(title: "新提醒", body: "", hour: 20, minute: 0, enabled: true)
    let add: (ReminderItem) -> Void

    var body: some View {
        NavigationStack {
            Form { ReminderEditor(reminder: $reminder) }
                .navigationTitle("新增提醒")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("添加") {
                            add(reminder)
                            dismiss()
                        }
                    }
                }
        }
    }
}

extension View {
    func cardStyle() -> some View {
        padding(14)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
