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

enum FitnessGoal: String, Codable, CaseIterable, Identifiable {
    case fatLoss = "减脂"
    case maintain = "维持"
    case muscleGain = "增肌"

    var id: String { rawValue }

    var calorieAdjustment: Double {
        switch self {
        case .fatLoss: return -0.15
        case .maintain: return 0
        case .muscleGain: return 0.10
        }
    }

    var proteinPerKilogram: Double {
        switch self {
        case .fatLoss: return 1.8
        case .maintain: return 1.6
        case .muscleGain: return 1.8
        }
    }
}

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case sedentary = "久坐，日常走动较少"
    case light = "轻度活动，每周训练 1–2 次"
    case moderate = "中等活动，每周训练 3–5 次"
    case high = "高活动量，每周训练 6 次以上"

    var id: String { rawValue }

    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .high: return 1.725
        }
    }
}

enum TrainingExperience: String, Codable, CaseIterable, Identifiable {
    case beginner = "新手（规律训练少于 6 个月）"
    case intermediate = "有基础（能稳定完成常见动作）"
    case experienced = "进阶（有明确训练记录）"

    var id: String { rawValue }
}

enum EquipmentAccess: String, Codable, CaseIterable, Identifiable {
    case gym = "健身房器械齐全"
    case basicHome = "家用哑铃/弹力带"
    case bodyweight = "徒手为主"

    var id: String { rawValue }
}

struct NutritionTargets {
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let sourceText: String
}

struct FitnessProfile: Codable {
    var heightCentimeters = 185.0
    var age = 23
    var sex: BiologicalSex = .male
    var startingWeight = 100.0
    var currentWeightGoal = 75.0
    var fitnessGoal: FitnessGoal = .fatLoss
    var activityLevel: ActivityLevel = .moderate
    var trainingExperience: TrainingExperience = .beginner
    var equipmentAccess: EquipmentAccess = .gym
    var trainingDaysPerWeek = 5
    var preferredSessionMinutes = 60
    var posturePriority = true
    var usesRecommendedNutrition = true
    var onboardingCompleted = false
    var dailyCaloriesGoal = 2200
    var dailyProteinGoal = 150
    var dailyStepsGoal = 8000
    var dailyWaterGoal = 8

    init() {}

    private enum CodingKeys: String, CodingKey {
        case heightCentimeters, age, sex, startingWeight, currentWeightGoal
        case fitnessGoal, activityLevel, trainingExperience, equipmentAccess
        case trainingDaysPerWeek, preferredSessionMinutes, posturePriority
        case usesRecommendedNutrition, onboardingCompleted
        case dailyCaloriesGoal, dailyProteinGoal, dailyStepsGoal, dailyWaterGoal
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = FitnessProfile()
        heightCentimeters = try container.decodeIfPresent(Double.self, forKey: .heightCentimeters) ?? defaults.heightCentimeters
        age = try container.decodeIfPresent(Int.self, forKey: .age) ?? defaults.age
        sex = try container.decodeIfPresent(BiologicalSex.self, forKey: .sex) ?? defaults.sex
        startingWeight = try container.decodeIfPresent(Double.self, forKey: .startingWeight) ?? defaults.startingWeight
        currentWeightGoal = try container.decodeIfPresent(Double.self, forKey: .currentWeightGoal) ?? defaults.currentWeightGoal
        fitnessGoal = try container.decodeIfPresent(FitnessGoal.self, forKey: .fitnessGoal) ?? defaults.fitnessGoal
        activityLevel = try container.decodeIfPresent(ActivityLevel.self, forKey: .activityLevel) ?? defaults.activityLevel
        trainingExperience = try container.decodeIfPresent(TrainingExperience.self, forKey: .trainingExperience) ?? defaults.trainingExperience
        equipmentAccess = try container.decodeIfPresent(EquipmentAccess.self, forKey: .equipmentAccess) ?? defaults.equipmentAccess
        trainingDaysPerWeek = try container.decodeIfPresent(Int.self, forKey: .trainingDaysPerWeek) ?? defaults.trainingDaysPerWeek
        preferredSessionMinutes = try container.decodeIfPresent(Int.self, forKey: .preferredSessionMinutes) ?? defaults.preferredSessionMinutes
        posturePriority = try container.decodeIfPresent(Bool.self, forKey: .posturePriority) ?? defaults.posturePriority
        usesRecommendedNutrition = try container.decodeIfPresent(Bool.self, forKey: .usesRecommendedNutrition) ?? defaults.usesRecommendedNutrition
        onboardingCompleted = try container.decodeIfPresent(Bool.self, forKey: .onboardingCompleted) ?? defaults.onboardingCompleted
        dailyCaloriesGoal = try container.decodeIfPresent(Int.self, forKey: .dailyCaloriesGoal) ?? defaults.dailyCaloriesGoal
        dailyProteinGoal = try container.decodeIfPresent(Int.self, forKey: .dailyProteinGoal) ?? defaults.dailyProteinGoal
        dailyStepsGoal = try container.decodeIfPresent(Int.self, forKey: .dailyStepsGoal) ?? defaults.dailyStepsGoal
        dailyWaterGoal = try container.decodeIfPresent(Int.self, forKey: .dailyWaterGoal) ?? defaults.dailyWaterGoal
    }

    func recommendedNutrition(for weight: Double) -> NutritionTargets {
        let mass = max(weight, 40)
        let sexConstant = sex == .male ? 5.0 : -161.0
        let bmr = (10 * mass) + (6.25 * heightCentimeters) - (5 * Double(age)) + sexConstant
        let maintenance = bmr * activityLevel.multiplier
        let minimumCalories = sex == .male ? 1500.0 : 1200.0
        let calories = Int((max(maintenance * (1 + fitnessGoal.calorieAdjustment), minimumCalories) / 50).rounded() * 50)
        let protein = Int((mass * fitnessGoal.proteinPerKilogram / 5).rounded() * 5)
        let fatPerKilogram = fitnessGoal == .fatLoss ? 0.7 : 0.8
        let fat = max(40, Int((mass * fatPerKilogram / 5).rounded() * 5))
        let carbs = max(80, Int((Double(calories - protein * 4 - fat * 9) / 4).rounded()))
        let source = "按 \(fitnessGoal.rawValue) · \(activityLevel.rawValue) · 当前体重计算"
        return NutritionTargets(calories: calories, protein: protein, carbs: carbs, fat: fat, sourceText: source)
    }
}
struct AIConfiguration: Codable {
    var endpoint = ""
    var model = ""
    var useImageAnalysis = true
    var showReasoning = true
    var customInstruction = ""

    init(endpoint: String = "", model: String = "", useImageAnalysis: Bool = true, showReasoning: Bool = true, customInstruction: String = "") {
        self.endpoint = endpoint
        self.model = model
        self.useImageAnalysis = useImageAnalysis
        self.showReasoning = showReasoning
        self.customInstruction = customInstruction
    }

    private enum CodingKeys: String, CodingKey {
        case endpoint, model, useImageAnalysis, showReasoning, customInstruction
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        endpoint = try container.decodeIfPresent(String.self, forKey: .endpoint) ?? ""
        model = try container.decodeIfPresent(String.self, forKey: .model) ?? ""
        useImageAnalysis = try container.decodeIfPresent(Bool.self, forKey: .useImageAnalysis) ?? true
        showReasoning = try container.decodeIfPresent(Bool.self, forKey: .showReasoning) ?? true
        customInstruction = try container.decodeIfPresent(String.self, forKey: .customInstruction) ?? ""
    }
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

extension WorkoutPlan {
    static func preferredTrainingWeekdays(for profile: FitnessProfile) -> [Int] {
        switch profile.trainingDaysPerWeek {
        case 1: return [3]
        case 2: return [2, 5]
        case 3: return [2, 4, 6]
        case 4: return [2, 3, 5, 6]
        default: return [2, 3, 4, 5, 6]
        }
    }

    static func recommendedWeekly(for profile: FitnessProfile) -> [WorkoutPlan] {
        let preferredDays = preferredTrainingWeekdays(for: profile)
        let restPlan = weekly.first(where: { $0.weekday == 1 }) ?? weekly[0]
        return (1...7).map { weekday in
            guard preferredDays.contains(weekday), var plan = weekly.first(where: { $0.weekday == weekday }) else {
                var rest = restPlan
                rest.id = "rest-\(weekday)"
                rest.weekday = weekday
                return rest
            }
            plan.id = "personal-\(weekday)"
            plan.subtitle = "\(profile.fitnessGoal.rawValue) · \(plan.subtitle)"
            if profile.posturePriority && (weekday == 3 || weekday == 5) {
                plan.subtitle = "体态优先 · \(plan.subtitle)"
            }
            if profile.trainingExperience == .beginner && !plan.exercises.isEmpty {
                plan.subtitle += " · 每组保留 2–3 次余力"
            }
            if profile.fitnessGoal == .muscleGain {
                plan.cardio = plan.exercises.isEmpty ? plan.cardio : "可选低强度有氧 10–15 分钟，优先完成力量训练"
            }
            return plan
        }
    }

    static func normalizedWeekly(_ proposedPlans: [WorkoutPlan], for profile: FitnessProfile) -> [WorkoutPlan] {
        let fallbackPlans = recommendedWeekly(for: profile)
        let validPlans = proposedPlans.filter { (1...7).contains($0.weekday) }
        guard validPlans.count == 7, Set(validPlans.map(\.weekday)).count == 7 else { return fallbackPlans }
        let allowedTrainingDays = Set(preferredTrainingWeekdays(for: profile))
        return (1...7).compactMap { weekday in
            let fallback = fallbackPlans.first(where: { $0.weekday == weekday })
            guard allowedTrainingDays.contains(weekday), let plan = validPlans.first(where: { $0.weekday == weekday }), !plan.exercises.isEmpty else {
                return fallback
            }
            return plan
        }
    }
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
    var cardioInclinePercent: Double? = nil
    var cardioSpeedKilometersPerHour: Double? = nil
    var estimatedCalories: Int? = nil
    var perceivedEffort: Int
    var note: String
    var durationMinutes: Int
}

enum WorkoutEnergy {
    static func estimate(bodyWeightKilograms: Double, totalMinutes: Int, cardioMinutes: Int, cardioSpeedKilometersPerHour: Double?, cardioInclinePercent: Double?, hasStrengthWork: Bool) -> Int {
        let safeWeight = max(40, bodyWeightKilograms)
        let safeDuration = max(1, totalMinutes)
        let safeCardio = min(max(0, cardioMinutes), safeDuration)
        let strengthMinutes = max(0, safeDuration - safeCardio)
        let strengthMET = hasStrengthWork ? 4.8 : 2.5
        let speed = cardioSpeedKilometersPerHour ?? 5.0
        let incline = cardioInclinePercent ?? 0
        let cardioMET = min(10.0, max(3.0, 3.0 + speed * 0.48 + incline * 0.09))
        let calories = safeWeight * (Double(strengthMinutes) / 60 * strengthMET + Double(safeCardio) / 60 * cardioMET)
        return Int(calories.rounded())
    }
}

struct ChatMessage: Codable, Identifiable {
    var id = UUID()
    var date = Date()
    var isUser: Bool
    var content: String
    var reasoning: String?
}

struct CoachMemory: Codable, Identifiable {
    var id = UUID()
    var createdAt = Date()
    var category: String
    var content: String
}

struct CoachCapability: Identifiable {
    let id: String
    let category: String
    let title: String
    let detail: String
    let actionName: String?

