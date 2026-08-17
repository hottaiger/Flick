import SwiftUI

enum CapsuleSummaryText {
    static func title(from titles: [String]) -> String {
        guard let first = titles.first, !first.isEmpty else { return L10n.t("capsule.empty") }
        var usedUnits = 0.0
        var prefix = ""
        for character in first {
            let units = character.unicodeScalars.allSatisfy { $0.value <= 0x7F } ? 0.5 : 1.0
            guard usedUnits + units <= 5 else { break }
            prefix.append(character)
            usedUnits += units
        }
        return prefix == first ? prefix : "\(prefix)..."
    }
}

struct NotchSurfaceView: View {
    @ObservedObject var controller: NotchPanelController
    @ObservedObject var store: TaskStore
    @ObservedObject var settings: AppSettings
    let usesTrailingSummaryLayout: Bool
    let isNotchAttached: Bool

    static func shouldShowFish(isExpanded: Bool) -> Bool { !isExpanded }
    static func shouldUseFishBackground(isExpanded: Bool) -> Bool { !isExpanded }

    private var fishLeadingInset: CGFloat {
        isNotchAttached ? 38 : 2
    }

    private var fishBackgroundWidth: CGFloat { isNotchAttached ? 68 : 32 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if controller.isExpanded {
                TaskBoardView(store: store, controller: controller)
            } else {
                HStack(spacing: 0) {
                    Spacer()
                    CapsuleSummaryView(store: store, showsCount: settings.showsTaskCount, usesTrailingSummaryLayout: usesTrailingSummaryLayout, isNotchAttached: isNotchAttached)
                        .frame(width: 104)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture { controller.expand() }
                .contextMenu {
                    Button(L10n.t("capsule.openBoard")) { controller.expand() }
                    Divider()
                    Button(L10n.t("capsule.quit"), role: .destructive) { NSApp.terminate(nil) }
                }
            }
            if Self.shouldUseFishBackground(isExpanded: controller.isExpanded) {
                Color.black
                    .frame(width: fishBackgroundWidth)
                    .frame(maxHeight: .infinity)
                    .allowsHitTesting(false)
            }
        if Self.shouldShowFish(isExpanded: controller.isExpanded) {
            FishEmojiView()
                .frame(maxHeight: .infinity)
                .padding(.leading, fishLeadingInset)
                .allowsHitTesting(false)
        }
        }
        .animation(.spring(response: 0.22, dampingFraction: 0.86), value: controller.isExpanded)
    }
}

private struct CapsuleSummaryView: View {
    @ObservedObject var store: TaskStore
    let showsCount: Bool
    let usesTrailingSummaryLayout: Bool
    let isNotchAttached: Bool

    private var headlineTask: TodoTask? { store.boardTasks.first }
    private var highestPriority: TaskPriority? { headlineTask?.priority }

    var body: some View {
        let summary = HStack(spacing: 8) {
            Circle().fill(color(for: highestPriority)).frame(width: 7, height: 7)
            if showsCount {
                Text(CapsuleSummaryText.title(from: [headlineTask?.title].compactMap { $0 }))
                    .font(.system(size: 12, weight: .semibold))
            } else {
                    Text(L10n.t("capsule.count", store.activeTasks.count)).font(.system(size: 12, weight: .semibold))
            }
        }
        .foregroundStyle(.white)

        Group {
            if usesTrailingSummaryLayout { HStack { Spacer(minLength: 0); summary }.padding(.trailing, 10) }
            else { summary.frame(maxWidth: .infinity) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .clipShape(NotchAttachedCapsuleShape(
            leadingRadius: isNotchAttached ? 0 : 10,
            topTrailingRadius: isNotchAttached ? 0 : 10,
            isNotchAttached: isNotchAttached
        ))
        .overlay(alignment: .topTrailing) {
            if let task = headlineTask, task.isOverdue || task.isDueSoon {
                Circle().fill(task.isOverdue ? Color.red : Color.orange).frame(width: 6, height: 6).padding(5)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.t("capsule.accessibility", store.activeTasks.count))
        .accessibilityHint(L10n.t("capsule.hint"))
    }

    private func color(for priority: TaskPriority?) -> Color {
        switch priority { case .high: .red; case .medium: .blue; case .low: .gray; case nil: .gray.opacity(0.55) }
    }
}

struct NotchAttachedCapsuleShape: Shape {
    let leadingRadius: CGFloat
    let topTrailingRadius: CGFloat
    let isNotchAttached: Bool

    static func bottomTrailingRadius(isNotchAttached: Bool, height: CGFloat) -> CGFloat {
        isNotchAttached ? min(14, height / 2) : 10
    }

    func path(in rect: CGRect) -> Path {
        let leadingRadius = min(leadingRadius, rect.height / 2)
        let topTrailingRadius = min(topTrailingRadius, rect.height / 2)
        let bottomTrailingRadius = min(
            Self.bottomTrailingRadius(isNotchAttached: isNotchAttached, height: rect.height),
            rect.height / 2
        )
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + leadingRadius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - topTrailingRadius, y: rect.minY))
        if topTrailingRadius > 0 { path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + topTrailingRadius), control: CGPoint(x: rect.maxX, y: rect.minY)) }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomTrailingRadius))
        if bottomTrailingRadius > 0 { path.addQuadCurve(to: CGPoint(x: rect.maxX - bottomTrailingRadius, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY)) }
        path.addLine(to: CGPoint(x: rect.minX + leadingRadius, y: rect.maxY))
        if leadingRadius > 0 {
            path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - leadingRadius), control: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + leadingRadius))
            path.addQuadCurve(to: CGPoint(x: rect.minX + leadingRadius, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        } else {
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        }
        return path
    }
}
