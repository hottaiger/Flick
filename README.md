# NotchTodo

macOS 14+ 原生刘海待办工具。收起时显示在刘海右侧（🐟 emoji 装饰，轻微游漂动画），点击或按快捷键展开单栏任务看板。

## 功能特性

### 核心功能

- **刘海贴合式胶囊**：收起时显示在刘海右侧，展示置顶任务标题或任务数量
- **单栏任务看板**：置顶任务固定在最前（最新置顶的在最上），其余任务拖拽排序
- **全局快捷键**：支持 `Option + Enter`（默认）或 `Option + Space`，随时切换面板
- **本地存储**：SwiftData 本地持久化，所有数据只保存在这台 Mac 上

### 任务管理

- **快速新增**：展开面板后输入框自动聚焦，回车创建任务
- **任务属性**：支持优先级（低/中/高）、截止日期、备注
- **任务置顶**：置顶重要任务固定在看板顶部，置顶图钉高亮蓝色，胶囊展示最新置顶任务
- **拖拽排序**：在列内拖拽任务调整顺序，置顶任务不参与排序
- **键盘操作**：`Cmd + Enter` 完成/恢复任务，`Delete` 键删除
- **批量清理**：一键清空所有已完成任务
- **延期功能**：右键菜单快速延期到明天
- **复制标题**：点击复制按钮，显示"复制成功"轻提示

### 归档与恢复

- **自动归档**：每日启动时归档前一天之前完成的任务
- **自动清理**：归档 30 天后自动删除，节省存储空间
- **手动恢复**：可从归档列表恢复任务到已完成状态

### 数据管理

- **JSON 导出**：从菜单栏导出所有任务（包括归档）到 JSON 文件备份
- **JSON 导入**：从菜单栏导入备份，已存在的任务不会重复
- **损坏恢复**：启动时检测数据损坏，自动移动原始数据到恢复目录并提示恢复操作

### 设置选项

- **显示数量**：胶囊显示置顶任务标题或未完成任务数量
- **自动收起**：展开后无操作自动收起（默认关闭，可选 5秒/10秒/30秒）
- **快捷键选择**：切换 `Option + Space` 或 `Option + Enter`
- **外接显示器**：多显示器环境下选择面板位置（顶部居中/左侧/右侧）
- **登录启动**：开机自动启动（默认开启）

### 视觉与交互

- **🐟 emoji 装饰**：胶囊右侧鱼 emoji 轻微上下游漂（尊重系统"减少动态效果"设置时静止）
- **Reminders 风格**：界面材质与图标配色向 macOS 原生提醒事项风格靠拢
- **进度指示**：圆环显示今日完成进度
- **截止提醒**：24 小时内到期显示橙色标记，逾期显示红色标记
- **优先级标识**：胶囊圆点和完成按钮颜色反映任务优先级（高-红色、中-蓝色、低-灰色）
- **无障碍支持**：完整 VoiceOver 标签与辅助功能支持

## 系统要求

- macOS 14 Sonoma 或更高版本
- Apple Silicon（M 系列芯片）或 Intel 处理器
- Swift 5.9+（开发构建时）

## 开发与构建

### 开发调试

先杀掉旧进程避免冲突，再以 debug 模式运行，终端可直接看日志输出：

```bash
pkill -x NotchTodo; swift run
```

### 运行测试

```bash
swift test
```

### 构建发布包

执行构建脚本，自动完成 release 构建、打包 `.app`、ad-hoc 签名、生成分发 zip：

```bash
zsh scripts/build-app.sh
```

构建产物：
- `.build/release/NotchTodo.app` — 可直接运行的应用
- `NotchTodo-macOS-arm64-<version>.zip` — 分发压缩包

打开应用：

```bash
open .build/release/NotchTodo.app
```

**版本号规则**：构建脚本从 git tag（如 `v1.2.0`）自动推导版本号，build 号使用提交计数。无 tag 时版本号为空，文件名使用 `local`。

## 安装与分发

### 本地安装

构建后直接双击 `.build/release/NotchTodo.app` 即可运行。

### 分发说明

当前发布包为 **Apple Silicon（M 系列芯片）** 版本。

#### Gatekeeper 与隔离属性

由于没有 Apple Developer 签名和公证，macOS 会对从浏览器、微信等渠道下载的 App 标记隔离属性（`com.apple.quarantine`）。这**不是压缩包损坏**，而是 macOS 安全机制的正常行为。

**首次打开方法**：

1. 下载并解压 `NotchTodo-macOS-arm64-<version>.zip`
2. 在 Finder 中右键点击 `NotchTodo.app`，选择"打开"
3. 在系统确认框中再次点击"打开"

若仍提示"已损坏"或无法打开，请**仅在确认来源可信时**执行以下命令移除隔离属性：

```bash
xattr -dr com.apple.quarantine ~/Downloads/NotchTodo.app
open ~/Downloads/NotchTodo.app
```

> **注意**：如果 App 不在"下载"目录，请将命令中的路径替换为实际路径。

#### 正式发布（开发者）

面向普通用户正式发布时，需要：

1. 使用 Apple Developer 的 `Developer ID Application` 证书签名
2. 提交 Apple 公证（Notarization）

完成后用户即可正常双击安装，无需上述手动操作。

## 项目结构

```
NotchTodo/
├── Sources/NotchTodo/
│   ├── App/                    # 应用入口与 AppDelegate
│   ├── TaskBoard/              # 任务看板 UI（看板视图、任务卡片、编辑器、快速新增等）
│   ├── TaskStore/              # 任务存储与业务逻辑（置顶、排序、Toast 提示等）
│   ├── TaskPersistence/        # 数据持久化（归档、导入/导出、恢复）
│   ├── NotchWindow/            # 刘海窗口管理（面板控制器、窗口定位、快捷键）
│   ├── Settings/               # 设置视图与登录启动服务
│   ├── Resources/              # 本地化字符串、图标等资源
│   └── L10n.swift              # 本地化工具
├── Tests/NotchTodoTests/       # 单元测试
├── scripts/                    # 构建与工具脚本
│   ├── build-app.sh           # 发布构建脚本
│   └── generate-icon.sh       # 图标生成脚本
├── Package.swift               # Swift Package Manager 配置
└── README.md                   # 本文档
```

## 技术栈

- **SwiftUI**：全部 UI 使用原生 SwiftUI 构建
- **SwiftData**：本地数据持久化
- **AppKit**：底层窗口管理与系统集成
- **Carbon**：全局快捷键注册
- **Swift Package Manager**：依赖管理与构建

## 许可证

MIT