    static let all: [CoachCapability] = [
        CoachCapability(id: "read-profile", category: "读取与分析", title: "个人资料与目标", detail: "读取身高、体重、目标、训练经验、器械和体态重点。", actionName: nil),
        CoachCapability(id: "read-history", category: "读取与分析", title: "完整健身记录", detail: "读取近期饮食、营养、体重、打卡、训练记录和长期记忆。", actionName: nil),
        CoachCapability(id: "weekly-review", category: "读取与分析", title: "每周完成分析", detail: "比较计划与实际完成情况、营养均值和体重趋势。", actionName: nil),
        CoachCapability(id: "record-meal", category: "记录", title: "新增或修改饮食", detail: "估算并保存一餐的热量、蛋白质、碳水和脂肪。", actionName: "record_meal"),
        CoachCapability(id: "meal-photo", category: "读取与分析", title: "识别餐食照片", detail: "使用支持视觉的模型时，在 AI 教练中上传图片并估算营养。", actionName: nil),
        CoachCapability(id: "delete-meal", category: "记录", title: "删除饮食", detail: "按餐次删除今天的一条饮食记录。", actionName: "delete_meal"),
        CoachCapability(id: "record-workout", category: "记录", title: "记录训练", detail: "保存动作、时长、RPE、有氧坡度/速度和估算消耗。", actionName: "record_workout"),
        CoachCapability(id: "delete-workout", category: "记录", title: "撤销最近训练", detail: "删除最近一次训练记录。", actionName: "delete_latest_workout"),
        CoachCapability(id: "record-weight", category: "记录", title: "记录体重与腰围", detail: "新增或更新当天体重、腰围。", actionName: "record_weight"),
        CoachCapability(id: "delete-weight", category: "记录", title: "撤销最近体重", detail: "删除最近一条体重记录。", actionName: "delete_latest_weight"),
        CoachCapability(id: "checkin", category: "记录", title: "今日打卡", detail: "更新饮水、睡眠和手动步数。", actionName: "record_checkin"),
        CoachCapability(id: "profile", category: "目标与计划", title: "修改目标与训练条件", detail: "修改减脂/维持/增肌、目标体重、每周天数和单次时长。", actionName: "update_profile"),
        CoachCapability(id: "nutrition", category: "目标与计划", title: "修改营养目标", detail: "切换自动计算，或设置每日热量与蛋白质目标。", actionName: "update_nutrition_targets"),
        CoachCapability(id: "day-plan", category: "目标与计划", title: "修改某一天计划", detail: "结合完成率更换当天标题、动作、组次提示和有氧。", actionName: "update_day_plan"),
        CoachCapability(id: "week-plan", category: "目标与计划", title: "替换整周计划", detail: "结合近几周完成情况重排 7 天训练与恢复。", actionName: "replace_weekly_plan"),
        CoachCapability(id: "generate-plan", category: "目标与计划", title: "重新生成周计划", detail: "按当前资料调用 AI 生成新的 7 天计划。", actionName: "regenerate_weekly_plan"),
        CoachCapability(id: "reset-plan", category: "目标与计划", title: "恢复基础周计划", detail: "清除 AI 调整，恢复按个人资料生成的基础计划。", actionName: "reset_weekly_plan"),
        CoachCapability(id: "reminder-add", category: "提醒", title: "新增提醒", detail: "新增训练、饮食、称重或休息提醒。", actionName: "add_reminder"),
        CoachCapability(id: "reminder-update", category: "提醒", title: "修改提醒", detail: "按名称修改提醒内容和时间。", actionName: "update_reminder"),
        CoachCapability(id: "reminder-delete", category: "提醒", title: "删除提醒", detail: "按名称删除已有提醒。", actionName: "delete_reminder"),
        CoachCapability(id: "remember", category: "记忆", title: "记住长期信息", detail: "保存工作时间、休息日、饮食偏好、伤病限制和训练习惯。", actionName: "remember"),
        CoachCapability(id: "forget", category: "记忆", title: "忘记长期信息", detail: "按关键词删除不再正确的记忆。", actionName: "forget_memory")
    ]

    static var promptRegistry: String {
        all.compactMap { capability in
            capability.actionName.map { "\($0)：\(capability.title)（\(capability.detail)）" }
        }.joined(separator: "\n")
    }
}

enum CoachActionType: String, Decodable, Equatable {
    case recordMeal = "record_meal"
    case deleteMeal = "delete_meal"
    case recordWorkout = "record_workout"
    case deleteLatestWorkout = "delete_latest_workout"
    case recordWeight = "record_weight"
    case deleteLatestWeight = "delete_latest_weight"
    case recordCheckIn = "record_checkin"
    case updateProfile = "update_profile"
    case updateNutritionTargets = "update_nutrition_targets"
    case updateDayPlan = "update_day_plan"
    case replaceWeeklyPlan = "replace_weekly_plan"
    case regenerateWeeklyPlan = "regenerate_weekly_plan"
    case resetWeeklyPlan = "reset_weekly_plan"
    case addReminder = "add_reminder"
    case updateReminder = "update_reminder"
    case deleteReminder = "delete_reminder"
    case remember = "remember"
    case forgetMemory = "forget_memory"
}

struct CoachAction: Decodable, Identifiable {
    var id = UUID()
    let type: CoachActionType
    var mealType: String?
    var description: String?
    var calories: Int?
    var protein: Int?
    var carbs: Int?
    var fat: Int?
    var weightKilograms: Double?
    var waistCentimeters: Double?
    var waterGlasses: Int?
    var sleepHours: Double?
    var steps: Int?
    var workoutTitle: String?
    var workoutMinutes: Int?
    var cardioMinutes: Int?
    var cardioInclinePercent: Double?
    var cardioSpeedKilometersPerHour: Double?
    var effort: Int?
    var exercises: [String]?
    var fitnessGoal: String?
    var goalWeightKilograms: Double?
    var trainingDaysPerWeek: Int?
    var preferredSessionMinutes: Int?
    var useRecommendedNutrition: Bool?
    var dailyCaloriesGoal: Int?
    var dailyProteinGoal: Int?
    var weekday: Int?
    var dayPlan: WorkoutPlan?
    var weeklyPlans: [WorkoutPlan]?
    var reminderTitle: String?
    var reminderBody: String?
    var reminderHour: Int?
    var reminderMinute: Int?
    var memoryCategory: String?
    var memoryContent: String?
    var memoryKeyword: String?

    init(type: CoachActionType, weeklyPlans: [WorkoutPlan]? = nil) {
        self.type = type
        self.weeklyPlans = weeklyPlans
    }

    private enum CodingKeys: String, CodingKey {
        case type, mealType, description, calories, protein, carbs, fat
        case weightKilograms, waistCentimeters, waterGlasses, sleepHours, steps
        case workoutTitle, workoutMinutes, cardioMinutes, cardioInclinePercent
        case cardioSpeedKilometersPerHour, effort, exercises
        case fitnessGoal, goalWeightKilograms, trainingDaysPerWeek
        case preferredSessionMinutes, useRecommendedNutrition, dailyCaloriesGoal, dailyProteinGoal
        case weekday, dayPlan, weeklyPlans
        case reminderTitle, reminderBody, reminderHour, reminderMinute
        case memoryCategory, memoryContent, memoryKeyword
    }

    var title: String {
        switch type {
        case .recordMeal: return "记录饮食"
        case .deleteMeal: return "删除饮食"
        case .recordWorkout: return "记录训练"
        case .deleteLatestWorkout: return "撤销最近训练"
        case .recordWeight: return "记录体重"
        case .deleteLatestWeight: return "撤销最近体重"
        case .recordCheckIn: return "更新今日打卡"
        case .updateProfile: return "更新个人目标"
        case .updateNutritionTargets: return "更新营养目标"
        case .updateDayPlan: return "调整单日计划"
        case .replaceWeeklyPlan: return "替换整周计划"
        case .regenerateWeeklyPlan: return "生成新的周计划"
        case .resetWeeklyPlan: return "恢复基础周计划"
        case .addReminder: return "新增提醒"
        case .updateReminder: return "修改提醒"
        case .deleteReminder: return "删除提醒"
        case .remember: return "加入长期记忆"
        case .forgetMemory: return "删除长期记忆"
        }
    }

    var detail: String {
        switch type {
        case .recordMeal: return "\(description ?? "一餐") · \(calories ?? 0) kcal · 蛋白质 \(protein ?? 0)g"
        case .deleteMeal: return "删除今天的\(resolvedMealType.rawValue)记录"
        case .recordWorkout: return "\(workoutTitle ?? "今日训练") · \(workoutMinutes ?? 0) 分钟"
        case .deleteLatestWorkout: return "删除最近一次训练记录"
        case .recordWeight: return "\(weightKilograms.map { String(format: "%.1f", $0) } ?? "—") kg"
        case .deleteLatestWeight: return "删除最近一条体重记录"
        case .recordCheckIn: return "饮水 \(waterGlasses ?? 0) 杯 · 睡眠 \(sleepHours.map { String(format: "%.1f", $0) } ?? "—") 小时 · 步数 \(steps ?? 0)"
        case .updateProfile: return "目标 \(fitnessGoal ?? "保持不变") · 目标体重 \(goalWeightKilograms.map { String(format: "%.1f", $0) } ?? "保持不变") kg · 每周 \(trainingDaysPerWeek.map { String($0) } ?? "不变") 天 · 每次 \(preferredSessionMinutes.map { String($0) } ?? "不变") 分钟"
        case .updateNutritionTargets: return useRecommendedNutrition == true ? "改为按个人资料自动计算" : "每日 \(dailyCaloriesGoal ?? 0) kcal · 蛋白质 \(dailyProteinGoal ?? 0)g"
        case .updateDayPlan: return "周\(Self.chineseWeekday(weekday ?? dayPlan?.weekday ?? 1)) · \(dayPlan?.title ?? workoutTitle ?? "训练计划")"
        case .replaceWeeklyPlan: return "根据完成情况替换 7 天计划"
        case .regenerateWeeklyPlan: return "根据当前个人资料重新生成 7 天训练安排"
        case .resetWeeklyPlan: return "清除 AI 调整并恢复基础计划"
        case .addReminder: return "\(reminderTitle ?? "新提醒") · \(String(format: "%02d:%02d", reminderHour ?? 20, reminderMinute ?? 0))"
        case .updateReminder: return "修改“\(reminderTitle ?? "指定")”至 \(String(format: "%02d:%02d", reminderHour ?? 20, reminderMinute ?? 0))"
        case .deleteReminder: return "删除“\(reminderTitle ?? "指定")”提醒"
        case .remember: return "\(memoryCategory ?? "其他") · \(memoryContent ?? "")"
        case .forgetMemory: return "删除包含“\(memoryKeyword ?? "指定内容")”的记忆"
        }
    }

    private static func chineseWeekday(_ weekday: Int) -> String {
        ["日", "一", "二", "三", "四", "五", "六"][min(7, max(1, weekday)) - 1]
    }

    var isDestructive: Bool {
        switch type {
        case .deleteMeal, .deleteLatestWorkout, .deleteLatestWeight, .deleteReminder, .forgetMemory:
            return true
        default:
            return false
        }
    }

    var canAutoExecuteFromExplicitRequest: Bool {
        switch type {
        case .recordMeal, .recordWorkout, .recordWeight, .recordCheckIn, .remember:
            return true
        default:
            return false
        }
    }

    var planPreviewLines: [String] {
        let plans: [WorkoutPlan]
        if let weeklyPlans { plans = weeklyPlans.sorted { $0.weekday < $1.weekday } }
        else if let dayPlan { plans = [dayPlan] }
        else { return [] }
        return plans.map { plan in
            let content = plan.exercises.isEmpty ? "恢复" : plan.exercises.map(\.name).joined(separator: "、")
            return "周\(Self.chineseWeekday(plan.weekday))：\(plan.title) · \(content)"
        }
    }

    var resolvedMealType: MealType {
        switch mealType?.lowercased() {
        case "breakfast", "早餐": return .breakfast
        case "lunch", "午餐": return .lunch
        case "dinner", "晚餐": return .dinner
        default: return .snack
        }
    }
}

struct ParsedCoachReply {
    let reply: String
    let actions: [CoachAction]

    static func parse(_ raw: String) -> ParsedCoachReply {
        let open = "<gymcoach_actions>"
        let close = "</gymcoach_actions>"
        guard let start = raw.range(of: open), let end = raw.range(of: close, range: start.upperBound..<raw.endIndex) else {
            return ParsedCoachReply(reply: raw.trimmingCharacters(in: .whitespacesAndNewlines), actions: [])
        }
        let json = String(raw[start.upperBound..<end.lowerBound])
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let actions = (try? JSONDecoder().decode([CoachAction].self, from: Data(json.utf8))) ?? []
        let visible = (String(raw[..<start.lowerBound]) + String(raw[end.upperBound...])).trimmingCharacters(in: .whitespacesAndNewlines)
        return ParsedCoachReply(reply: visible, actions: actions)
    }

