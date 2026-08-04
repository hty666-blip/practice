import SwiftUI
import PhotosUI
import UserNotifications
import HealthKit
import Security

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

struct NutritionEstimate: Codable, Equatable {
    var calories: Int
    var protein: Int
    var carbs: Int
    var fat: Int
    var confidence: Double
    var note: String

    static let empty = NutritionEstimate(calories: 0, protein: 0, carbs: 0, fat: 0, confidence: 0, note: "")
}

struct MealLog: Codable, Identifiable {
    var id = UUID()
    var date = Date()
    var type: MealType
    var description: String
    var nutrition: NutritionEstimate
    var imageData: Data?
}

struct WeightEntry: Codable, Identifiable {
    var id = UUID()
    var date = Date()
    var kilograms: Double
    var waistCentimeters: Double?
}

struct FitnessProfile: Codable {
    var heightCentimeters = 185.0
    var currentWeightGoal = 75.0
    var dailyCaloriesGoal = 2250
    var dailyProteinGoal = 140
    var dailyStepsGoal = 8000
}

struct AIConfiguration: Codable {
    var endpoint = ""
    var model = ""
}

struct ReminderItem: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var body: String
    var hour: Int
    var minute: Int
    var enabled: Bool

    var date: Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }

    mutating func setTime(_ date: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        hour = components.hour ?? hour
        minute = components.minute ?? minute
    }

    static let defaults = [
        ReminderItem(id: "weight", title: "晨起称重", body: "记录今天的体重，趋势比单日数字更重要。", hour: 7, minute: 30, enabled: true),
        ReminderItem(id: "lunch", title: "午餐选择", body: "把菜单发给我，先选好蛋白质和蔬菜。", hour: 10, minute: 0, enabled: true),
        ReminderItem(id: "workout", title: "下班训练", body: "今天先到健身房，完成最小训练也算赢。", hour: 17, minute: 50, enabled: true),
        ReminderItem(id: "review", title: "晚间复盘", body: "记录晚餐和今天的完成情况，为明天留好余地。", hour: 21, minute: 30, enabled: true)
    ]
}

struct Exercise: Codable, Identifiable {
    var id: String { name }
    var name: String
    var target: String
}

struct WorkoutPlan: Codable, Identifiable {
    var id: String
    var weekday: Int
    var title: String
    var subtitle: String
    var exercises: [Exercise]
    var cardio: String?

