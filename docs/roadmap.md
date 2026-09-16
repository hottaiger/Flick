# Flick 后续工作清单

记录 `review/codebase-improvements` 分支主动**拆出**的功能与工程项，
便于后续按独立任务推进。每项含现状、依据、建议做法。

## 功能

### 拖拽重排序
- **现状**：`TaskStore.move` 只把任务追加到目标桶尾（`nextOrder` = `max(sortOrder)+1`），
  同列内无法调整顺序，也无法插入到两张卡片之间。设计文档 `docs/superpowers/specs/`
  声称"插入到目标项之后"，实现为追加 —— spec 偏差。
- **依据**：`TaskColumnView.dropDestination` drop 时只传目标 bucket，不传插入位置。
- **做法**：`move` 扩展为接受目标位置（邻居 task 或 index），利用 `sortOrder: Double`
  取前后邻居的中值实现插入；`dropDestination` 改为传递 drop 落点。

### 归档恢复入口
- **现状**：设计文档承诺"归档任务保留 30 天可恢复"，但**没有任何 UI** 查看/恢复
  已归档任务。`TaskStore.activeTasks`/`completedTasks` 均用 `!$0.isArchived` 过滤；
  `ArchiveService.archiveCompletedTasks` 打上 `archivedAt` 后任务即从所有列表消失。
  `reopen()` 虽会清 `archivedAt`，但 UI 上看不到已归档任务，无法触发。
  30 天后被 `purgeExpiredArchives` 硬删。
- **做法**：`TaskStore` 加 `archivedTasks` 派生属性 + `unarchive(_:)` 方法；
  看板加"最近归档"折叠区或独立 sheet 展示，允许恢复。

### 小增强
- 今日到期胶囊角标（基于 `dueDate` + `isDueSoon`）。
- 批量操作：清空已完成、全部归档。
- 卡片键盘操作：聚焦后 ⌘↵ 完成、⌫ 删除。

## 工程

### 本地化
- **现状**：全仓库 0 处 `NSLocalizedString`/`String(localized:)`，界面字符串全部
  中文硬编码，`CFBundleDevelopmentRegion=zh-Hans`。
- **SwiftPM 限制**：本项目用 SwiftPM executable target（非 Xcode 项目）。SwiftPM 的
  资源系统（`.copy`/`.process`）**不自动编译** String Catalog（`.xcstrings`）为
  `.lproj/*.strings`，也不挂载到 main bundle 供 `NSLocalizedString` 直接读取。
  强行加 `.xcstrings` 会产出不可工作的本地化。
- **推荐方案**（择一）：
  1. 迁移到 Xcode 项目（`.xcodeproj`）——获得完整 String Catalog 支持。
  2. 保持 SwiftPM，手动维护 `Resources/<lang>.lproj/Localizable.strings`，
     在 `Package.swift` 用 `.copy` 注册资源，代码用 `Bundle.module` 加载
     （需把所有硬编码字符串改为 `String(localized:bundle:)`）。
- **本次范围**：因上述限制，本批次未动代码，仅记录策略。翻译留待选定方案后。

### App 图标
- **现状**：无 `Assets.xcassets`/`.icns`，`Info.plist` 无 `CFBundleIconFile`，
  `build-app.sh` 不打包图标，应用显示通用图标。
- **做法**：提供图标素材后，建 `Resources/AppIcon.icns`，`Info.plist` 加
  `CFBundleIconFile`，`build-app.sh` 加 `cp` 到 `Contents/Resources/`。

## 文档漂移（已知）
- design.md 称默认非活动 5 秒收起，实为 10 秒（`AppSettings.defaultAutoCollapseSeconds`）。
- design.md 称拖拽"按目标项顺序插入"，实为追加（见上方"拖拽重排序"）。
