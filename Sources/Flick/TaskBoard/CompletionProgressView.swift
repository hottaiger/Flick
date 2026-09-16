import SwiftUI

struct CompletionProgressView: View {
    let completed: Int
    let total: Int
    var progress: Double { total == 0 ? 0 : Double(completed) / Double(total) }
    var body: some View {
        ZStack { Circle().stroke(.secondary.opacity(0.2), lineWidth: 4); Circle().trim(from: 0, to: progress).stroke(.green, style: StrokeStyle(lineWidth: 4, lineCap: .round)).rotationEffect(.degrees(-90)); Text("\(completed)").font(.system(size: 10, weight: .bold)) }
        .accessibilityLabel(L10n.t("progress.accessibility", completed, total))
    }
}
