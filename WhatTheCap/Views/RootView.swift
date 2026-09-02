import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        HStack(spacing: 0) {
            RailView()
            Rectangle()
                .fill(Theme.hairline)
                .frame(width: 1)
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.bg)
        .sheet(isPresented: .init(
            get: { !model.hasCompletedOnboarding },
            set: { model.hasCompletedOnboarding = !$0 }
        )) {
            OnboardingView()
                .environment(model)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.selectedScreen {
        case .settings:
            SettingsView()
        case .overview, .heatmap, .apps:
            if model.captureState.blocksContent {
                PermissionDeniedView()
            } else if !model.hasData {
                EmptyStateView()
            } else {
                VStack(spacing: 0) {
                    if model.captureState != .active {
                        CaptureBanner(state: model.captureState)
                    }
                    switch model.selectedScreen {
                    case .overview: DashboardView()
                    case .heatmap: HeatmapView()
                    case .apps: AppsView()
                    case .settings: EmptyView()
                    }
                }
            }
        }
    }
}

// MARK: - Rail

struct RailView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Wordmark()
                .padding(.top, 28)
                .padding(.leading, 22)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(Screen.allCases) { screen in
                    railItem(screen)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 36)

            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                Hairline()
                CaptureStateBadge(state: model.captureState)
                    .padding(.leading, 10)
                Text("Counts per key code.\nNever what you type.")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.inkFaint)
                    .padding(.leading, 10)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 20)
        }
        .frame(width: 208)
        .background(Theme.bgInset)
    }

    private func railItem(_ screen: Screen) -> some View {
        let isSelected = model.selectedScreen == screen
        return Button {
            withAnimation(Theme.spring) { model.selectedScreen = screen }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: screen.symbol)
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 16)
                Text(screen.title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                Spacer()
            }
            .foregroundStyle(isSelected ? Theme.amber : Theme.inkDim)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Theme.amberSoft : Color.clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Capture banner

struct CaptureBanner: View {
    @Environment(AppModel.self) private var model
    let state: CaptureState

    private var tint: Color {
        state == .secureInput ? Theme.calm : Theme.amber
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: state.menuBarSymbol)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(state.label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text(state.detail)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.inkDim)
            }
            Spacer()
            if state == .pausedByUser {
                Button("Resume") { withAnimation(Theme.spring) { model.togglePause() } }
                    .buttonStyle(AccentButtonStyle())
            }
        }
        .padding(.horizontal, Theme.pagePadding)
        .padding(.vertical, 12)
        .background(tint.opacity(0.08))
        .overlay(alignment: .bottom) { Hairline() }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
