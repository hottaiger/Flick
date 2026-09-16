import SwiftUI

/// 🐟 emoji 装饰：轻微上下游漂动画（尊重系统"减少动态效果"时静止）。
struct FishEmojiView: View {
    @State private var bob: CGFloat = 0

    var body: some View {
        Text("🐟")
            .font(.system(size: 16))
            .offset(y: bob + 3)
            .accessibilityHidden(true)
            .onAppear {
                guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    bob = -2
                }
            }
    }
}
