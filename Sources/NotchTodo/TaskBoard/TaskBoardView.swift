import SwiftUI

struct TaskBoardView: View {
    @ObservedObject var store: TaskStore
    @ObservedObject var controller: NotchPanelController
    @State private var isCompletedExpanded = false
    @State private var isArchivedExpanded = false
    @State private var isBoardTargeted = false
    @State private var activeSheet: ActiveSheet?
    @FocusState private var quickAddFocused: Bool
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false

    private enum ActiveSheet: Identifiable {
        case onboarding
        case editor(TodoTask)
        var id: String {
            switch self {
            case .onboarding: "onboarding"
            case .editor(let task): "editor-\(task.id.uuidString)"
            }
        }
    }

    private var totalToday: Int { store.activeTasks.count + store.completedTasks.count }
    private var completeCount: Int { store.completedTasks.count }

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Date.now.formatted(.dateTime.weekday(.wide).month().day())).font(.system(size: 13, weight: .semibold))
                    Text(L10n.t("board.tagline")).font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Spacer()
                CompletionProgressView(completed: completeCount, total: totalToday).frame(width: 34, height: 34)
                Button { controller.collapse() } label: { Image(systemName: "xmark").font(.system(size: 11, weight: .bold)) }.buttonStyle(.plain).accessibilityLabel(L10n.t("board.collapse"))
            }
            QuickAddView(store: store, focused: $quickAddFocused, activity: controller.registerActivity)
            boardList
            if !store.completedTasks.isEmpty { completedSection }
            if !store.archivedTasks.isEmpty { archivedSection }
            if store.activeTasks.isEmpty {
                Text(L10n.t("quickadd.empty"))
                    .font(.system(size: 12)).foregroundStyle(.secondary).frame(maxWidth: .infinity, minHeight: 42)
            }
        }
        .padding(14)
        .frame(width: 420, height: 430, alignment: .top)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(.white.opacity(0.12)))
        .onAppear {
            DispatchQueue.main.async { quickAddFocused = true }
            if !onboardingCompleted { activeSheet = .onboarding }
        }
        .onKeyPress(.escape) { controller.collapse(); return .handled }
        .sheet(item: $activeSheet, onDismiss: { activeSheet = nil }) { sheet in
            switch sheet {
            case .onboarding: OnboardingView { onboardingCompleted = true; activeSheet = nil }
            case .editor(let task): TaskEditorView(task: task, store: store)
            }
        }
        .alert(L10n.t("board.error"), isPresented: Binding(get: { store.saveError != nil }, set: { if !$0 { store.clearError() } })) {
            Button(L10n.t("board.ok")) { store.clearError() }
        } message: {
            Text(store.saveError ?? "")
        }
    }

    /// 单栏任务列表（可滚动、撑满剩余高度；拖拽排序：拖到卡片上=插前，拖到空白=追加尾）。
    private var boardList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(store.boardTasks, id: \.id) { task in
                    TaskCardView(task: task, store: store, editorTask: editorBinding, activity: controller.registerActivity)
                        .draggable(task.id.uuidString)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(7)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isBoardTargeted ? AnyShapeStyle(Color.accentColor.opacity(0.13)) : AnyShapeStyle(.quaternary.opacity(0.3)), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .dropDestination(for: String.self) { identifiers, _ in
            guard let raw = identifiers.first,
                  let id = UUID(uuidString: raw),
                  let task = store.tasks.first(where: { $0.id == id }) else { return false }
            store.move(task, before: nil)
            controller.registerActivity()
            return true
        } isTargeted: { isBoardTargeted = $0 }
    }

    private var completedSection: some View {
        HStack {
            DisclosureGroup(L10n.t("board.completed", store.completedTasks.count), isExpanded: $isCompletedExpanded) {
                ForEach(store.completedTasks, id: \.id) { task in
                    TaskCardView(task: task, store: store, editorTask: editorBinding, activity: controller.registerActivity)
                }
            }
            Spacer(minLength: 4)
            Button(L10n.t("board.clearCompleted")) { clearCompleted() }
                .buttonStyle(.plain).font(.caption).foregroundStyle(.red)
        }
        .font(.caption)
    }

    private var archivedSection: some View {
        DisclosureGroup(L10n.t("board.archived", store.archivedTasks.count), isExpanded: $isArchivedExpanded) {
            ForEach(store.archivedTasks, id: \.id) { task in
                HStack {
                    Text(task.title).font(.system(size: 12)).strikethrough().foregroundStyle(.secondary).lineLimit(1)
                    Spacer()
                    Button(L10n.t("board.restore")) { store.unarchive(task); controller.registerActivity() }
                        .buttonStyle(.plain).font(.caption).foregroundStyle(.blue)
                }
            }
        }
        .font(.caption)
    }

    private func clearCompleted() {
        let snapshot = store.completedTasks
        for task in snapshot { store.delete(task) }
    }

    private var editorBinding: Binding<TodoTask?> {
        Binding(
            get: {
                if case .editor(let task) = activeSheet { return task }
                return nil
            },
            set: { newValue in
                if let newValue {
                    activeSheet = .editor(newValue)
                } else if case .editor = activeSheet {
                    activeSheet = nil
                }
            }
        )
    }
}