    static func visibleText(in raw: String) -> String {
        guard let start = raw.range(of: "<gymcoach_actions>") else { return raw }
        return String(raw[..<start.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Local storage

@MainActor
final class FitnessStore: ObservableObject {
    @Published private(set) var meals: [MealLog]
    @Published private(set) var weights: [WeightEntry]
    @Published private(set) var checkIns: [DailyCheckIn]
    @Published private(set) var sessions: [WorkoutSession]
    @Published private(set) var chatMessages: [ChatMessage]
    @Published private(set) var aiWorkoutPlans: [WorkoutPlan]
    @Published private(set) var coachMemories: [CoachMemory]
    @Published var profile: FitnessProfile { didSet { save(profile, key: Keys.profile) } }
    @Published var aiConfiguration: AIConfiguration { didSet { save(aiConfiguration, key: Keys.aiConfiguration) } }
    @Published var reminders: [ReminderItem] { didSet { save(reminders, key: Keys.reminders) } }

    private enum Keys {
        static let meals = "gymcoach.meals.v2"
        static let weights = "gymcoach.weights.v2"
        static let checkIns = "gymcoach.checkins.v2"
        static let sessions = "gymcoach.sessions.v2"
        static let chatMessages = "gymcoach.chat.v2"
        static let aiWorkoutPlans = "gymcoach.aiWorkoutPlans.v1"
        static let coachMemories = "gymcoach.coachMemories.v1"
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
        aiWorkoutPlans = Self.load([WorkoutPlan].self, key: Keys.aiWorkoutPlans) ?? []
        coachMemories = Self.load([CoachMemory].self, key: Keys.coachMemories) ?? []
        profile = Self.load(FitnessProfile.self, key: Keys.profile) ?? FitnessProfile()
        aiConfiguration = Self.load(AIConfiguration.self, key: Keys.aiConfiguration) ?? AIConfiguration()
        reminders = Self.load([ReminderItem].self, key: Keys.reminders) ?? ReminderItem.defaults
    }

    var weeklyPlans: [WorkoutPlan] {
        aiWorkoutPlans.count == 7 ? WorkoutPlan.normalizedWeekly(aiWorkoutPlans, for: profile) : WorkoutPlan.recommendedWeekly(for: profile)
    }

    var isUsingAIWorkoutPlan: Bool { aiWorkoutPlans.count == 7 }

    var todayPlan: WorkoutPlan {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return weeklyPlans.first(where: { $0.weekday == weekday }) ?? weeklyPlans[0]
    }

    var todayMeals: [MealLog] {
        meals.filter { Calendar.current.isDateInToday($0.date) }
    }

    var todayNutrition: NutritionEstimate {
        todayMeals.reduce(.empty) { $0.adding($1.nutrition) }
    }

    var nutritionTargets: NutritionTargets {
        if profile.usesRecommendedNutrition {
            return profile.recommendedNutrition(for: currentWeight ?? profile.startingWeight)
        }
        return NutritionTargets(
            calories: profile.dailyCaloriesGoal,
            protein: profile.dailyProteinGoal,
            carbs: max(80, Int(Double(profile.dailyCaloriesGoal - profile.dailyProteinGoal * 4 - 60 * 9) / 4)),
            fat: 60,
            sourceText: "使用手动设置的每日目标"
        )
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

    var completedDayStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        for offset in 0..<365 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { break }
            let hasCheckIn = checkIns.contains { calendar.isDate($0.date, inSameDayAs: date) }
            let hasWorkout = sessions.contains { calendar.isDate($0.date, inSameDayAs: date) }
            let mealCount = meals.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
            if hasCheckIn || hasWorkout || mealCount >= 2 {
                streak += 1
            } else {
                break
            }
        }
        return streak
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

    func saveSession(_ session: WorkoutSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.append(session)
        }
        sessions.sort { $0.date > $1.date }
        save(sessions, key: Keys.sessions)
    }

    func deleteLatestSession() {
        guard !sessions.isEmpty else { return }
        sessions.removeFirst()
        save(sessions, key: Keys.sessions)
    }

    func deleteLatestWeight() {
        guard !weights.isEmpty else { return }
        weights.removeFirst()
        save(weights, key: Keys.weights)
    }

    func resetPersonalizedWorkoutPlan() {
        aiWorkoutPlans = []
        save(aiWorkoutPlans, key: Keys.aiWorkoutPlans)
    }

    func saveAIWorkoutPlans(_ plans: [WorkoutPlan]) {
        guard plans.count == 7 else { return }
        aiWorkoutPlans = WorkoutPlan.normalizedWeekly(plans, for: profile)
        save(aiWorkoutPlans, key: Keys.aiWorkoutPlans)
    }

    func buildAIWorkoutPlan(adjustmentRequest: String? = nil) async throws -> [WorkoutPlan] {
        guard let apiKey = aiKey else { throw AIService.AIError.requestFailed("请先在设置中保存 AI API Key。") }
        let request = adjustmentRequest?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let context = request.isEmpty ? workoutPlanContext : "\(workoutPlanContext)\n用户本次调整要求（必须体现在新计划中）：\(request)"
        return try await AIService.generateWeeklyPlan(
            profile: profile,
            currentWeight: currentWeight ?? profile.startingWeight,
            adaptationContext: context,
            configuration: aiConfiguration,
            apiKey: apiKey,
            adjustmentRequest: request.isEmpty ? nil : request
        )
    }

    func generateAIWorkoutPlan() async throws {
        let plans = try await buildAIWorkoutPlan()
        saveAIWorkoutPlans(plans)
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

    func appendChat(isUser: Bool, content: String, reasoning: String? = nil) {
        let compactReasoning = reasoning?.trimmingCharacters(in: .whitespacesAndNewlines)
        chatMessages.append(ChatMessage(isUser: isUser, content: content, reasoning: compactReasoning?.isEmpty == true ? nil : compactReasoning))
        chatMessages = Array(chatMessages.suffix(60))
        save(chatMessages, key: Keys.chatMessages)
    }

    func clearChat() {
        chatMessages = []
        save(chatMessages, key: Keys.chatMessages)
    }

    func addMemory(category: String, content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        coachMemories.removeAll { $0.content.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }
        coachMemories.insert(CoachMemory(category: category.isEmpty ? "其他" : category, content: trimmed), at: 0)
        coachMemories = Array(coachMemories.prefix(60))
        save(coachMemories, key: Keys.coachMemories)
    }

    func deleteMemory(_ memory: CoachMemory) {
        coachMemories.removeAll { $0.id == memory.id }
        save(coachMemories, key: Keys.coachMemories)
    }

    func deleteMemories(matching keyword: String) -> Int {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }
        let oldCount = coachMemories.count
        coachMemories.removeAll {
            $0.content.localizedCaseInsensitiveContains(trimmed) || $0.category.localizedCaseInsensitiveContains(trimmed)
        }
        save(coachMemories, key: Keys.coachMemories)
        return oldCount - coachMemories.count
    }

    private var recentConversationContext: String {
        let recent = chatMessages.suffix(6)
        guard !recent.isEmpty else { return "无" }
        return recent.map {
            let compact = String($0.content.prefix(400))
            return "\($0.isUser ? "用户" : "教练")：\(compact)"
        }.joined(separator: "\n")
    }

    private var memoryContext: String {
        guard !coachMemories.isEmpty else { return "暂无长期记忆" }
        return coachMemories.prefix(15).map { "[\($0.category)] \(String($0.content.prefix(240)))" }.joined(separator: "；")
    }

    private var planContext: String {
        let dayNames = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        return weeklyPlans.sorted { $0.weekday < $1.weekday }.map { plan in
            let exercises = plan.exercises.isEmpty ? "恢复" : plan.exercises.map { "\($0.name) \($0.target)" }.joined(separator: "、")
            return "\(dayNames[plan.weekday - 1]) \(plan.title)：\(exercises)；有氧：\(plan.cardio ?? "无")"
        }.joined(separator: "\n")
    }

    private var trainingAdherenceContext: String {
        guard !sessions.isEmpty else {
            return "暂无训练日志，属于数据不足，不能据此判断完成率低；请按个人资料和用户明确要求正常制定计划。"
        }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayNames = ["日", "一", "二", "三", "四", "五", "六"]
        return (0..<4).compactMap { weeksAgo -> String? in
            guard let reference = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: today),
                  let interval = calendar.dateInterval(of: .weekOfYear, for: reference) else { return nil }
            var due = 0
            var completed = 0
            var daily: [String] = []
            for offset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: offset, to: interval.start), date <= today else { continue }
                let weekday = calendar.component(.weekday, from: date)
                guard let plan = weeklyPlans.first(where: { $0.weekday == weekday }), !plan.exercises.isEmpty else { continue }
                due += 1
                let done = sessions.contains { calendar.isDate($0.date, inSameDayAs: date) }
                if done { completed += 1 }
                daily.append("周\(dayNames[weekday - 1])\(done ? "✓" : "未完成")")
            }
            let rate = due == 0 ? 0 : Int((Double(completed) / Double(due) * 100).rounded())
            return "\(weeksAgo == 0 ? "本周" : "前\(weeksAgo)周")：到目前应完成 \(due) 次，实际 \(completed) 次，完成率 \(rate)%（\(daily.joined(separator: "、"))）"
        }.joined(separator: "\n")
    }

    private var recentTrendContext: String {
        let calendar = Calendar.current
        let today = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let recentMeals = meals.filter { $0.date >= calendar.startOfDay(for: sevenDaysAgo) }
        let grouped = Dictionary(grouping: recentMeals) { calendar.startOfDay(for: $0.date) }
        let dayTotals = grouped.values.map { $0.reduce(NutritionEstimate.empty) { $0.adding($1.nutrition) } }
        let nutritionText: String
        if dayTotals.isEmpty {
            nutritionText = "近 7 天无饮食记录"
        } else {
            let count = dayTotals.count
            let calories = dayTotals.map(\.calories).reduce(0, +) / count
            let protein = dayTotals.map(\.protein).reduce(0, +) / count
            nutritionText = "近 7 天有 \(count) 天记录饮食，记录日均 \(calories) kcal、蛋白质 \(protein)g"
        }
        let monthAgo = calendar.date(byAdding: .day, value: -28, to: today) ?? today
        let recentWeights = weights.filter { $0.date >= monthAgo }.sorted { $0.date < $1.date }
        let weightText: String
        if let first = recentWeights.first, let last = recentWeights.last, recentWeights.count >= 2 {
            weightText = "近 28 天体重 \(String(format: "%.1f", first.kilograms)) → \(String(format: "%.1f", last.kilograms)) kg（变化 \(String(format: "%+.1f", last.kilograms - first.kilograms)) kg）"
        } else {
            weightText = "近 28 天体重趋势数据不足"
        }
        return "\(nutritionText)；\(weightText)"
    }

    var coachContext: String {
        let nutrition = todayNutrition
        let targets = nutritionTargets
        let weightText = currentWeight.map { String(format: "%.1f", $0) } ?? "未记录"
        let mealsText = todayMeals.isEmpty ? "无" : todayMeals.map { "\($0.type.rawValue)：\($0.description)（\($0.nutrition.calories)kcal，蛋白质\($0.nutrition.protein)g）" }.joined(separator: "；")
        let checkIn = todayCheckIn
        return """
        用户资料：\(profile.age) 岁\(profile.sex.rawValue)，身高 \(Int(profile.heightCentimeters))cm，当前体重 \(weightText)kg，目标 \(profile.fitnessGoal.rawValue)，目标体重 \(String(format: "%.1f", profile.currentWeightGoal))kg。每周训练 \(profile.trainingDaysPerWeek) 天，每次约 \(profile.preferredSessionMinutes) 分钟，\(profile.trainingExperience.rawValue)，器械：\(profile.equipmentAccess.rawValue)，体态优先：\(profile.posturePriority ? "是" : "否")。
        长期记忆：\(memoryContext)
        今日饮食：\(mealsText)。今日营养：\(nutrition.calories)/\(targets.calories) kcal，蛋白质 \(nutrition.protein)/\(targets.protein)g，碳水 \(nutrition.carbs)/\(targets.carbs)g，脂肪 \(nutrition.fat)/\(targets.fat)g。
        今日打卡：饮水 \(checkIn.waterGlasses) 杯，睡眠 \(checkIn.sleepHours.map { String(format: "%.1f", $0) } ?? "未记") 小时，步数 \(checkIn.steps.map { String($0) } ?? "未记")。
        当前整周计划：
        \(planContext)
        近 4 周训练执行：
        \(trainingAdherenceContext)
        近期趋势：\(recentTrendContext)
        最近对话：
        \(recentConversationContext)
        """
    }

    private var workoutPlanContext: String {
        """
        长期记忆：\(memoryContext)
        当前整周计划：
        \(planContext)
        近 4 周训练执行：
        \(trainingAdherenceContext)
        近期趋势：\(recentTrendContext)
        """
    }