    static let weekly: [WorkoutPlan] = [
        WorkoutPlan(id: "sun", weekday: 1, title: "轻松恢复", subtitle: "散步或休息，给身体恢复空间", exercises: [], cardio: "轻松走路 30–60 分钟（可选）"),
        WorkoutPlan(id: "mon", weekday: 2, title: "全身力量 A", subtitle: "下肢、推、拉与核心", exercises: [
            Exercise(name: "腿举", target: "3 组 × 8–12 次"), Exercise(name: "坐姿推胸", target: "3 组 × 8–12 次"),
            Exercise(name: "高位下拉", target: "3 组 × 8–12 次"), Exercise(name: "坐姿腿弯举", target: "3 组 × 10–15 次"),
            Exercise(name: "坐姿划船", target: "3 组 × 10–12 次"), Exercise(name: "反向蝴蝶机", target: "2 组 × 12–15 次"),
            Exercise(name: "平板支撑", target: "3 组 × 20–40 秒")
        ], cardio: "跑步机走坡 15 分钟"),
        WorkoutPlan(id: "tue", weekday: 3, title: "有氧＋体态", subtitle: "降低疲劳、提高活动量", exercises: [
            Exercise(name: "下巴微收", target: "2 组 × 10 次"), Exercise(name: "靠墙滑手", target: "2 组 × 10 次"),
            Exercise(name: "臀桥", target: "2 组 × 15 次"), Exercise(name: "胸肌拉伸", target: "每侧 2 组 × 30 秒")
        ], cardio: "跑步机坡走 30–40 分钟"),
        WorkoutPlan(id: "wed", weekday: 4, title: "全身力量 B", subtitle: "臀腿、上胸、背部与抗旋转", exercises: [
            Exercise(name: "哈克深蹲或史密斯深蹲", target: "3 组 × 8–12 次"), Exercise(name: "臀推机", target: "3 组 × 10–12 次"),
            Exercise(name: "上斜推胸机", target: "3 组 × 8–12 次"), Exercise(name: "窄握高位下拉", target: "3 组 × 8–12 次"),
            Exercise(name: "胸托划船", target: "3 组 × 10–12 次"), Exercise(name: "绳索面拉", target: "2 组 × 12–15 次"),
            Exercise(name: "Pallof 抗旋转推", target: "每侧 2 组 × 12 次")
        ], cardio: "跑步机走坡 15 分钟"),
        WorkoutPlan(id: "thu", weekday: 5, title: "有氧＋体态", subtitle: "把活动量做扎实", exercises: [
            Exercise(name: "靠墙滑手", target: "2 组 × 10 次"), Exercise(name: "髋屈肌拉伸", target: "每侧 2 组 × 30 秒"),
            Exercise(name: "臀桥", target: "2 组 × 15 次"), Exercise(name: "平板支撑", target: "3 组 × 20–40 秒")
        ], cardio: "跑步机坡走 30–40 分钟"),
        WorkoutPlan(id: "fri", weekday: 6, title: "全身力量 A", subtitle: "巩固力量和训练动作", exercises: [
            Exercise(name: "腿举", target: "3 组 × 8–12 次"), Exercise(name: "坐姿推胸", target: "3 组 × 8–12 次"),
            Exercise(name: "高位下拉", target: "3 组 × 8–12 次"), Exercise(name: "坐姿腿弯举", target: "3 组 × 10–15 次"),
            Exercise(name: "坐姿划船", target: "3 组 × 10–12 次"), Exercise(name: "反向蝴蝶机", target: "2 组 × 12–15 次"),
            Exercise(name: "平板支撑", target: "3 组 × 20–40 秒")
        ], cardio: "跑步机走坡 15 分钟"),
        WorkoutPlan(id: "sat", weekday: 7, title: "主动恢复", subtitle: "轻松走路，不补偿性训练", exercises: [], cardio: "户外走路 60 分钟（可选）")
    ]
}

struct WorkoutSession: Codable, Identifiable {
    var id = UUID()
    var date = Date()
    var planTitle: String
    var completedExerciseNames: [String]
    var note: String
}

// MARK: - Local store

@MainActor
final class FitnessStore: ObservableObject {
    @Published private(set) var meals: [MealLog]
    @Published private(set) var weights: [WeightEntry]
    @Published private(set) var sessions: [WorkoutSession]
    @Published var profile: FitnessProfile { didSet { save(profile, key: Keys.profile) } }
    @Published var aiConfiguration: AIConfiguration { didSet { save(aiConfiguration, key: Keys.aiConfiguration) } }
    @Published var reminders: [ReminderItem] { didSet { save(reminders, key: Keys.reminders) } }

    private enum Keys {
        static let meals = "gymcoach.meals"
        static let weights = "gymcoach.weights"
        static let sessions = "gymcoach.sessions"
        static let profile = "gymcoach.profile"
        static let aiConfiguration = "gymcoach.aiConfiguration"
        static let reminders = "gymcoach.reminders"
    }

    init() {
        meals = Self.load([MealLog].self, key: Keys.meals) ?? []
        weights = Self.load([WeightEntry].self, key: Keys.weights) ?? []
        sessions = Self.load([WorkoutSession].self, key: Keys.sessions) ?? []
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
        todayMeals.reduce(.empty) { partial, meal in
            NutritionEstimate(calories: partial.calories + meal.nutrition.calories,
                              protein: partial.protein + meal.nutrition.protein,
                              carbs: partial.carbs + meal.nutrition.carbs,
                              fat: partial.fat + meal.nutrition.fat,
                              confidence: 0,
                              note: "")
        }
    }

