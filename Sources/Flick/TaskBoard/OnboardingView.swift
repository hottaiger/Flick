import SwiftUI

struct OnboardingView: View {
    let finish: () -> Void
    var body: some View { VStack(spacing: 16) { Image(systemName: "checklist.checked").font(.system(size: 36)); Text(L10n.t("onboarding.welcome")).font(.title2.bold()); Text(L10n.t("onboarding.body")).multilineTextAlignment(.center).foregroundStyle(.secondary); Button(L10n.t("onboarding.start"), action: finish).keyboardShortcut(.defaultAction) }.padding(32).frame(width: 380) }
}