    func applyCoachAction(_ action: CoachAction) async throws {
        switch action.type {
        case .recordMeal:
            guard let calories = action.calories, let protein = action.protein, let carbs = action.carbs, let fat = action.fat, calories > 0, protein >= 0, carbs >= 0, fat >= 0 else { throw AIService.AIError.requestFailed("AI 没有给出完整的营养数据，请补充食物和大概份量后再试。") }
            upsertMeal(MealLog(type: action.resolvedMealType, description: action.description ?? "AI 记录的一餐", nutrition: NutritionEstimate(calories: calories, protein: protein, carbs: carbs, fat: fat, confidence: 0.65, note: "由 AI 教练根据对话估算，请按实际份量复核。"), imageData: nil, source: .ai))
        case .deleteMeal:
            guard let meal = meal(for: action.resolvedMealType) else { throw AIService.AIError.requestFailed("今天没有这条餐次记录。") }
            deleteMeal(meal)
        case .recordWorkout:
            let plan = todayPlan
            let completedNames = action.exercises ?? []
            let logs = completedNames.map { name in
                let matched = plan.exercises.first(where: { $0.name.localizedCaseInsensitiveContains(name) || name.localizedCaseInsensitiveContains($0.name) })
                return WorkoutExerciseLog(exerciseName: name, target: matched?.target ?? "已完成", sets: 0, loadKilograms: nil, reps: nil, completed: true)
            }
            let duration = max(1, action.workoutMinutes ?? profile.preferredSessionMinutes)
            let cardio = max(0, action.cardioMinutes ?? 0)
            let estimated = WorkoutEnergy.estimate(bodyWeightKilograms: currentWeight ?? profile.startingWeight, totalMinutes: duration, cardioMinutes: cardio, cardioSpeedKilometersPerHour: action.cardioSpeedKilometersPerHour, cardioInclinePercent: action.cardioInclinePercent, hasStrengthWork: !logs.isEmpty)
            let incline = action.cardioInclinePercent.map { "，坡度 \(String(format: "%.1f", $0))%" } ?? ""
            let speed = action.cardioSpeedKilometersPerHour.map { "，速度 \(String(format: "%.1f", $0)) km/h" } ?? ""
            let cardioNote = cardio > 0 ? "有氧 \(cardio) 分钟\(incline)\(speed)。" : ""
            addSession(WorkoutSession(planID: plan.id, planTitle: action.workoutTitle ?? plan.title, exercises: logs, cardioMinutes: cardio, cardioInclinePercent: action.cardioInclinePercent, cardioSpeedKilometersPerHour: action.cardioSpeedKilometersPerHour, estimatedCalories: estimated, perceivedEffort: min(10, max(1, action.effort ?? 7)), note: "AI 对话记录。\(cardioNote)\(action.description ?? "")", durationMinutes: duration))
        case .deleteLatestWorkout:
            guard !sessions.isEmpty else { throw AIService.AIError.requestFailed("还没有训练记录可以删除。") }
            deleteLatestSession()
        case .recordWeight:
            guard let weight = action.weightKilograms, weight > 25, weight < 350 else { throw AIService.AIError.requestFailed("AI 没有识别到有效体重，请按“体重 87kg”这样补充。") }
            addWeight(kilograms: weight, waist: action.waistCentimeters)
        case .deleteLatestWeight:
            guard !weights.isEmpty else { throw AIService.AIError.requestFailed("还没有体重记录可以删除。") }
            deleteLatestWeight()
        case .recordCheckIn:
            let current = todayCheckIn
            updateTodayCheckIn(water: max(0, action.waterGlasses ?? current.waterGlasses), sleepHours: action.sleepHours ?? current.sleepHours, steps: action.steps ?? current.steps)
        case .updateProfile:
            if let rawGoal = action.fitnessGoal { profile.fitnessGoal = FitnessGoal.allCases.first(where: { $0.rawValue == rawGoal }) ?? profile.fitnessGoal }
            if let weight = action.goalWeightKilograms, weight > 25, weight < 350 { profile.currentWeightGoal = weight }
            if let days = action.trainingDaysPerWeek { profile.trainingDaysPerWeek = min(6, max(1, days)) }
            if let minutes = action.preferredSessionMinutes { profile.preferredSessionMinutes = min(180, max(20, minutes)) }
        case .updateNutritionTargets:
            if action.useRecommendedNutrition == true {
                profile.usesRecommendedNutrition = true
            } else {
                guard let calories = action.dailyCaloriesGoal, let protein = action.dailyProteinGoal,
                      (1200...5000).contains(calories), (40...350).contains(protein) else {
                    throw AIService.AIError.requestFailed("营养目标不完整或超出合理录入范围。")
                }
                profile.usesRecommendedNutrition = false
                profile.dailyCaloriesGoal = calories
                profile.dailyProteinGoal = protein
            }
        case .updateDayPlan:
            guard var plan = action.dayPlan else { throw AIService.AIError.requestFailed("AI 没有返回完整的单日训练计划。") }
            let targetWeekday = min(7, max(1, action.weekday ?? plan.weekday))
            plan.weekday = targetWeekday
            plan.id = "ai-adjusted-\(targetWeekday)-\(Int(Date().timeIntervalSince1970))"
            var plans = weeklyPlans
            plans.removeAll { $0.weekday == targetWeekday }
            plans.append(plan)
            saveAIWorkoutPlans(plans)
        case .replaceWeeklyPlan:
            guard let plans = action.weeklyPlans, plans.count == 7, Set(plans.map(\.weekday)).count == 7 else {
                throw AIService.AIError.requestFailed("AI 返回的整周计划不完整。")
            }
            if let days = action.trainingDaysPerWeek { profile.trainingDaysPerWeek = min(6, max(1, days)) }
            saveAIWorkoutPlans(plans)
        case .regenerateWeeklyPlan:
            try await generateAIWorkoutPlan()
        case .resetWeeklyPlan:
            resetPersonalizedWorkoutPlan()
        case .addReminder:
            guard let title = action.reminderTitle?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else {
                throw AIService.AIError.requestFailed("提醒名称不能为空。")
            }
            let hour = min(23, max(0, action.reminderHour ?? 20))
            let minute = min(59, max(0, action.reminderMinute ?? 0))
            var updated = reminders
            updated.append(ReminderItem(title: title, body: action.reminderBody ?? "来自 AI 教练的提醒", hour: hour, minute: minute, enabled: true))
            try await NotificationManager.requestAndSchedule(updated)
            reminders = updated
        case .updateReminder:
            guard let title = action.reminderTitle?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty,
                  let index = reminders.firstIndex(where: { $0.title.localizedCaseInsensitiveContains(title) }) else {
                throw AIService.AIError.requestFailed("没有找到要修改的提醒。")
            }
            var updated = reminders
            if let body = action.reminderBody { updated[index].body = body }
            if let hour = action.reminderHour { updated[index].hour = min(23, max(0, hour)) }
            if let minute = action.reminderMinute { updated[index].minute = min(59, max(0, minute)) }
            try await NotificationManager.requestAndSchedule(updated)
            reminders = updated
        case .deleteReminder:
            guard let title = action.reminderTitle?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else {
                throw AIService.AIError.requestFailed("请说明要删除哪个提醒。")
            }
            var updated = reminders
            updated.removeAll { $0.title.localizedCaseInsensitiveContains(title) }
            guard updated.count != reminders.count else { throw AIService.AIError.requestFailed("没有找到名称包含“\(title)”的提醒。") }
            try await NotificationManager.requestAndSchedule(updated)
            reminders = updated
        case .remember:
            guard let content = action.memoryContent else { throw AIService.AIError.requestFailed("没有可保存的记忆内容。") }
            addMemory(category: action.memoryCategory ?? "其他", content: content)
        case .forgetMemory:
            guard let keyword = action.memoryKeyword, deleteMemories(matching: keyword) > 0 else {
                throw AIService.AIError.requestFailed("没有找到匹配的长期记忆。")
            }
        }
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
    private struct GeneratedPlanResponse: Decodable {
        let weeklyPlans: [WorkoutPlan]
    }

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
            systemPrompt: "只输出符合要求的 JSON。不要提供药物剂量、诊断或医疗建议。",
            maxTokens: 1800,
            jsonMode: true
        )
        let json = extractJSON(from: response)
        guard let data = json.data(using: .utf8) else { throw AIError.unreadableResponse }
        return try JSONDecoder().decode(NutritionEstimate.self, from: data)
    }