    var currentWeight: Double? {
        weights.sorted { $0.date > $1.date }.first?.kilograms
    }

    func meal(for type: MealType) -> MealLog? {
        todayMeals.filter { $0.type == type }.sorted { $0.date > $1.date }.first
    }

    func upsertMeal(_ meal: MealLog) {
        meals.removeAll { Calendar.current.isDate($0.date, inSameDayAs: meal.date) && $0.type == meal.type }
        meals.append(meal)
        save(meals, key: Keys.meals)
    }

    func addWeight(kilograms: Double, waist: Double?) {
        weights.removeAll { Calendar.current.isDateInToday($0.date) }
        weights.append(WeightEntry(kilograms: kilograms, waistCentimeters: waist))
        save(weights, key: Keys.weights)
    }

    func addSession(_ session: WorkoutSession) {
        sessions.append(session)
        save(sessions, key: Keys.sessions)
    }

    func configureAI(endpoint: String, model: String, apiKey: String) {
        aiConfiguration = AIConfiguration(endpoint: endpoint.trimmingCharacters(in: .whitespacesAndNewlines), model: model.trimmingCharacters(in: .whitespacesAndNewlines))
        if !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            KeychainStore.save(apiKey.trimmingCharacters(in: .whitespacesAndNewlines), account: "ai-api-key")
        }
    }

    var aiKey: String? { KeychainStore.read(account: "ai-api-key") }
    var canUseAI: Bool { !aiConfiguration.endpoint.isEmpty && !aiConfiguration.model.isEmpty && aiKey != nil }

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
    static func save(_ value: String, account: String) {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrAccount as String: account]
        SecItemDelete(query as CFDictionary)
        var item = query
        item[kSecValueData as String] = Data(value.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(item as CFDictionary, nil)
    }

    static func read(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - Nutrition estimation

enum FoodEstimator {
    private struct FoodRule {
        let terms: [String]
        let calories: Int
        let protein: Int
        let carbs: Int
        let fat: Int
        let label: String
    }

    private static let rules: [FoodRule] = [
        FoodRule(terms: ["鸡蛋", "煮蛋"], calories: 70, protein: 6, carbs: 0, fat: 5, label: "鸡蛋（每个）"),
        FoodRule(terms: ["无糖豆浆"], calories: 95, protein: 9, carbs: 6, fat: 4, label: "无糖豆浆（约300ml）"),
        FoodRule(terms: ["豆浆"], calories: 150, protein: 8, carbs: 20, fat: 5, label: "豆浆（约300ml，含糖可能更高）"),
        FoodRule(terms: ["纯牛奶", "牛奶"], calories: 150, protein: 9, carbs: 14, fat: 6, label: "牛奶（约300ml）"),
        FoodRule(terms: ["全麦面包", "面包"], calories: 160, protein: 6, carbs: 28, fat: 3, label: "面包（约2片）"),
        FoodRule(terms: ["八宝粥"], calories: 250, protein: 4, carbs: 52, fat: 2, label: "八宝粥（约1罐）"),
        FoodRule(terms: ["香蕉"], calories: 105, protein: 1, carbs: 27, fat: 0, label: "香蕉（1根）"),
        FoodRule(terms: ["苹果"], calories: 95, protein: 1, carbs: 25, fat: 0, label: "苹果（1个）"),
        FoodRule(terms: ["米饭"], calories: 230, protein: 5, carbs: 52, fat: 0, label: "米饭（约1小碗）"),
        FoodRule(terms: ["鸡胸"], calories: 165, protein: 31, carbs: 0, fat: 4, label: "鸡胸肉（约100g）"),
        FoodRule(terms: ["鸡肉", "炒鸡"], calories: 240, protein: 25, carbs: 3, fat: 14, label: "鸡肉菜（约1掌心）"),
        FoodRule(terms: ["牛肉"], calories: 250, protein: 26, carbs: 3, fat: 15, label: "牛肉菜（约1掌心）"),
        FoodRule(terms: ["鱼", "黑鱼"], calories: 180, protein: 25, carbs: 2, fat: 8, label: "鱼类菜（约1掌心）"),
        FoodRule(terms: ["豆腐"], calories: 160, protein: 12, carbs: 5, fat: 10, label: "豆腐（约150g）"),
        FoodRule(terms: ["酸奶"], calories: 120, protein: 10, carbs: 15, fat: 3, label: "高蛋白酸奶（约1杯）")
    ]

    static func estimate(text: String) -> NutritionEstimate {
        let normalized = text.replacingOccurrences(of: " ", with: "").lowercased()
        var total = NutritionEstimate.empty
        var matched: [String] = []
        var usedGenericSoy = false

        for rule in rules {
            guard let term = rule.terms.first(where: { normalized.contains($0) }) else { continue }
            if term == "豆浆" && normalized.contains("无糖豆浆") { continue }
            if term == "豆浆" && usedGenericSoy { continue }
            if term == "豆浆" { usedGenericSoy = true }
            let count = quantity(for: term, in: normalized)
            total.calories += rule.calories * count
            total.protein += rule.protein * count
            total.carbs += rule.carbs * count
            total.fat += rule.fat * count
            matched.append("\(rule.label) × \(count)")
        }

        if matched.isEmpty {
            return NutritionEstimate(calories: 350, protein: 15, carbs: 40, fat: 14, confidence: 0.25, note: "未识别到明确食物，已给出保守默认估算。建议补充份量或配置 AI 图片分析。")
        }

        total.confidence = min(0.78, 0.38 + Double(matched.count) * 0.1)
        total.note = "本地快速估算：\(matched.joined(separator: "、"))。油、酱汁和实际份量会带来误差。"
        return total
    }

    private static func quantity(for term: String, in text: String) -> Int {
        if text.contains("两个\(term)") || text.contains("两\(term)") { return 2 }
        if text.contains("三个\(term)") || text.contains("三\(term)") { return 3 }
        let pattern = "([1-5])个?\(NSRegularExpression.escapedPattern(for: term))"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text),
           let amount = Int(text[range]) {
            return amount
        }
        return 1
    }
}

