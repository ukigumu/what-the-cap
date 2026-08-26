import SwiftUI

/// Full-content states: nothing counted yet, or no permission. Paused and
/// secure-input keep the data visible under a banner instead, because stale
/// numbers are still true numbers.
struct EmptyStateView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        StatePage(
            symbol: "keyboard",
            title: "Nothing counted yet",
            detail: "Counts appear the moment you type anywhere. WTC tallies key codes only, so there is nothing to review or redact.",
            tint: Theme.inkDim
        ) {
            Button("Restore mock data") {
                withAnimation(Theme.spring) { model.restoreDemoData() }
            }
            .buttonStyle(EmberButtonStyle())
        }
    }
}

struct PermissionDeniedView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        StatePage(
            symbol: "keyboard.badge.ellipsis",
            title: "Input Monitoring needed",
            detail: "macOS blocks listen-only key-event taps until you grant Input Monitoring. WTC is idle and counting nothing right now.",
            tint: Theme.danger
        ) {
            HStack(spacing: 10) {
                Button("Open System Settings") {
                    model.requestInputMonitoring()
                    model.openInputMonitoringSettings()
                }
                .buttonStyle(EmberButtonStyle())
                Button("Run onboarding") {
                    model.hasCompletedOnboarding = false
                }
                .buttonStyle(EmberButtonStyle(prominent: false))
            }
        }
    }
}

private struct StatePage<Actions: View>: View {
    let symbol: String
    let title: String
    let detail: String
    let tint: Color
    @ViewBuilder var actions: Actions

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(tint.opacity(0.08))
                    .frame(width: 88, height: 88)
                Circle()
                    .strokeBorder(tint.opacity(0.25), lineWidth: 1)
                    .frame(width: 88, height: 88)
                Image(systemName: symbol)
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(tint)
            }
            .reveal(0)
            Text(title)
                .font(.system(size: 22, weight: .medium, design: .serif))
                .foregroundStyle(Theme.ink)
                .reveal(1)
            Text(detail)
                .font(Theme.body)
                .foregroundStyle(Theme.inkDim)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 380)
                .reveal(2)
            actions
                .reveal(3)
                .padding(.top, 6)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.pagePadding)
    }
}