    static func coachReplyStream(
        question: String,
        context: String,
        imageData: Data?,
        configuration: AIConfiguration,
        apiKey: String,
        onReasoning: @escaping @MainActor (String) -> Void,
        onDelta: @escaping @MainActor (String) -> Void
    ) async throws {
        let actionProtocol = """
        你能读取用户资料、长期记忆、最近对话、饮食与营养、体重趋势、打卡、完整周计划和近 4 周训练完成率。请按整句话和最近对话理解用户意图，不依赖固定关键词；也要理解“都记上”“就这样改”等省略表达。若用户明确报告了新记录，或明确要求修改 App 数据，请在正常中文回复的最后另起一行输出唯一的机器指令：
        <gymcoach_actions>[{...}]</gymcoach_actions>
        可调用功能：
        \(CoachCapability.promptRegistry)

        参数规则：
        - record_meal/delete_meal：mealType 使用 breakfast/lunch/dinner/snack；记录还需 description、calories、protein、carbs、fat。
        - record_workout：workoutTitle、workoutMinutes、cardioMinutes、cardioInclinePercent、cardioSpeedKilometersPerHour、effort、exercises、description。
        - record_weight：weightKilograms，可选 waistCentimeters。record_checkin：waterGlasses、sleepHours、steps。
        - update_profile：fitnessGoal 仅为减脂/维持/增肌，可选 goalWeightKilograms、trainingDaysPerWeek、preferredSessionMinutes。
        - update_nutrition_targets：自动计算用 useRecommendedNutrition=true；手动目标用 false 并同时提供 dailyCaloriesGoal、dailyProteinGoal。
        - update_day_plan：提供 weekday 1...7 和完整 dayPlan，dayPlan 格式为 {"id":"adjusted","weekday":2,"title":"标题","subtitle":"调整原因","exercises":[{"name":"动作","target":"组数 × 次数","cue":"提示"}],"cardio":"有氧或 null"}。
        - replace_weekly_plan：提供 weeklyPlans，必须恰好有 weekday 1...7 七项，单项格式同 dayPlan；如改变训练频率，同时提供 trainingDaysPerWeek。要遵守用户可训练日期；恢复日 exercises=[]。reset_weekly_plan 无参数。
        - add_reminder：reminderTitle、reminderBody、reminderHour、reminderMinute。update_reminder 用 reminderTitle 定位并提供要改的内容/时间。delete_reminder：reminderTitle。
        - remember：memoryCategory（训练偏好/饮食偏好/时间安排/身体限制/其他）和 memoryContent。forget_memory：memoryKeyword。

        一句话包含多条独立记录时必须输出多个 action。例如用户一次补报早餐、午餐和晚餐，应分别生成 3 个 record_meal 并按常见份量估算；用户只是在询问吃什么时不要记录。
        当用户说“记住……”或透露稳定且未来有用的偏好、时间安排、器械限制或身体限制时，可以提出 remember；临时状态不要长期记忆。当用户要求根据执行情况调整计划时，必须先引用近 4 周完成率和近期趋势，再输出 update_day_plan 或 replace_weekly_plan，不能只给口头建议。不要因为一次漏练就补偿性加量；完成率持续偏低时优先减少动作/天数或缩短时长，持续完成且恢复良好时才小幅进阶。
        只有把握用户是在“陈述事实”或“明确要求修改”时才输出指令。明确新增的饮食、训练、体重、打卡和长期记忆会由 App 解析后直接执行；删除、目标、提醒和训练计划变更需用户在 App 内确认。你只能说“准备记录/准备修改”，只有 App 返回的执行结果消息才能说“已实际写入”。估算数值时说明是估算。普通问答、医疗和药物相关对话不要输出指令。
        """
        let prompt = """
        你是用户的中文健身教练。给出务实、简短、可执行的减脂与训练建议；不提供药物剂量、疾病诊断或替代医生意见。
        当前数据：\(context)
        用户问题：\(question)
        """
        let custom = configuration.customInstruction.trimmingCharacters(in: .whitespacesAndNewlines)
        let system = "用中文回答，先给结论，再给不超过 3 条行动建议。\n\n\(actionProtocol)\(custom.isEmpty ? "" : "\n\n用户额外偏好：\(custom)")"
        try await stream(prompt: prompt, imageData: configuration.useImageAnalysis ? imageData : nil, configuration: configuration, apiKey: apiKey, systemPrompt: system, onReasoning: onReasoning, onDelta: onDelta)
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

    static func generateWeeklyPlan(profile: FitnessProfile, currentWeight: Double, adaptationContext: String, configuration: AIConfiguration, apiKey: String, adjustmentRequest: String? = nil) async throws -> [WorkoutPlan] {
        let priorityRequest = adjustmentRequest?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let prompt = """
        你是谨慎的中文私教。基于以下个人资料生成 7 天训练安排：
         年龄：\(profile.age)，性别：\(profile.sex.rawValue)，身高：\(Int(profile.heightCentimeters))cm，体重：\(String(format: "%.1f", currentWeight))kg，目标：\(profile.fitnessGoal.rawValue)，每周训练：\(profile.trainingDaysPerWeek) 天，每次：\(profile.preferredSessionMinutes) 分钟，经验：\(profile.trainingExperience.rawValue)，器械：\(profile.equipmentAccess.rawValue)，体态关注：\(profile.posturePriority ? "前倾/圆肩" : "无")。
        \(priorityRequest.isEmpty ? "本次没有额外修改要求。" : "本次最高优先级修改要求：\(priorityRequest)")
        长期记忆、当前计划与执行情况：
        \(adaptationContext)
        输出严格 JSON，不要 Markdown，不要解释。格式必须是：
        {"weeklyPlans":[{"id":"day-1","weekday":1,"title":"中文标题","subtitle":"一句重点","exercises":[{"name":"动作名","target":"组数 × 次数","cue":"简短动作提示"}],"cardio":"可选有氧或 null"}]}
        weekday 映射固定为：1=周日、2=周一、3=周二、4=周三、5=周四、6=周五、7=周六。必须恰好包含 weekday 1 到 7 各一天，每个训练日 4–6 个动作，提示保持简短。非训练日 exercises 为空数组。用户当前每周训练 \(profile.trainingDaysPerWeek) 天；当为 5 天时，必须把周一至周五（weekday 2–6）排为训练日，周六、周日（weekday 7、1）均为恢复日，不能把两个休息日拆开。用户本次明确提出的调整必须落实到结果中；除非要求明显危险或违反身体限制，不得只评价、劝退或拒绝生成。训练日志为空代表数据不足，不代表完成率低。确有低完成率时可控制每个动作的组数和总时长，但仍须给出完整可执行计划。必须遵守长期记忆里的可训练日期、器械和身体限制。对新手避免高风险动作；体态关注为真时安排上背、后肩和活动度练习。输出前检查本次最高优先级修改是否已经出现在对应日期的 exercises 或 cardio 中。不要给药物剂量、疾病诊断或疼痛治疗建议。
        """
        let response = try await send(
            prompt: prompt,
            imageData: nil,
            configuration: configuration,
            apiKey: apiKey,
            systemPrompt: "只返回能够被 JSONDecoder 解析的 JSON。",
            maxTokens: 8000,
            jsonMode: true
        )
        let json = extractJSON(from: response)
        guard let data = json.data(using: .utf8) else { throw AIError.unreadableResponse }
        let decoded = try JSONDecoder().decode(GeneratedPlanResponse.self, from: data)
        let plans = decoded.weeklyPlans
            .filter { (1...7).contains($0.weekday) }
            .sorted { $0.weekday < $1.weekday }
        guard plans.count == 7, Set(plans.map(\.weekday)).count == 7 else {
            throw AIError.requestFailed("AI 返回的训练计划不完整，请重试。")
        }
        return WorkoutPlan.normalizedWeekly(plans, for: profile)
    }
    private static func stream(
        prompt: String,
        imageData: Data?,
        configuration: AIConfiguration,
        apiKey: String,
        systemPrompt: String,
        onReasoning: @escaping @MainActor (String) -> Void,
        onDelta: @escaping @MainActor (String) -> Void
    ) async throws {
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

        var payload: [String: Any] = [
            "model": configuration.model,
            "temperature": 0.2,
            "max_tokens": 4000,
            "stream": true,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userContent]
            ]
        ]
        let isOfficialDeepSeek = configuration.endpoint.localizedCaseInsensitiveContains("api.deepseek.com")
        if configuration.showReasoning && isOfficialDeepSeek {
            payload.removeValue(forKey: "temperature")
            payload["thinking"] = ["type": "enabled"]
            payload["reasoning_effort"] = "low"
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 180
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse else { throw AIError.requestFailed("没有收到有效服务器响应") }
        guard 200..<300 ~= http.statusCode else {
            var detail = ""
            for try await line in bytes.lines {
                detail += line
                if detail.count >= 160 { break }
            }
            throw AIError.requestFailed("HTTP \(http.statusCode)：\(detail.prefix(160))")
        }

        var receivedContent = false
        var fallbackLines: [String] = []
        for try await line in bytes.lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            guard trimmed.hasPrefix("data:") else {
                fallbackLines.append(trimmed)
                continue
            }
            let event = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
            if event == "[DONE]" { break }
            guard let data = event.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data),
                  let object = json as? [String: Any],
                  let choices = object["choices"] as? [[String: Any]],
                  let delta = choices.first?["delta"] as? [String: Any] else { continue }
            if configuration.showReasoning,
               let reasoning = delta["reasoning_content"] as? String,
               !reasoning.isEmpty {
                await onReasoning(reasoning)
            }
            if let content = delta["content"] as? String, !content.isEmpty {
                receivedContent = true
                await onDelta(content)
            }
        }

        if !receivedContent, !fallbackLines.isEmpty {
            let data = Data(fallbackLines.joined(separator: "\n").utf8)
            let responseText = try responseText(from: data)
            guard !responseText.isEmpty else { throw AIError.unreadableResponse }
            await onDelta(responseText)
            receivedContent = true
        }
        guard receivedContent else { throw AIError.unreadableResponse }
    }
    private static func send(prompt: String, imageData: Data?, configuration: AIConfiguration, apiKey: String, systemPrompt: String, timeoutInterval: TimeInterval = 120, maxTokens: Int? = nil, jsonMode: Bool = false) async throws -> String {
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

        var payload: [String: Any] = [
            "model": configuration.model,
            "temperature": 0.2,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userContent]
            ]
        ]
        if let maxTokens { payload["max_tokens"] = maxTokens }
        if jsonMode && (configuration.model.lowercased().contains("deepseek") || configuration.endpoint.lowercased().contains("deepseek")) {
            payload["response_format"] = ["type": "json_object"]
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeoutInterval
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
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var showingHelp = false
    @Published var lastSyncedAt: Date?

    func refreshSteps() async {
        guard HKHealthStore.isHealthDataAvailable(),
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            errorMessage = "这台设备当前无法使用健康数据。"
            return
        }

        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let status = try await healthStore.statusForAuthorizationRequest(toShare: [], read: [stepType])
            if status == .shouldRequest {
                try await healthStore.requestAuthorization(toShare: [], read: [stepType])
            }

            let calendar = Calendar(identifier: .gregorian)
            let start = calendar.startOfDay(for: Date())
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? Date()
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let descriptor = HKStatisticsQueryDescriptor(
                predicate: .quantitySample(type: stepType, predicate: predicate),
                options: .cumulativeSum
            )
            let result = try await descriptor.result(for: healthStore)
            steps = Int(result?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
            lastSyncedAt = Date()
            errorMessage = steps == 0 ? "尚未读取到今日步数。请确认健康 App 已允许“练了么”读取步数。" : nil
        } catch {
            let detail = error.localizedDescription
            if detail.localizedCaseInsensitiveContains("healthkit entitlement") || detail.localizedCaseInsensitiveContains("com.apple.developer.healthkit") {
                errorMessage = "当前自签证书没有 HealthKit 权限，无法自动同步；可在下面手动填写今日步数。"
            } else {
                errorMessage = "同步失败：\(detail)"
            }
        }
    }
}
// MARK: - Root and today

struct RootView: View {
    @EnvironmentObject private var store: FitnessStore
    @State private var showingProfileSetup = false

    var body: some View {
        TabView {
            NavigationStack { TodayView() }
                .tabItem { Label("今日", systemImage: "checkmark.seal.fill") }
            NavigationStack { FoodHomeView() }
                .tabItem { Label("饮食", systemImage: "fork.knife") }
            NavigationStack { WorkoutHomeView() }
                .tabItem { Label("训练", systemImage: "dumbbell.fill") }
            NavigationStack { CoachChatView() }
                .tabItem { Label("AI 教练", systemImage: "sparkles") }
            NavigationStack { ProgressDashboardView() }
                .tabItem { Label("进度", systemImage: "chart.line.uptrend.xyaxis") }
        }
        .tint(.green)
        .keyboardDismissToolbar()
        .onAppear { showingProfileSetup = !store.profile.onboardingCompleted }
        .fullScreenCover(isPresented: $showingProfileSetup) {
            PersonalProfileSetupView(isOnboarding: true) {
                showingProfileSetup = false
            }
        }
    }
}
struct TodayView: View {
    @EnvironmentObject private var store: FitnessStore
    @StateObject private var health = HealthManager()
    @State private var showingWeight = false

    private var todayLabel: String {
        Date.now.formatted(.dateTime.month(.wide).day().weekday(.wide))
    }

    private var remainingCalories: Int {
        max(store.nutritionTargets.calories - store.todayNutrition.calories, 0)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(todayLabel)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text("今天，练得刚刚好")
                        .font(.largeTitle.weight(.bold))
                        .tracking(-0.6)
                    Text("完成最小的一步，身体会记住。")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)

                HStack(spacing: 0) {
                    TodayMetric(
                        title: "最新体重",
                        value: store.currentWeight.map { String(format: "%.1f kg", $0) } ?? "去记录",
                        icon: "scalemass.fill",
                        tint: .blue
                    ) {
                        showingWeight = true
                    }

                    Divider()
                        .padding(.vertical, 4)

                    TodayMetric(
                        title: "今日步数",
                        value: health.isRefreshing ? "同步中…" : (health.steps == 0 ? "同步步数" : "\(health.steps)"),
                        icon: "figure.walk",
                        tint: .orange
                    ) {
                        Task { await health.refreshSteps() }
                    }
                }
                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color(uiColor: .separator).opacity(0.28), lineWidth: 0.5)
                }

                if let errorMessage = health.errorMessage {
                    Button { health.showingHelp = true } label: {
                        Label(errorMessage, systemImage: "heart.text.square")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 3) {
                            Label("下一步训练", systemImage: "bolt.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.green)
                            Text(store.todayPlan.title)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.primary)
                        }
                        Spacer(minLength: 12)
                        Text("今天")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Text(store.todayPlan.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let cardio = store.todayPlan.cardio {
                        Label(cardio, systemImage: "figure.walk")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }

                    NavigationLink { WorkoutSessionView(plan: store.todayPlan) } label: {
                        Label("开始训练", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.green)
        .keyboardDismissToolbar()
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("今日燃料")
                                .font(.headline)
                            Text(remainingCalories > 0 ? "还可吃约 \(remainingCalories) kcal" : "今日热量已达目标")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        NavigationLink { FoodHomeView() } label: {
                            Text("查看饮食")
                                .font(.subheadline.weight(.semibold))
                        }
                    }

                    NutrientProgress(
                        title: "热量",
                        value: store.todayNutrition.calories,
                        target: store.nutritionTargets.calories,
                        unit: "kcal",
                        color: .orange
                    )

                    HStack(spacing: 12) {
                        MacroValue(title: "蛋白质", value: store.todayNutrition.protein, target: store.nutritionTargets.protein, color: .green)
                        MacroValue(title: "碳水", value: store.todayNutrition.carbs, target: store.nutritionTargets.carbs, color: .blue)
                        MacroValue(title: "脂肪", value: store.todayNutrition.fat, target: store.nutritionTargets.fat, color: .pink)
                    }
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("饮食记录")
                            .font(.headline)
                        Spacer()
                        NavigationLink("去记录") { FoodHomeView() }
                            .font(.subheadline.weight(.semibold))
                    }

                    ForEach(MealType.allCases) { type in
                        NavigationLink { MealLogEditor(initialType: type) } label: {
                            MealStatusRow(type: type, meal: store.meal(for: type))
                                .padding(.vertical, 7)
                        }
                        .buttonStyle(.plain)

                        if type != MealType.allCases.last! {
                            Divider()
                                .padding(.leading, 36)
                        }
                    }
                }
                .cardStyle()

                DailyCheckInCard(healthSteps: health.steps)
                CoachAdviceCard()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("练了么")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink { SettingsView() } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .onAppear {
            Task { await health.refreshSteps() }
        }
        .sheet(isPresented: $showingWeight) { WeightEntryView() }
        .sheet(isPresented: $health.showingHelp) { HealthStepsHelpView() }
    }
}