struct AIService {
    static func refineMeal(text: String, imageData: Data?, configuration: AIConfiguration, apiKey: String) async throws -> NutritionEstimate {
        guard let url = URL(string: configuration.endpoint) else { throw AIError.invalidEndpoint }
        let prompt = """
        你是一位谨慎的中文健身饮食助手。根据用户提供的餐食文字和可选图片，估算这一餐的能量与宏量营养。只返回一个 JSON 对象，不能有 Markdown：
        {"calories":整数,"protein":整数,"carbs":整数,"fat":整数,"confidence":0到1小数,"note":"中文简短说明，提示主要误差来源"}
        用户餐食：\(text)
        """

        var content: [[String: Any]] = [["type": "text", "text": prompt]]
        if let imageData {
            let dataURL = "data:image/jpeg;base64,\(imageData.base64EncodedString())"
            content.append(["type": "image_url", "image_url": ["url": dataURL]])
        }
        let payload: [String: Any] = [
            "model": configuration.model,
            "temperature": 0.2,
            "messages": [
                ["role": "system", "content": "请只输出符合要求的 JSON，不提供药物剂量或医学诊断。"],
                ["role": "user", "content": content]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw AIError.requestFailed }
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = object["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String,
              let jsonData = extractJSON(from: content).data(using: .utf8) else { throw AIError.unreadableResponse }
        return try JSONDecoder().decode(NutritionEstimate.self, from: jsonData)
    }

    private static func extractJSON(from text: String) -> String {
        guard let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}") else { return text }
        return String(text[start...end])
    }

    enum AIError: LocalizedError {
        case invalidEndpoint, requestFailed, unreadableResponse
        var errorDescription: String? {
            switch self {
            case .invalidEndpoint: return "AI 接口地址不正确。"
            case .requestFailed: return "AI 接口请求失败，请检查网络、地址、模型和 Key。"
            case .unreadableResponse: return "AI 没有返回可识别的营养数据。"
            }
        }
    }
}

// MARK: - Notifications and Health

enum NotificationManager {
    static func requestAndSchedule(_ reminders: [ReminderItem]) async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        guard granted else { return }
        center.removePendingNotificationRequests(withIdentifiers: reminders.map(\.id))
        for reminder in reminders where reminder.enabled {
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: reminder.hour, minute: reminder.minute), repeats: true)
            center.add(UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger))
        }
    }
}

