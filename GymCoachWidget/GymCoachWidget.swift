import WidgetKit
import UIKit
import SwiftUI

private struct DashboardWidgetSnapshot: Codable {
    let generatedAt: Date
    let streakDays: Int
    let planTitle: String
    let planSubtitle: String
    let workoutCompleted: Bool
    let mealsLogged: Int
    let mealTarget: Int
    let calories: Int
    let calorieTarget: Int
    let protein: Int
    let proteinTarget: Int

    static let empty = DashboardWidgetSnapshot(
        generatedAt: Date(), streakDays: 0, planTitle: "今天的计划待创建", planSubtitle: "打开练了么填写个人情况",
        workoutCompleted: false, mealsLogged: 0, mealTarget: 3, calories: 0, calorieTarget: 0, protein: 0, proteinTarget: 0
    )
}

private struct GymCoachWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: DashboardWidgetSnapshot
}

private struct GymCoachWidgetProvider: TimelineProvider {
    private let appGroup = "group.com.hty666.gymcoach"
    private let storageKey = "dashboard-widget-snapshot"

    func placeholder(in context: Context) -> GymCoachWidgetEntry {
        GymCoachWidgetEntry(date: Date(), snapshot: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (GymCoachWidgetEntry) -> Void) {
        completion(GymCoachWidgetEntry(date: Date(), snapshot: loadSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GymCoachWidgetEntry>) -> Void) {
        let entry = GymCoachWidgetEntry(date: Date(), snapshot: loadSnapshot())
        let refresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }

    private func loadSnapshot() -> DashboardWidgetSnapshot {
        guard let defaults = UserDefaults(suiteName: appGroup),
              let data = defaults.data(forKey: storageKey),
              let snapshot = try? JSONDecoder().decode(DashboardWidgetSnapshot.self, from: data) else {
            return .empty
        }
        return snapshot
    }
}

private struct GymCoachWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: GymCoachWidgetEntry

    private var mealText: String { "餐食 \(entry.snapshot.mealsLogged)/\(entry.snapshot.mealTarget)" }
    private var proteinText: String { "蛋白 \(entry.snapshot.protein)/\(entry.snapshot.proteinTarget)g" }

    var body: some View {
        Group {
            if family == .systemSmall {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("练了么")
                            .font(.caption.weight(.bold))
                        Spacer()
                        Image(systemName: entry.snapshot.workoutCompleted ? "checkmark.seal.fill" : "figure.strengthtraining.traditional")
                            .foregroundStyle(entry.snapshot.workoutCompleted ? .green : .secondary)
                    }
                    Spacer()
                    Text("连续 \(entry.snapshot.streakDays) 天")
                        .font(.title3.weight(.bold))
                    Text(entry.snapshot.workoutCompleted ? "今日训练已完成" : entry.snapshot.planTitle)
                        .font(.subheadline)
                        .lineLimit(2)
                    Text(entry.snapshot.workoutCompleted ? "保持节奏，明天继续。" : "\(mealText) · \(proteinText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("练了么")
                            .font(.headline)
                        Spacer()
                        Label("连续 \(entry.snapshot.streakDays) 天", systemImage: "flame.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: entry.snapshot.workoutCompleted ? "checkmark.circle.fill" : "dumbbell.fill")
                            .font(.title2)
                            .foregroundStyle(entry.snapshot.workoutCompleted ? .green : .primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.snapshot.workoutCompleted ? "今日训练已完成" : entry.snapshot.planTitle)
                                .font(.subheadline.weight(.semibold))
                            Text(entry.snapshot.workoutCompleted ? "恢复和饮食同样重要" : entry.snapshot.planSubtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    HStack(spacing: 16) {
                        WidgetProgress(title: mealText, progress: Double(entry.snapshot.mealsLogged) / Double(max(entry.snapshot.mealTarget, 1)), tint: .orange)
                        WidgetProgress(title: proteinText, progress: Double(entry.snapshot.protein) / Double(max(entry.snapshot.proteinTarget, 1)), tint: .green)
                    }
                }
            }
        }
        .containerBackground(for: .widget) { Color(uiColor: .systemBackground) }
    }
}

private struct WidgetProgress: View {
    let title: String
    let progress: Double
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption2)
                .lineLimit(1)
            ProgressView(value: min(max(progress, 0), 1))
                .tint(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@main
struct GymCoachWidget: Widget {
    let kind = "GymCoachWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GymCoachWidgetProvider()) { entry in
            GymCoachWidgetView(entry: entry)
        }
        .configurationDisplayName("练了么 · 今日计划")
        .description("查看连续打卡、今日训练和饮食完成状态。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}