struct TodayMetric: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 7) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(tint)
                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
            .padding(16)
        }
        .buttonStyle(.plain)
        .accessibilityHint("轻点更新或记录")
    }
}
struct HealthStepsHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("自签安装提示") {
                    Text("当前自签描述文件如果没有 HealthKit 权限，iPhone 会拒绝自动读取步数。这种情况下请在健康 App 查看今天步数，再回到首页手动填写；不影响饮食、训练和 AI 功能。")
                        .foregroundStyle(.secondary)
                }
                Section("打开步数读取") {
                    Text("在 iPhone 的健康 App 中依次打开：右上角头像 → App 与服务 → 练了么 → 打开“步数”。")
                    Text("HealthKit 为了保护隐私，在未允许读取时只会返回 0；允许后回到首页点“同步步数”即可。")
                        .foregroundStyle(.secondary)
                }
                Section("仍然为 0？") {
                    Text("确认今天 iPhone 或 Apple Watch 已产生步数，并在设备解锁后再同步一次。")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("步数同步")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
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
    @State private var manualSteps = ""

    private var effectiveSteps: Int? {
        if healthSteps > 0 { return healthSteps }
        let value = Int(manualSteps.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        return value > 0 ? value : nil
    }

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
            HStack(spacing: 10) {
                if healthSteps > 0 {
                    Label("步数：\(healthSteps)", systemImage: "figure.walk")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    TextField("手动填写今日步数", text: $manualSteps)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                }
                Button("保存打卡") {
                    store.updateTodayCheckIn(water: water, sleepHours: sleep, steps: effectiveSteps)
                }
                .buttonStyle(.bordered)
            }
        }
        .cardStyle()
        .onAppear {
            let checkIn = store.todayCheckIn
            water = checkIn.waterGlasses
            sleep = checkIn.sleepHours ?? 7
            if healthSteps == 0, let steps = checkIn.steps { manualSteps = String(steps) }
        }
    }
}

struct CoachAdviceCard: View {
    @EnvironmentObject private var store: FitnessStore

