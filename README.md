# 练了么 GymCoach

面向个人减脂的 iPhone 原生应用，最低支持 iOS 17。

已包含：早餐/午餐/晚餐/加餐记录、图片与文字营养估算、可自定义的 OpenAI 兼容 API、AI 教练问答、5 天训练安排、动作完成和训练重量记录、体态改善动作、体重腰围趋势图、饮水睡眠打卡、HealthKit 步数读取，以及可增删改时间的本地提醒。

## AI 设置

在 App 的「我的 → AI 接口与教练」填写完整的 Chat Completions 地址、模型名和自己的 API Key。Key 仅保存于设备 Keychain；个人自用可以直连，若未来发布给他人使用，应改为服务端代理，绝不能将共享 Key 写入 App。

## Codemagic

当前 `codemagic.yaml` 是无签名验证工作流：成功时生成 `.app` 和日志，不会生成可安装 IPA。准备好 Apple 证书和描述文件后，再添加签名工作流导出 IPA。

