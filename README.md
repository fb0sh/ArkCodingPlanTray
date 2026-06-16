# ArkCodingPlanTray

一个轻量级的 macOS 菜单栏应用，让你随时查看 CodingPlan（火山引擎 ARK）的使用情况。

<img width="565" height="76" alt="image" src="https://github.com/user-attachments/assets/82b84980-2992-4fc0-9a50-52deb8093c54" />

<img width="439" height="323" alt="image" src="https://github.com/user-attachments/assets/ec0a5f25-1560-42ad-8af9-ae5a7807ce99" />

<img width="450" height="359" alt="image" src="https://github.com/user-attachments/assets/04353455-3bd9-4d96-900e-750807bc5d32" />

<img width="533" height="434" alt="image" src="https://github.com/user-attachments/assets/b0b76f08-7593-4712-9f05-03e5ee84ae22" />



## 功能特点

- **菜单栏图标** — 点击打开使用量弹窗，再次点击关闭
- **使用量仪表盘** — 查看会话、周和月配额使用量，带进度条显示
- **自动刷新** — 弹窗打开时自动刷新数据
- **节能设计** — 无后台轮询，弹窗关闭即停止刷新
- **安全存储** — Cookie、CSRF Token 和 Web ID 存储在钥匙串中
- **原生体验** — 使用 SwiftUI + AppKit 构建，无 Electron 或 WebView

## 系统要求

- macOS 13.0+（Ventura 或更高版本）
- Apple Silicon 或 Intel Mac
- Xcode 15.0+（用于构建）
- [XcodeGen](https://github.com/nicoverbruggen/xcodegen)（用于生成项目文件）

## 构建与运行

### 1. 安装 XcodeGen

```bash
brew install xcodegen
```

### 2. 生成 Xcode 项目

```bash
cd ArkCodingPlanTray
xcodegen generate
```

### 3. 构建并运行

```bash
xcodebuild -project ArkCodingPlanTray.xcodeproj -scheme ArkCodingPlanTray build
```

或者在 Xcode 中打开项目，按 `Cmd+R` 运行。

## 配置

启动后，点击菜单栏中的饼图图标，然后点击弹窗底部的**设置**按钮（齿轮图标）。

### 通用设置

| 设置项 | 说明 | 默认值 |
|---------|-------------|---------|
| Base URL | 火山引擎控制台基础地址 | `https://console.volcengine.com` |
| Web URL | CodingPlan 网页端地址 | `https://console.volcengine.com/ark/region:ark+cn-beijing/openManagement` |
| 刷新间隔 | 自动刷新间隔（秒） | `60` |

### 账户设置

| 设置项 | 说明 |
|---------|-------------|
| Cookie | 从浏览器开发者工具复制的完整 Cookie 头（存储在钥匙串中） |
| x-csrf-token | 从浏览器开发者工具复制的 CSRF Token（存储在钥匙串中） |
| x-web-id | 从浏览器开发者工具复制的 Web ID（存储在钥匙串中） |

### 如何获取凭证

1. 在 Chrome/Edge 中打开 [CodingPlan 控制台](https://console.volcengine.com/ark/region:ark+cn-beijing/openManagement)
2. 打开开发者工具（F12）→ 网络（Network）选项卡
3. 刷新页面，找到任意 `GetCodingPlanUsage` 请求
4. 复制请求头中的 `Cookie`、`x-csrf-token` 和 `x-web-id` 值
5. 粘贴到应用的账户设置选项卡中

使用**测试连接**按钮验证你的设置是否正确。

## 使用说明

- **点击**菜单栏图标打开/关闭弹窗
- **ESC** 或点击弹窗外部区域关闭弹窗
- **⌘R** 刷新数据
- **设置**齿轮图标配置应用

## 项目架构

```
ArkCodingPlanTray/
├── App/              # 应用入口和 AppDelegate
├── Models/           # 数据模型（CodingPlanUsage, QuotaUsage）
├── Views/            # SwiftUI 视图和 NSPanel
├── ViewModels/       # 视图模型（MVVM 架构）
├── Services/         # API 客户端、钥匙串、设置服务
├── Settings/         # 设置窗口
├── Utilities/        # 协议和工具类
└── Resources/        # Info.plist
```

## 快捷键

| 快捷键 | 操作 |
|----------|------|
| ⌘R | 刷新数据 |
| ESC | 关闭弹窗 |

## 许可证

版权所有 © 2026 ArkCodingPlanTray。保留所有权利。