    private var tips: [String] {
        var items: [String] = []
        if store.currentWeight == nil { items.append("明早称一次体重；以后看 7 日平均，不用被单日波动影响。") }
        let proteinGap = store.nutritionTargets.protein - store.todayNutrition.protein
        if proteinGap > 25 { items.append("今天还差约 \(proteinGap)g 蛋白质：晚餐优先鸡肉、鱼、牛肉、豆腐或酸奶。") }
        if store.todayNutrition.calories > store.nutritionTargets.calories { items.append("热量已接近或超过目标，晚餐选高蛋白和蔬菜，主食减半。") }
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
        .keyboardDismissToolbar()
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

    private var plan: WorkoutPlan { store.todayPlan }
    private var todaySession: WorkoutSession? {
        store.sessions.first { Calendar.current.isDateInToday($0.date) }
    }

    private var completedToday: Bool { todaySession != nil }

    private var estimatedSessionCalories: Int {
        let cardioMinutes = plan.cardio == nil ? 0 : min(20, max(10, store.profile.preferredSessionMinutes / 3))
        return WorkoutEnergy.estimate(bodyWeightKilograms: store.currentWeight ?? store.profile.startingWeight, totalMinutes: store.profile.preferredSessionMinutes, cardioMinutes: cardioMinutes, cardioSpeedKilometersPerHour: plan.cardio == nil ? nil : 5.0, cardioInclinePercent: plan.cardio == nil ? nil : 8.0, hasStrengthWork: !plan.exercises.isEmpty)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(completedToday ? "今天已保存" : "今天的训练")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(completedToday ? .green : .secondary)
                            Text(plan.title)
                                .font(.title2.weight(.bold))
                            Text(plan.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 12)
                        Image(systemName: completedToday ? "checkmark.seal.fill" : "figure.strengthtraining.traditional")
                            .font(.title2)
                            .foregroundStyle(completedToday ? .green : .primary)
                    }

                    HStack(spacing: 14) {
                        Label("约 \(store.profile.preferredSessionMinutes) 分钟", systemImage: "clock")
                        Label("\(plan.exercises.count) 个动作", systemImage: "list.bullet")
                        Label("约 \(estimatedSessionCalories) kcal", systemImage: "flame.fill")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                    if let session = todaySession {
                        let doneCount = session.exercises.filter(\.completed).count
                        Label(session.exercises.isEmpty ? "今天的恢复记录已保存，可以随时修改。" : "已保存 \(doneCount)/\(session.exercises.count) 个动作，可以随时继续修改。", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    NavigationLink { WorkoutSessionView(plan: plan, existingSession: todaySession) } label: {
                        Label(
                            todaySession == nil ? (plan.exercises.isEmpty ? "查看恢复安排" : "开始训练") : "继续或修改训练",
                            systemImage: todaySession == nil ? "play.fill" : "square.and.pencil"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.green)
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 12) {
                    Text("本周节奏")
                        .font(.headline)
                    TrainingWeekStrip(plans: store.weeklyPlans)
                    Text(store.isUsingAIWorkoutPlan ? "这是按你的资料由 AI 生成的本周计划，可随时在训练配置里更新。" : "这是按你的目标、训练频率和体态关注生成的基础计划；连接 AI 后可生成更细的本周动作。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if !plan.exercises.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("今天的动作")
                                .font(.headline)
                            Spacer()
                            Text("先完成前 3 个也算完成最低训练量")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.bottom, 8)

                        ForEach(Array(plan.exercises.prefix(5).enumerated()), id: \.element.id) { index, exercise in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20, height: 20)
                                    .background(Color(uiColor: .tertiarySystemFill), in: Circle())
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(exercise.name)
                                        .font(.subheadline.weight(.semibold))
                                    Text("\(exercise.target) · \(exercise.cue)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 10)
                            if exercise.id != plan.exercises.prefix(5).last?.id {
                                Divider().padding(.leading, 32)
                            }
                        }
                    }
                    .cardStyle()
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("训练配置")
                            .font(.headline)
                        Spacer()
                        NavigationLink("编辑") { PersonalProfileSetupView(isOnboarding: false) {} }
                            .font(.subheadline.weight(.semibold))
                    }
                    Text("\(store.profile.fitnessGoal.rawValue) · \(store.profile.trainingDaysPerWeek) 天/周 · \(store.profile.preferredSessionMinutes) 分钟 · \(store.profile.equipmentAccess.rawValue)")
                        .font(.subheadline)
                    Text(store.profile.posturePriority ? "已加入前倾/圆肩的上背、后肩与活动度练习。" : "当前计划不额外强调体态练习。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .cardStyle()

                if let session = store.sessions.first {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("最近一次训练")
                            .font(.headline)
                        Text(session.planTitle)
                            .font(.subheadline.weight(.semibold))
                        Text("\(session.date.formatted(date: .abbreviated, time: .omitted)) · \(session.exercises.filter(\.completed).count) 个动作完成 · RPE \(session.perceivedEffort)/10\(session.estimatedCalories.map { " · 约 \($0) kcal" } ?? "")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .cardStyle()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("训练")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink { PersonalProfileSetupView(isOnboarding: false) {} } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
        }
    }
}

struct TrainingWeekStrip: View {
    let plans: [WorkoutPlan]
    private let dayNames = ["日", "一", "二", "三", "四", "五", "六"]

    var body: some View {
        let today = Calendar.current.component(.weekday, from: Date())
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(plans) { plan in
                    let isToday = plan.weekday == today
                    let isRest = plan.exercises.isEmpty
                    NavigationLink { WorkoutPlanDetailView(plan: plan) } label: {
                        VStack(spacing: 5) {
                            Text(dayNames[plan.weekday - 1])
                                .font(.caption.weight(.semibold))
                            Image(systemName: isRest ? "leaf" : "dumbbell.fill")
                                .font(.caption)
                            Text(isToday ? "今天" : (isRest ? "恢复" : "训练"))
                                .font(.caption2)
                        }
                        .foregroundStyle(isToday ? Color.white : (isRest ? Color.secondary : Color.primary))
                        .frame(width: 54, height: 66)
                        .background(isToday ? Color.green : Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            if !isToday {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color(uiColor: .separator).opacity(0.24), lineWidth: 0.5)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("周\(dayNames[plan.weekday - 1])，\(plan.title)，点击查看计划")
                }
            }
        }
    }
}

struct WorkoutPlanDetailView: View {
    let plan: WorkoutPlan
    private let dayNames = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(plan.title)
                        .font(.title2.weight(.bold))
                    Text(plan.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            if plan.exercises.isEmpty {
                Section("恢复安排") {
                    Label(plan.cardio ?? "休息、轻松走路或拉伸", systemImage: "leaf.fill")
                }
            } else {
                Section("力量动作 · \(plan.exercises.count) 个") {
                    ForEach(Array(plan.exercises.enumerated()), id: \.element.id) { index, exercise in
                        VStack(alignment: .leading, spacing: 5) {
                            Text("\(index + 1). \(exercise.name)")
                                .font(.headline)
                            Text(exercise.target)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.green)
                            Text(exercise.cue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                if let cardio = plan.cardio {
                    Section("有氧") {
                        Label(cardio, systemImage: "figure.walk")
                    }
                }
            }
        }
        .navigationTitle(dayNames[min(7, max(1, plan.weekday)) - 1])
        .navigationBarTitleDisplayMode(.inline)
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
    let existingSession: WorkoutSession?
    @State private var drafts: [ExerciseDraft]
    @State private var durationMinutes = ""
    @State private var cardioMinutes = ""
    @State private var cardioInclinePercent = ""
    @State private var cardioSpeedKilometersPerHour = ""
    @State private var effort = 7
    @State private var note = ""

    init(plan: WorkoutPlan, existingSession: WorkoutSession? = nil) {
        self.plan = plan
        self.existingSession = existingSession
        _drafts = State(initialValue: plan.exercises.map { exercise in
            let log = existingSession?.exercises.first { $0.exerciseName == exercise.name }
            return ExerciseDraft(
                exercise: exercise,
                sets: log?.sets ?? 3,
                load: log?.loadKilograms.map { String(format: "%g", $0) } ?? "",
                reps: log?.reps.map { String($0) } ?? "",
                completed: log?.completed ?? false
            )
        })
        _durationMinutes = State(initialValue: existingSession.map { String($0.durationMinutes) } ?? "")
        _cardioMinutes = State(initialValue: existingSession.map { String($0.cardioMinutes) } ?? "")
        _cardioInclinePercent = State(initialValue: existingSession?.cardioInclinePercent.map { String(format: "%g", $0) } ?? "")
        _cardioSpeedKilometersPerHour = State(initialValue: existingSession?.cardioSpeedKilometersPerHour.map { String(format: "%g", $0) } ?? "")
        _effort = State(initialValue: existingSession?.perceivedEffort ?? 7)
        _note = State(initialValue: existingSession?.note ?? "")
    }

    private var effectiveDuration: Int { min(300, max(10, Int(durationMinutes) ?? store.profile.preferredSessionMinutes)) }
    private var effectiveCardioMinutes: Int { min(effectiveDuration, max(0, Int(cardioMinutes) ?? 0)) }
    private var estimatedCalories: Int {
        WorkoutEnergy.estimate(bodyWeightKilograms: store.currentWeight ?? store.profile.startingWeight, totalMinutes: effectiveDuration, cardioMinutes: effectiveCardioMinutes, cardioSpeedKilometersPerHour: Double(cardioSpeedKilometersPerHour), cardioInclinePercent: Double(cardioInclinePercent), hasStrengthWork: !drafts.isEmpty)
    }
    var body: some View {
        List {
            Section("训练时长与消耗") {
                TextField("训练总时长（分钟）", text: $durationMinutes).keyboardType(.numberPad)
                Label("约 \(estimatedCalories) kcal", systemImage: "flame.fill").foregroundStyle(.orange)
                Text("按你的体重、时长、力量训练和有氧参数估算；不包含基础代谢，实际会有误差。").font(.caption).foregroundStyle(.secondary)
            }
            if let cardio = plan.cardio {
                Section("有氧") {
                    Label(cardio, systemImage: "figure.walk")
                    TextField("实际有氧分钟数", text: $cardioMinutes).keyboardType(.numberPad)
                    HStack {
                        TextField("坡度 %", text: $cardioInclinePercent).keyboardType(.decimalPad)
                        TextField("速度 km/h", text: $cardioSpeedKilometersPerHour).keyboardType(.decimalPad)
                    }
                }
            }
            if drafts.isEmpty {
                Section { Text("今天以轻松走路或休息为主。恢复也是计划的一部分。") }
            } else {
                Section("力量动作") {
                    ForEach($drafts) { $draft in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack { Text(draft.exercise.name).font(.headline); Spacer(); Toggle("完成", isOn: $draft.completed).labelsHidden() }
                            Text(draft.exercise.target).font(.caption).foregroundStyle(.secondary)
                            Text(draft.exercise.cue).font(.caption).foregroundStyle(.green)
                            Stepper("组数 \(draft.sets)", value: $draft.sets, in: 1...6)
                            HStack {
                                TextField("重量 kg", text: $draft.load).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                                TextField("最佳次数", text: $draft.reps).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                            }
                        }.padding(.vertical, 4)
                    }
                    Text("未勾选的动作会按“未完成”保存；之后可从训练首页继续修改。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Section("训练感受") {
                Stepper("主观强度 RPE：\(effort)/10", value: $effort, in: 1...10)
                TextField("备注，例如：最后一组还能做 2 次", text: $note, axis: .vertical)
            }
            Section {
                Button(existingSession == nil ? "保存本次进度" : "保存修改") {
                    let logs = drafts.map { WorkoutExerciseLog(exerciseName: $0.exercise.name, target: $0.exercise.target, sets: $0.sets, loadKilograms: Double($0.load), reps: Int($0.reps), completed: $0.completed) }
                    var session = WorkoutSession(planID: plan.id, planTitle: plan.title, exercises: logs, cardioMinutes: effectiveCardioMinutes, cardioInclinePercent: Double(cardioInclinePercent), cardioSpeedKilometersPerHour: Double(cardioSpeedKilometersPerHour), estimatedCalories: estimatedCalories, perceivedEffort: effort, note: note, durationMinutes: effectiveDuration)
                    if let existingSession {
                        session.id = existingSession.id
                        session.date = existingSession.date
                    }
                    store.saveSession(session)
                    dismiss()
                }.frame(maxWidth: .infinity).foregroundStyle(.green)
            }
        }
        .navigationTitle(plan.title)
        .onAppear { if durationMinutes.isEmpty { durationMinutes = String(store.profile.preferredSessionMinutes) } }
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
        .keyboardDismissToolbar()
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
        .keyboardDismissToolbar()

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

final class BackgroundRequestLease: ObservableObject {
    private var identifier: UIBackgroundTaskIdentifier = .invalid

    @MainActor
    func begin() {
        guard identifier == .invalid else { return }
        identifier = UIApplication.shared.beginBackgroundTask(withName: "AI 教练回复") { [weak self] in
            Task { @MainActor in self?.end() }
        }
    }

    @MainActor
    func end() {
        guard identifier != .invalid else { return }
        UIApplication.shared.endBackgroundTask(identifier)
        identifier = .invalid
    }
}

struct CoachChatView: View {
    @EnvironmentObject private var store: FitnessStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var question = ""
    @State private var isSending = false
    @State private var reasoningReply = ""
    @State private var reasoningIsExpanded = true
    @State private var streamingReply = ""
    @State private var errorText: String?
    @State private var pendingActions: [CoachAction] = []
    @State private var applyingActionID: UUID?
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var requestTask: Task<Void, Never>?
    @StateObject private var backgroundLease = BackgroundRequestLease()
    @FocusState private var questionIsFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if !store.canUseAI {
                ContentUnavailableView("尚未配置 AI", systemImage: "sparkles", description: Text("到“我的 → AI 接口与教练”填写你自己的接口、模型和 API Key。"))
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            if store.chatMessages.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Label("能记住，也能执行", systemImage: "brain.head.profile")
                                        .font(.headline)
                                    Text("AI 会先理解你的意图：明确的饮食、训练、体重和打卡会直接写入；删除、目标和计划修改会先给你确认。")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    HStack {
                                        Label("\(store.coachMemories.count) 条记忆", systemImage: "brain")
                                        Label("\(CoachCapability.all.count) 项能力", systemImage: "square.grid.2x2")
                                    }
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.green)
                                    Button {
                                        startPreset("复盘我近 4 周的训练完成情况、饮食和体重趋势，并根据我的长期记忆调整整周每天的训练计划。")
                                    } label: {
                                        Label("复盘并调整整周计划", systemImage: "wand.and.stars")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.green)
                                }
                                .padding(16)
                                .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                            ForEach(store.chatMessages) { message in
                                HStack {
                                    if message.isUser { Spacer(minLength: 42) }
                                    VStack(alignment: .leading, spacing: 8) {
                                        if !message.isUser, let reasoning = message.reasoning, !reasoning.isEmpty {
                                            DisclosureGroup {
                                                Text(reasoning)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                    .textSelection(.enabled)
                                                    .padding(.top, 4)
                                            } label: {
                                                Label("思考过程", systemImage: "brain.head.profile")
                                                    .font(.caption.weight(.semibold))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        Text(message.content)
                                    }
                                        .padding(11)
                                        .background(message.isUser ? Color.green.opacity(0.18) : Color(uiColor: .secondarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                    if !message.isUser { Spacer(minLength: 42) }
                                }
                                .id(message.id)
                            }
                            if isSending {
                                HStack {
                                    VStack(alignment: .leading, spacing: 10) {
                                        if !reasoningReply.isEmpty {
                                            DisclosureGroup(isExpanded: $reasoningIsExpanded) {
                                                Text(reasoningReply + (streamingReply.isEmpty ? "▍" : ""))
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                    .textSelection(.enabled)
                                                    .padding(.top, 4)
                                            } label: {
                                                Label(streamingReply.isEmpty ? "AI 正在思考" : "思考过程", systemImage: "brain.head.profile")
                                                    .font(.caption.weight(.semibold))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        if streamingReply.isEmpty {
                                            ProgressView(reasoningReply.isEmpty ? "AI 正在组织建议…" : "正在生成正式回答…")
                                        } else {
                                        Text(ParsedCoachReply.visibleText(in: streamingReply) + "▍")
                                        }
                                    }
                                    .padding(11)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    Spacer(minLength: 42)
                                }
                                .id("streaming-reply")
                            }
                            ForEach(pendingActions) { action in
                                CoachActionCard(action: action, isApplying: applyingActionID == action.id) {
                                    Task { await apply(action) }
                                } discard: {
                                    pendingActions.removeAll { $0.id == action.id }
                                }
                                .id(action.id)
                            }
                        }
                        .padding()
                    }
                    .scrollDismissesKeyboard(.immediately)
                    .onChange(of: store.chatMessages.count) { _, _ in
                        if let id = store.chatMessages.last?.id { proxy.scrollTo(id, anchor: .bottom) }
                    }
                    .onChange(of: streamingReply) { _, _ in
                        if isSending { proxy.scrollTo("streaming-reply", anchor: .bottom) }
                    }
                    .onChange(of: reasoningReply) { _, _ in
                        if isSending { proxy.scrollTo("streaming-reply", anchor: .bottom) }
                    }
                    .onChange(of: pendingActions.count) { _, _ in
                        if let id = pendingActions.first?.id { proxy.scrollTo(id, anchor: .bottom) }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if store.canUseAI { composer }
        }
        .navigationTitle("AI 教练")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink { CoachMemoryView() } label: {
                    Image(systemName: "brain.head.profile")
                }
                .accessibilityLabel("AI 长期记忆")
                NavigationLink { CoachCapabilitiesView() } label: {
                    Image(systemName: "square.grid.2x2")
                }
                .accessibilityLabel("AI 可用功能")
                Menu {
                    Button {
                        startPreset("复盘我近 4 周的训练完成情况、饮食和体重趋势，并根据我的长期记忆调整整周每天的训练计划。")
                    } label: {
                        Label("复盘并调整周计划", systemImage: "wand.and.stars")
                    }
                    .disabled(isSending || !store.canUseAI)
                    NavigationLink { AISettingsView() } label: {
                        Label("AI 接口设置", systemImage: "slider.horizontal.3")
                    }
                    Button("清空对话", role: .destructive) { store.clearChat(); pendingActions = [] }
                        .disabled(store.chatMessages.isEmpty)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { questionIsFocused = false }
        }
        .onDisappear {
            questionIsFocused = false
        }
    }

    @MainActor
    private func startSending() {
        guard requestTask == nil, !isSending else { return }
        questionIsFocused = false
        requestTask = Task { @MainActor in
            await send()
            requestTask = nil
        }
    }

    @MainActor
    private func startPreset(_ text: String) {
        guard requestTask == nil, !isSending else { return }
        questionIsFocused = false
        requestTask = Task { @MainActor in
            await sendPreset(text)
            requestTask = nil
        }
    }

    @MainActor
    private func stopSending() {
        guard isSending else { return }
        requestTask?.cancel()
        backgroundLease.end()
        questionIsFocused = false
        errorText = "已停止本次回复。"
    }

    @MainActor
    private func send() async {
        let typed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let attachedImage = photoData
        guard !typed.isEmpty || attachedImage != nil, let key = store.aiKey else { return }
        let trimmed = typed.isEmpty ? "请识别这张图片；如果是餐食，请估算营养并准备饮食记录供我确认。" : typed
        let conversationContext = store.coachContext
        store.appendChat(isUser: true, content: attachedImage == nil ? trimmed : "📷 \(trimmed)")
        pendingActions = []
        question = ""
        photoData = nil
        photoItem = nil
        questionIsFocused = false
        reasoningReply = ""
        reasoningIsExpanded = true
        streamingReply = ""
        isSending = true
        errorText = nil
        backgroundLease.begin()
        defer { backgroundLease.end() }
        do {
            try await AIService.coachReplyStream(
                question: trimmed,
                context: conversationContext,
                imageData: attachedImage,
                configuration: store.aiConfiguration,
                apiKey: key,
                onReasoning: { delta in
                    reasoningReply += delta
                }
            ) { delta in
                streamingReply += delta
            }
            let parsed = ParsedCoachReply.parse(streamingReply)
            if !parsed.reply.isEmpty { store.appendChat(isUser: false, content: parsed.reply, reasoning: reasoningReply) }
            if await executePlannedActions(parsed.actions, reasoning: parsed.reply.isEmpty ? reasoningReply : nil) { return }
        } catch {
            if error is CancellationError || (error as? URLError)?.code == .cancelled {
                reasoningReply = ""
                streamingReply = ""
                isSending = false
                return
            }
            let partialReply = streamingReply.trimmingCharacters(in: .whitespacesAndNewlines)
            if !partialReply.isEmpty { store.appendChat(isUser: false, content: partialReply, reasoning: reasoningReply) }
            if (error as? URLError)?.code == .timedOut {
                errorText = "AI 响应超时，原消息已放回输入框，可直接重试。"
            } else {
                errorText = "请求失败：\(error.localizedDescription)"
            }
            question = trimmed
            photoData = attachedImage
        }
        reasoningReply = ""
        streamingReply = ""
        isSending = false
    }

    @MainActor
    private func executePlannedActions(_ actions: [CoachAction], reasoning: String? = nil) async -> Bool {
        guard !actions.isEmpty else { return false }
        var saved: [String] = []
        var failed: [String] = []
        let requiringConfirmation = actions.filter { !$0.canAutoExecuteFromExplicitRequest }

        for action in actions where action.canAutoExecuteFromExplicitRequest {
            do {
                try await store.applyCoachAction(action)
                saved.append("\(action.title)（\(action.detail)）")
            } catch {
                failed.append("\(action.title)：\(error.localizedDescription)")
            }
        }
        pendingActions = requiringConfirmation

        var replyParts: [String] = []
        if !saved.isEmpty { replyParts.append("已实际写入：\(saved.joined(separator: "；"))。") }
        if !requiringConfirmation.isEmpty { replyParts.append("另有 \(requiringConfirmation.count) 项修改需要你在下方确认后才会保存。") }
        if !failed.isEmpty { replyParts.append("未能写入：\(failed.joined(separator: "；"))") }
        store.appendChat(isUser: false, content: replyParts.joined(separator: "\n"), reasoning: reasoning)
        if !failed.isEmpty { errorText = failed.joined(separator: "\n") }
        reasoningReply = ""
        streamingReply = ""
        isSending = false
        return true
    }

    @MainActor
    private func sendPreset(_ text: String) async {
        guard !isSending else { return }
        question = ""
        photoData = nil
        photoItem = nil
        questionIsFocused = false
        pendingActions = []
        reasoningReply = ""
        streamingReply = ""
        errorText = nil
        isSending = true
        store.appendChat(isUser: true, content: text)
        backgroundLease.begin()
        defer { backgroundLease.end() }
        await prepareWeeklyPlanAdjustment(request: text)
    }

    @MainActor
    private func prepareWeeklyPlanAdjustment(request: String) async {
        do {
            let plans = try await store.buildAIWorkoutPlan(adjustmentRequest: request)
            pendingActions = [CoachAction(type: .replaceWeeklyPlan, weeklyPlans: plans)]
            store.appendChat(isUser: false, content: "我已根据你的个人资料、长期记忆和近 4 周完成情况生成新的整周计划。请先查看下面的 7 天预览，点击“确认执行”后才会替换当前计划。")
        } catch {
            if !(error is CancellationError) && (error as? URLError)?.code != .cancelled {
                errorText = error.localizedDescription
                store.appendChat(isUser: false, content: "这次没有成功生成可保存的完整计划：\(error.localizedDescription)")
            }
        }
        streamingReply = ""
        isSending = false
    }

    private var composer: some View {
        VStack(spacing: 8) {
            if let errorText {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(errorText)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .font(.caption)
                .foregroundStyle(.red)
                .padding(.horizontal, 16)
            }
            if let photoData, let image = UIImage(data: photoData) {
                HStack(spacing: 10) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Text("已附加图片，需要当前模型支持视觉")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button { self.photoData = nil; photoItem = nil } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .frame(width: 44, height: 44)
                    .accessibilityLabel("移除已选图片")
                }
                .padding(.horizontal, 16)
            }
            if isSending {
                HStack(spacing: 12) {
                    ProgressView()
                    VStack(alignment: .leading, spacing: 2) {
                        Text(!reasoningReply.isEmpty && streamingReply.isEmpty ? "AI 正在思考" : (streamingReply.isEmpty ? "正在等待 AI 回复" : "AI 正在回复"))
                            .font(.subheadline.weight(.semibold))
                        Text("可切到后台短暂等待，完成后会保留在对话中")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Button("停止", role: .destructive) { stopSending() }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .frame(minWidth: 64, minHeight: 44)
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 52)
            } else {
                HStack(alignment: .bottom, spacing: 6) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Image(systemName: "photo.circle.fill")
                            .font(.title2)
                    }
                    .frame(width: 44, height: 44)
                    .accessibilityLabel("添加图片")
                    .disabled(!store.aiConfiguration.useImageAnalysis)
                    .onChange(of: photoItem) { _, item in
                        Task {
                            guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
                            photoData = ImageCompressor.compress(data)
                        }
                    }
                    TextField("输入消息…", text: $question, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)
                        .focused($questionIsFocused)
                        .submitLabel(.send)
                        .onSubmit { startSending() }
                    if questionIsFocused {
                        Button { questionIsFocused = false } label: {
                            Image(systemName: "keyboard.chevron.compact.down")
                                .font(.title3)
                        }
                        .frame(width: 44, height: 44)
                        .accessibilityLabel("收起键盘")
                    }
                    Button { startSending() } label: {
                        Image(systemName: "arrow.up.circle.fill").font(.title2)
                    }
                    .frame(width: 44, height: 44)
                    .accessibilityLabel("发送给 AI 教练")
                    .disabled((question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && photoData == nil) || !store.canUseAI)
                }
                .padding(.horizontal, 12)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }

    @MainActor
    private func apply(_ action: CoachAction) async {
        guard applyingActionID == nil else { return }
        applyingActionID = action.id
        errorText = nil
        do {
            try await store.applyCoachAction(action)
            pendingActions.removeAll { $0.id == action.id }
            store.appendChat(isUser: false, content: "已保存：\(action.title)（\(action.detail)）。")
        } catch {
            errorText = error.localizedDescription
        }
        applyingActionID = nil
    }
}

struct CoachMemoryView: View {
    @EnvironmentObject private var store: FitnessStore
    @State private var category = "训练偏好"
    @State private var content = ""
    private let categories = ["训练偏好", "饮食偏好", "时间安排", "身体限制", "其他"]

    var body: some View {
        List {
            Section {
                Text("这些内容只保存在本机，并会在每次 AI 对话时作为长期背景发送给你配置的模型。你可以随时添加或删除。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Section("新增记忆") {
                Picker("分类", selection: $category) {
                    ForEach(categories, id: \.self) { Text($0).tag($0) }
                }
                TextField("例如：周六日只能休息，工作日下班训练", text: $content, axis: .vertical)
                    .lineLimit(2...4)
                Button {
                    store.addMemory(category: category, content: content)
                    content = ""
                } label: {
                    Label("保存到长期记忆", systemImage: "plus.circle.fill")
                }
                .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Section("已记住 · \(store.coachMemories.count)") {
                if store.coachMemories.isEmpty {
                    ContentUnavailableView("还没有长期记忆", systemImage: "brain", description: Text("你也可以在聊天中说“记住我周六日休息”。"))
                } else {
                    ForEach(store.coachMemories) { memory in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(memory.category)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.green)
                            Text(memory.content)
                                .font(.subheadline)
                            Text(memory.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                        .swipeActions {
                            Button("删除", role: .destructive) { store.deleteMemory(memory) }
                        }
                    }
                }
            }
        }
        .navigationTitle("AI 长期记忆")
    }
}

struct CoachCapabilitiesView: View {
    private var categories: [String] {
        Array(Set(CoachCapability.all.map(\.category))).sorted { lhs, rhs in
            let order = ["读取与分析", "记录", "目标与计划", "提醒", "记忆"]
            return (order.firstIndex(of: lhs) ?? 99) < (order.firstIndex(of: rhs) ?? 99)
        }
    }

    var body: some View {
        List {
            Section {
                Text("AI 会按语义选择下列功能。明确的新记录会直接写入；删除、目标、提醒和计划等修改会生成确认卡片。HealthKit 自动步数仍受签名权限限制。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ForEach(categories, id: \.self) { category in
                Section(category) {
                    ForEach(CoachCapability.all.filter { $0.category == category }) { capability in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: capability.actionName == nil ? "eye.fill" : "checkmark.circle.fill")
                                .foregroundStyle(capability.actionName == nil ? .blue : .green)
                                .frame(width: 22)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(capability.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(capability.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 3)
                    }
                }
            }
        }
        .navigationTitle("AI 可用功能")
    }
}

struct CoachActionCard: View {
    let action: CoachAction
    let isApplying: Bool
    let confirm: () -> Void
    let discard: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("AI 准备\(action.title)", systemImage: "checkmark.circle.badge.questionmark")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.green)
            Text(action.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
            if !action.planPreviewLines.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(action.planPreviewLines, id: \.self) { line in
                        Text(line)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            HStack {
                Button(isApplying ? "正在处理…" : (action.type == .replaceWeeklyPlan ? "确认替换计划" : (action.isDestructive ? "确认删除" : "确认保存")), action: confirm)
                    .buttonStyle(.borderedProminent)
                    .tint(action.isDestructive ? .red : .green)
                    .disabled(isApplying)
                Button("不保存", role: .cancel, action: discard)
                    .buttonStyle(.bordered)
                    .disabled(isApplying)
            }
        }
        .padding(12)
        .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct NutritionTargetRow: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PersonalProfileSetupView: View {
    @EnvironmentObject private var store: FitnessStore
    @Environment(\.dismiss) private var dismiss
    let isOnboarding: Bool
    let onFinish: () -> Void
    @State private var isGenerating = false
    @State private var message = ""

    private var targets: NutritionTargets { store.nutritionTargets }

    var body: some View {
        Form {
            Section("身体与目标") {
                TextField("身高（cm）", value: $store.profile.heightCentimeters, format: .number)
                    .keyboardType(.decimalPad)
                Stepper("年龄：\(store.profile.age) 岁", value: $store.profile.age, in: 16...80)
                Picker("性别", selection: $store.profile.sex) {
                    ForEach(BiologicalSex.allCases) { Text($0.rawValue).tag($0) }
                }
                TextField("当前/起始体重（kg）", value: $store.profile.startingWeight, format: .number)
                    .keyboardType(.decimalPad)
                TextField("目标体重（kg）", value: $store.profile.currentWeightGoal, format: .number)
                    .keyboardType(.decimalPad)
                Picker("当前目标", selection: $store.profile.fitnessGoal) {
                    ForEach(FitnessGoal.allCases) { Text($0.rawValue).tag($0) }
                }
            }

            Section("训练条件") {
                Picker("日常活动量", selection: $store.profile.activityLevel) {
                    ForEach(ActivityLevel.allCases) { Text($0.rawValue).tag($0) }
                }
                Picker("训练经验", selection: $store.profile.trainingExperience) {
                    ForEach(TrainingExperience.allCases) { Text($0.rawValue).tag($0) }
                }
                Picker("可用器械", selection: $store.profile.equipmentAccess) {
                    ForEach(EquipmentAccess.allCases) { Text($0.rawValue).tag($0) }
                }
                Stepper("每周训练：\(store.profile.trainingDaysPerWeek) 天", value: $store.profile.trainingDaysPerWeek, in: 1...6)
                Stepper("单次训练：\(store.profile.preferredSessionMinutes) 分钟", value: $store.profile.preferredSessionMinutes, in: 30...120, step: 15)
                Toggle("优先改善前倾/圆肩", isOn: $store.profile.posturePriority)
            }

            Section("每日营养目标") {
                Toggle("按个人情况自动计算", isOn: $store.profile.usesRecommendedNutrition)
                if store.profile.usesRecommendedNutrition {
                    HStack(spacing: 12) {
                        NutritionTargetRow(title: "热量", value: "\(targets.calories) kcal", tint: .orange)
                        NutritionTargetRow(title: "蛋白质", value: "\(targets.protein) g", tint: .green)
                        NutritionTargetRow(title: "碳水", value: "\(targets.carbs) g", tint: .blue)
                        NutritionTargetRow(title: "脂肪", value: "\(targets.fat) g", tint: .pink)
                    }
                    Text(targets.sourceText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("这是个人化起点，不是医疗处方。体重趋势、饥饿感和训练表现出现持续异常时，应调整目标或咨询专业人士。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Stepper("热量：\(store.profile.dailyCaloriesGoal) kcal", value: $store.profile.dailyCaloriesGoal, in: 1200...4500, step: 50)
                    Stepper("蛋白质：\(store.profile.dailyProteinGoal) g", value: $store.profile.dailyProteinGoal, in: 60...300, step: 5)
                }
            }

            Section("计划") {
                Button("保存资料并使用基础计划") {
                    store.profile.onboardingCompleted = true
                    store.resetPersonalizedWorkoutPlan()
                    message = "已按当前资料更新基础计划。"
                    if isOnboarding { onFinish() }
                }

                Button {
                    Task {
                        isGenerating = true
                        defer { isGenerating = false }
                        do {
                            try await store.generateAIWorkoutPlan()
                            store.profile.onboardingCompleted = true
                            message = "AI 已更新本周训练安排。"
                            if isOnboarding { onFinish() }
                        } catch {
                            message = error.localizedDescription
                        }
                    }
                } label: {
                    if isGenerating { ProgressView() } else { Label("用 AI 生成本周训练", systemImage: "sparkles") }
                }
                .disabled(!store.canUseAI || isGenerating)

                if !store.canUseAI {
                    Text("连接 AI 接口后，可根据以上资料生成/更新本周动作。未连接时仍会使用基础计划。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if !message.isEmpty {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(isOnboarding ? "建立你的计划" : "个人计划")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isOnboarding {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: FitnessStore

    var body: some View {
        List {
            Section {
                NavigationLink { PersonalProfileSetupView(isOnboarding: false) {} } label: {
                    Label("个人情况与训练计划", systemImage: "person.crop.circle")
                }
            } footer: {
                Text("\(store.profile.fitnessGoal.rawValue) · \(store.profile.trainingDaysPerWeek) 天/周 · \(store.profile.equipmentAccess.rawValue)")
            }

            Section("当前每日目标") {
                LabeledContent("热量", value: "\(store.nutritionTargets.calories) kcal")
                LabeledContent("蛋白质", value: "\(store.nutritionTargets.protein) g")
                LabeledContent("碳水", value: "\(store.nutritionTargets.carbs) g")
                LabeledContent("脂肪", value: "\(store.nutritionTargets.fat) g")
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
                NavigationLink { HealthStepsHelpView() } label: {
                    Label("步数同步与授权", systemImage: "heart.text.square")
                }
            }

            Section("数据与安全") {
                Text("饮食、训练和体重数据只保存在本机。API Key 仅保存于本机 Keychain，不会写入 GitHub 或代码。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("这是个人训练工具，不提供药物剂量、疾病诊断或替代医疗建议。出现持续疼痛或不适时，请咨询医生或康复专业人员。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
    @State private var showReasoning = true
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
                    Button("DeepSeek V4 Flash") {
                        endpoint = "https://api.deepseek.com/chat/completions"
                        model = "deepseek-v4-flash"
                    }
                    Button("DeepSeek V4 Pro") {
                        endpoint = "https://api.deepseek.com/chat/completions"
                        model = "deepseek-v4-pro"
                    }
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
                Toggle("显示支持模型的思考过程", isOn: $showReasoning)
                Text("DeepSeek V4 会以低强度思考并流式显示；其他兼容接口只有返回 reasoning_content 时才会显示。关闭可缩短等待。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
                    store.saveAI(configuration: AIConfiguration(endpoint: endpoint.trimmingCharacters(in: .whitespacesAndNewlines), model: model.trimmingCharacters(in: .whitespacesAndNewlines), useImageAnalysis: useImageAnalysis, showReasoning: showReasoning, customInstruction: instruction.trimmingCharacters(in: .whitespacesAndNewlines)), apiKey: apiKey)
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
            showReasoning = store.aiConfiguration.showReasoning
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
    func keyboardDismissToolbar() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
    }

    func cardStyle() -> some View {
        padding(16)
            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(uiColor: .separator).opacity(0.28), lineWidth: 0.5)
            }
    }
}
