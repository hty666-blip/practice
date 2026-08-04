# 练了吗（GymCoach）

一个面向减脂、训练打卡和饮食记录的原生 iPhone App 原型。当前版本已包含：

- 早餐、午餐、晚餐与加餐记录
- 根据文字的本地营养估算；配置 AI 接口后，可用文字或餐食照片复核
- 每周 5 天的训练与有氧安排、训练打卡
- 体重记录和 7 日平均趋势
- 可自行设置称重、午餐、训练和晚间复盘提醒
- HealthKit 步数读取入口

## 在 Xcode 中运行

1. 用 Xcode 15 或更新版本打开 `GymCoach.xcodeproj`。
2. 选择 iOS 17 或更新版本的模拟器，直接运行。
3. 在“我的 → AI 接口”中填写兼容 Chat Completions 格式的接口地址、模型名称和 API Key。

API Key 仅通过 Keychain 保存。此开发版允许 App 直接调用你的 AI 服务；如果发布给其他人使用，应改为 `iPhone App → 自有后端 → AI API`，不要让任何用户的 API Key 暴露在客户端。

## AI 接口格式

当前实现发送标准的 `POST /chat/completions` 请求，支持文本和 `image_url`（base64 data URL）形式的餐食图片。模型需能按提示返回 JSON。未配置接口时，记录功能和本地估算仍然可用。
