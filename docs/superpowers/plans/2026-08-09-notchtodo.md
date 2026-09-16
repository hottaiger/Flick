# Flick Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS notch task board with local persistence, settings, and test coverage.

**Architecture:** A SwiftUI app hosts a non-activating AppKit panel. SwiftData persists tasks behind `TaskStore`; UI modules consume the store and report user intents. Persistence services own archive, transfer, import/export, and failure recovery behavior.

**Tech Stack:** Swift 5.9+, macOS 14+, SwiftUI, AppKit, SwiftData, ServiceManagement, XCTest.

## Global Constraints

- Target macOS 14.0 or later; use SwiftUI and AppKit only.
- Set `LSUIElement` to `YES`; expose settings and quit through a menu bar extra.
- Store data locally in SwiftData; do not add accounts, network calls, cloud sync, or notification delivery.
- Keep the modules `NotchWindow`, `TaskBoard`, `TaskStore`, `TaskPersistence`, and `Settings`.
- The expanded board is 420 points wide, visually separate from the reference product, and respects Reduce Motion and VoiceOver.

---

### Task 1: Application skeleton and domain model

**Files:**
- Create: `Package.swift`, `Sources/NotchTodo/App/NotchTodoApp.swift`, `Sources/NotchTodo/TaskStore/TodoTask.swift`, `Sources/NotchTodo/TaskStore/TaskStore.swift`, `Tests/NotchTodoTests/TaskStoreTests.swift`

- [ ] Define `TodoTask`, `TaskBucket`, and `TaskPriority` with SwiftData persistence fields.
- [ ] Implement `TaskStore.add`, `move`, `complete`, `restore`, `delete`, and deterministic per-bucket ordering.
- [ ] Test creation, sorting, migration between buckets, and completion state.

### Task 2: Local persistence, archive, and transfer

**Files:**
- Create: `Sources/NotchTodo/TaskPersistence/ModelContainerFactory.swift`, `Sources/NotchTodo/TaskPersistence/ArchiveService.swift`, `Sources/NotchTodo/TaskPersistence/TaskTransferService.swift`, `Sources/NotchTodo/TaskPersistence/RecoveryService.swift`, `Tests/NotchTodoTests/ArchiveServiceTests.swift`, `Tests/NotchTodoTests/TaskTransferServiceTests.swift`

- [ ] Create a local model container and recovery state for persistent-store failure.
- [ ] Archive completed tasks daily, permanently purge after 30 days, and restore retained tasks.
- [ ] Export/import versioned JSON only after validation; test malformed and valid documents.

### Task 3: Notch window lifecycle

**Files:**
- Create: `Sources/NotchTodo/NotchWindow/NotchPanelWindow.swift`, `Sources/NotchTodo/NotchWindow/NotchPanelController.swift`, `Sources/NotchTodo/NotchWindow/DisplayPlacementResolver.swift`, `Sources/NotchTodo/NotchWindow/GlobalShortcutManager.swift`, `Tests/NotchTodoTests/DisplayPlacementResolverTests.swift`

- [ ] Implement a non-activating `NSPanel` with collapsed and expanded frames, all-space visibility, Escape dismissal, outside-click dismissal, and configurable inactivity dismissal.
- [ ] Resolve notch-safe placement or external-display top-center placement.
- [ ] Register Option-Space and re-enable its event tap when macOS disables it.

### Task 4: Task board

**Files:**
- Create: `Sources/NotchTodo/TaskBoard/TaskBoardView.swift`, `Sources/NotchTodo/TaskBoard/QuickAddView.swift`, `Sources/NotchTodo/TaskBoard/TaskColumnView.swift`, `Sources/NotchTodo/TaskBoard/TaskCardView.swift`, `Sources/NotchTodo/TaskBoard/TaskEditorView.swift`, `Sources/NotchTodo/TaskBoard/CompletionProgressView.swift`

- [ ] Build the task count capsule, three buckets, date header, progress ring, quick entry, task edit flow, completed section, and empty state.
- [ ] Add drag/drop bucket migration and contextual actions for priority, tomorrow deferral, and delete.
- [ ] Apply priority/due-soon color states, keyboard navigation, VoiceOver actions, and reduced-motion transitions.

### Task 5: Menu bar, settings, onboarding, and release verification

**Files:**
- Create: `Sources/NotchTodo/App/AppDelegate.swift`, `Sources/NotchTodo/App/MenuBarController.swift`, `Sources/NotchTodo/Settings/AppSettings.swift`, `Sources/NotchTodo/Settings/SettingsView.swift`, `Sources/NotchTodo/Settings/LaunchAtLoginService.swift`, `Sources/NotchTodo/TaskBoard/OnboardingView.swift`

- [ ] Configure the app as a menu-bar-only utility with open, settings, import, export, and quit actions.
- [ ] Implement settings for login launch, timeout, count visibility, shortcut, and external placement.
- [ ] Add first-run onboarding and a visible recovery prompt; build and run all unit tests.