final class HealthManager: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var steps = 0

    func requestSteps() async {
        guard HKHealthStore.isHealthDataAvailable(), let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        do {
            try await healthStore.requestAuthorization(toShare: [], read: [stepType])
            await loadTodaySteps(stepType: stepType)
        } catch { }
    }

    private func loadTodaySteps(stepType: HKQuantityType) async {
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let descriptor = HKStatisticsQueryDescriptor(predicate: .quantitySample(type: stepType, predicate: predicate), options: .cumulativeSum)
        if let result = try? await descriptor.result(for: healthStore), let sum = result.sumQuantity() {
            await MainActor.run { steps = Int(sum.doubleValue(for: .count())) }
        }
    }
}

// MARK: - Root and Today

struct RootView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { TodayView(selectedTab: $selectedTab) }
                .tabItem { Label("今日", systemImage: "sun.max.fill") }.tag(0)
            NavigationStack { WorkoutHomeView() }
                .tabItem { Label("训练", systemImage: "dumbbell.fill") }.tag(1)
            NavigationStack { MealLogView(initialMealType: .breakfast) }
                .tabItem { Label("饮食", systemImage: "fork.knife") }.tag(2)
            NavigationStack { ProgressDashboardView() }
                .tabItem { Label("进度", systemImage: "chart.line.uptrend.xyaxis") }.tag(3)
            NavigationStack { SettingsView() }
                .tabItem { Label("我的", systemImage: "person.crop.circle") }.tag(4)
        }
        .tint(.green)
    }
}

struct TodayView: View {
    @EnvironmentObject private var store: FitnessStore
    @Binding var selectedTab: Int
    @StateObject private var health = HealthManager()
    @State private var showingWeight = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("今天，先完成一件事")
                        .font(.largeTitle.bold())
                    Text("不追求完美；按计划出现，就在变强。")
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    MetricCard(title: "体重", value: store.currentWeight.map { String(format: "%.1f kg", $0) } ?? "未记录", icon: "scalemass.fill", color: .blue) { showingWeight = true }
                    MetricCard(title: "步数", value: "\(health.steps)", icon: "figure.walk", color: .orange) {
                        Task { await health.requestSteps() }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Label("今日营养", systemImage: "chart.pie.fill")
                        .font(.headline)
                    HStack {
                        NutrientProgress(title: "能量", value: store.todayNutrition.calories, target: store.profile.dailyCaloriesGoal, unit: "kcal", color: .orange)
                        NutrientProgress(title: "蛋白质", value: store.todayNutrition.protein, target: store.profile.dailyProteinGoal, unit: "g", color: .green)
                    }
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("今天吃什么", systemImage: "fork.knife")
                            .font(.headline)
                        Spacer()
                        Button("记录") { selectedTab = 2 }
                    }
                    ForEach(MealType.allCases) { type in
                        NavigationLink { MealLogView(initialMealType: type) } label: {
                            MealStatusRow(type: type, meal: store.meal(for: type))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 10) {
                    Label("今日训练", systemImage: "dumbbell.fill")
                        .font(.headline)
                    Text(store.todayPlan.title).font(.title3.bold())
                    Text(store.todayPlan.subtitle).foregroundStyle(.secondary)
                    if let cardio = store.todayPlan.cardio { Text(cardio).font(.subheadline).foregroundStyle(.green) }
                    Button("开始今天的训练") { selectedTab = 1 }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                }
                .cardStyle()
            }
            .padding()
        }
        .navigationTitle("练了吗")
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
            VStack(alignment: .leading, spacing: 8) {
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
            Text("\(value) / \(target) \(unit)").font(.subheadline.bold())
            ProgressView(value: min(Double(value) / Double(max(target, 1)), 1))
                .tint(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MealStatusRow: View {
    let type: MealType
    let meal: MealLog?

    var body: some View {
        HStack {
            Image(systemName: type.icon).frame(width: 24).foregroundStyle(.green)
            VStack(alignment: .leading) {
                Text(type.rawValue).foregroundStyle(.primary)
                Text(meal.map { "\($0.nutrition.calories) kcal · 蛋白质 \($0.nutrition.protein)g" } ?? "点击记录")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: meal == nil ? "plus.circle" : "checkmark.circle.fill").foregroundStyle(meal == nil ? .secondary : .green)
        }
    }
}

// MARK: - Meal logging

struct MealLogView: View {
    @EnvironmentObject private var store: FitnessStore
    @Environment(\.dismiss) private var dismiss
    @State private var mealType: MealType
    @State private var description = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var estimate: NutritionEstimate?
    @State private var isEstimating = false
    @State private var errorText: String?

    init(initialMealType: MealType) {
        _mealType = State(initialValue: initialMealType)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Picker("餐次", selection: $mealType) {
                    ForEach(MealType.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                Text(mealType == .breakfast ? "早餐吃了什么？" : "这餐吃了什么？")
                    .font(.title3.bold())
                Text("例如：两个煮鸡蛋、无糖豆浆 300ml、两片全麦面包。也可以直接粘贴盒饭菜单。")
                    .font(.subheadline).foregroundStyle(.secondary)

                TextEditor(text: $description)
                    .frame(minHeight: 120)
                    .padding(8)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary))

                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label(photoData == nil ? "添加餐食或菜单照片（可选）" : "已添加照片", systemImage: "photo")
                }
                .buttonStyle(.bordered)
                .onChange(of: photoItem) { _, item in
                    Task {
                        photoData = try? await item?.loadTransferable(type: Data.self)
                    }
                }

                Button {
                    estimateMeal()
                } label: {
                    HStack {
                        if isEstimating { ProgressView().tint(.white) }
                        Text(store.canUseAI ? "AI 分析并估算" : "立即估算")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isEstimating)

                if let estimate {
                    NutritionCard(estimate: estimate)
                    Button("保存\(mealType.rawValue)记录") {
                        let meal = MealLog(type: mealType, description: description, nutrition: estimate, imageData: photoData)
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
                    Label("当前使用本地快速估算。到“我的 → AI 接口”配置后，可结合文字和图片复核。", systemImage: "info.circle")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("记录\(mealType.rawValue)")
    }

    private func estimateMeal() {
        isEstimating = true
        errorText = nil
        let localEstimate = FoodEstimator.estimate(text: description)
        guard store.canUseAI, let key = store.aiKey else {
            estimate = localEstimate
            isEstimating = false
            return
        }
        Task {
            do {
                estimate = try await AIService.refineMeal(text: description, imageData: photoData, configuration: store.aiConfiguration, apiKey: key)
            } catch {
                estimate = localEstimate
                errorText = "AI 分析失败，已保存本地估算：\(error.localizedDescription)"
            }
            isEstimating = false
        }
    }
}

struct NutritionCard: View {
    let estimate: NutritionEstimate

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("营养估算").font(.headline)
            HStack {
                NutritionValue(title: "能量", value: "\(estimate.calories)", unit: "kcal")
                NutritionValue(title: "蛋白质", value: "\(estimate.protein)", unit: "g")
                NutritionValue(title: "碳水", value: "\(estimate.carbs)", unit: "g")
                NutritionValue(title: "脂肪", value: "\(estimate.fat)", unit: "g")
            }
            Text(estimate.note).font(.footnote).foregroundStyle(.secondary)
            Text("可信度：\(Int(estimate.confidence * 100))%（估算值，不等同于称重计算）")
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

// MARK: - Workouts

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
            Section("本周安排") {
                ForEach(WorkoutPlan.weekly) { plan in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(plan.title)
                        Text(plan.subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("训练")
    }
}

private struct ExerciseDraft: Identifiable {
    let id = UUID()
    let name: String
    let target: String
    var weight = ""
    var reps = ""
    var completed = false
}

struct WorkoutSessionView: View {
    @EnvironmentObject private var store: FitnessStore
    @Environment(\.dismiss) private var dismiss
    let plan: WorkoutPlan
    @State private var drafts: [ExerciseDraft]
    @State private var note = ""

    init(plan: WorkoutPlan) {
        self.plan = plan
        _drafts = State(initialValue: plan.exercises.map { ExerciseDraft(name: $0.name, target: $0.target) })
    }

    var body: some View {
        List {
            if let cardio = plan.cardio {
                Section("有氧") { Label(cardio, systemImage: "figure.walk") }
            }
            if drafts.isEmpty {
                Section { Text("今天以轻松走路或休息为主。") }
            } else {
                Section("力量动作") {
                    ForEach($drafts) { $draft in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(draft.name).font(.headline)
                                Spacer()
                                Toggle("完成", isOn: $draft.completed).labelsHidden()
                            }
                            Text(draft.target).font(.caption).foregroundStyle(.secondary)
                            HStack {
                                TextField("重量 kg", text: $draft.weight).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                                TextField("最佳次数", text: $draft.reps).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            Section("训练备注") { TextField("例如：最后一组还能做2次", text: $note, axis: .vertical) }
            Section {
                Button("完成并保存训练") {
                    store.addSession(WorkoutSession(planTitle: plan.title, completedExerciseNames: drafts.filter(\.completed).map(\.name), note: note))
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(.green)
            }
        }
        .navigationTitle(plan.title)
    }
}

// MARK: - Progress

struct ProgressDashboardView: View {
    @EnvironmentObject private var store: FitnessStore
    @State private var showingWeight = false

    private var recentWeights: [WeightEntry] { store.weights.sorted { $0.date > $1.date }.prefix(14).map { $0 } }
    private var weeklyAverage: Double? {
        let items = recentWeights.prefix(7)
        guard !items.isEmpty else { return nil }
        return items.map(\.kilograms).reduce(0, +) / Double(items.count)
    }

    var body: some View {
        List {
            Section("当前进度") {
                LabeledContent("最新体重", value: store.currentWeight.map { String(format: "%.1f kg", $0) } ?? "未记录")
                LabeledContent("7 日平均", value: weeklyAverage.map { String(format: "%.1f kg", $0) } ?? "数据不足")
                LabeledContent("目标体重", value: String(format: "%.0f kg", store.profile.currentWeightGoal))
                Button("记录今天的体重和腰围") { showingWeight = true }
            }
            Section("最近记录") {
                if recentWeights.isEmpty {
                    Text("从明天晨起开始记录体重。")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(recentWeights) { entry in
                        HStack {
                            Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                            Spacer()
                            Text(String(format: "%.1f kg", entry.kilograms)).bold()
                            if let waist = entry.waistCentimeters { Text(String(format: "腰围 %.0fcm", waist)).font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                }
            }
            Section("训练完成") {
                Text("本周已记录 \(store.sessions.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }.count) 次训练")
            }
        }
        .navigationTitle("进度")
        .sheet(isPresented: $showingWeight) { WeightEntryView() }
    }
}

struct WeightEntryView: View {
    @EnvironmentObject private var store: FitnessStore
    @Environment(\.dismiss) private var dismiss
    @State private var weight = ""
    @State private var waist = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("今天的身体数据") {
                    TextField("体重（kg）", text: $weight).keyboardType(.decimalPad)
                    TextField("腰围（cm，可选）", text: $waist).keyboardType(.decimalPad)
                }
                Section { Text("晨起、上厕所后、进食饮水前称重。看 7 日平均，不因单日波动焦虑。") .font(.footnote).foregroundStyle(.secondary) }
            }
            .navigationTitle("记录体重")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let value = Double(weight) else { return }
                        store.addWeight(kilograms: value, waist: Double(waist))
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Settings

struct SettingsView: View {
    @EnvironmentObject private var store: FitnessStore
    @State private var endpoint = ""
    @State private var model = ""
    @State private var apiKey = ""
    @State private var reminders: [ReminderItem] = []
    @State private var message = ""

    var body: some View {
        Form {
            Section("每日目标") {
                Stepper("能量：\(store.profile.dailyCaloriesGoal) kcal", value: $store.profile.dailyCaloriesGoal, in: 1500...4000, step: 50)
                Stepper("蛋白质：\(store.profile.dailyProteinGoal) g", value: $store.profile.dailyProteinGoal, in: 80...220, step: 5)
                Stepper("步数：\(store.profile.dailyStepsGoal)", value: $store.profile.dailyStepsGoal, in: 3000...15000, step: 500)
            }
            Section("AI 接口") {
                TextField("完整 Chat Completions 地址", text: $endpoint).textInputAutocapitalization(.never).keyboardType(.URL)
                TextField("模型名称", text: $model).textInputAutocapitalization(.never)
                SecureField("API Key（留空则保留旧 Key）", text: $apiKey).textInputAutocapitalization(.never)
                Button("保存 AI 配置") {
                    store.configureAI(endpoint: endpoint, model: model, apiKey: apiKey)
                    apiKey = ""
                    message = store.canUseAI ? "已保存。餐食记录将优先使用 AI 估算。" : "已保存接口信息；请确认地址、模型和 Key。"
                }
                Text("开发版将 Key 存在本机 Keychain。发布版必须改为服务端代理，不能将共享 Key 放进 App。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("自定义提醒") {
                ForEach($reminders) { $reminder in
                    ReminderEditor(reminder: $reminder)
                }
                Button("保存并更新提醒") {
                    store.reminders = reminders
                    Task {
                        do {
                            try await NotificationManager.requestAndSchedule(reminders)
                            message = "提醒已更新。"
                        } catch {
                            message = "无法开启提醒：\(error.localizedDescription)"
                        }
                    }
                }
            }
            if !message.isEmpty { Section { Text(message).font(.footnote).foregroundStyle(.secondary) } }
        }
        .navigationTitle("我的")
        .onAppear {
            endpoint = store.aiConfiguration.endpoint
            model = store.aiConfiguration.model
            reminders = store.reminders
        }
    }
}

struct ReminderEditor: View {
    @Binding var reminder: ReminderItem

    var body: some View {
        VStack(alignment: .leading) {
            Toggle(reminder.title, isOn: $reminder.enabled)
            DatePicker("时间", selection: Binding(get: { reminder.date }, set: { reminder.setTime($0) }), displayedComponents: .hourAndMinute)
                .labelsHidden()
                .disabled(!reminder.enabled)
        }
        .padding(.vertical, 4)
    }
}

extension View {
    func cardStyle() -> some View {
        padding(14)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
