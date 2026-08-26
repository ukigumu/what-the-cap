import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    @State private var step = 0

    private let stepCount = 3

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch step {
                case 0: WelcomeStep()
                case 1: PrivacyStep()
                default: PermissionStep()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .id(step)

            HStack {
                HStack(spacing: 6) {
                    ForEach(0..<stepCount, id: \.self) { index in
                        Capsule()
                            .fill(index == step ? Theme.ember : Theme.hairlineStrong)
                            .frame(width: index == step ? 18 : 6, height: 6)
                    }
                }
                Spacer()
                if step > 0 {
                    Button("Back") {
                        withAnimation(Theme.spring) { step -= 1 }
                    }
                    .buttonStyle(EmberButtonStyle(prominent: false))
                }
                Button(step == stepCount - 1 ? "Start counting" : "Continue") {
                    withAnimation(Theme.spring) {
                        if step == stepCount - 1 {
                            model.hasCompletedOnboarding = true
                        } else {
                            step += 1
                        }
                    }
                }
                .buttonStyle(EmberButtonStyle())
                .keyboardShortcut(.defaultAction)
            }
            .padding(24)
            .background(Theme.bgInset)
            .overlay(alignment: .top) { Hairline() }
        }
        .frame(width: 560, height: 500)
        .background(Theme.bg)
        .animation(Theme.spring, value: step)
    }
}

// MARK: - Steps

private struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Wordmark()
            Text("Your keyboard, in numbers.")
                .font(.system(size: 24, weight: .medium, design: .serif))
                .foregroundStyle(Theme.ink)
            Text("WTC counts how often each key gets pressed.\nIt never records what you type.")
                .font(Theme.body)
                .foregroundStyle(Theme.inkDim)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            Spacer()
            HStack(spacing: 10) {
                ForEach(Array("HOLA".enumerated()), id: \.offset) { index, char in
                    Keycap(legend: String(char), heat: 0.25 + Double(index) * 0.22, width: 40, height: 40)
                        .reveal(index + 2)
                }
            }
            Spacer()
        }
        .padding(36)
    }
}

private struct PrivacyStep: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SectionLabel("The privacy contract")
            Text("Counts, never content.")
                .font(.system(size: 24, weight: .medium, design: .serif))
                .foregroundStyle(Theme.ink)

            VStack(alignment: .leading, spacing: 18) {
                ContractRow(
                    symbol: "number.square",
                    title: "Per-key tallies only",
                    detail: "WTC stores \"key 14 was pressed 1,205 times today\". Key order is never kept, so words and passwords cannot be reconstructed."
                )
                ContractRow(
                    symbol: "lock.shield",
                    title: "Secure input pauses everything",
                    detail: "When macOS flags a password field, WTC stops counting by itself and says so in the menu bar."
                )
                ContractRow(
                    symbol: "externaldrive",
                    title: "Local only",
                    detail: "Counts stay in a file on this Mac. Nothing about your typing crosses the network."
                )
                ContractRow(
                    symbol: "eye",
                    title: "Always visible",
                    detail: "WTC lives in your menu bar and Dock. There is no hidden mode."
                )
            }
            Spacer()
        }
        .padding(36)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PermissionStep: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SectionLabel("One permission")
            Text("Accessibility access")
                .font(.system(size: 24, weight: .medium, design: .serif))
                .foregroundStyle(Theme.ink)
            Text("macOS only lets an app observe key-down events through the Accessibility permission. WTC uses it to increment one counter per key code, and for nothing else.")
                .font(Theme.body)
                .foregroundStyle(Theme.inkDim)
                .lineSpacing(3)

            LedgerCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Theme.inkDim)
                        Text("System Settings › Privacy & Security › Accessibility")
                            .font(Theme.mono)
                            .foregroundStyle(Theme.ink)
                    }
                    Text("Toggle on What the cap, then come back here.")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.inkFaint)
                    Button("Open System Settings") {
                        let pane = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
                        if let url = URL(string: pane) {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(EmberButtonStyle())
                }
            }

            HStack(spacing: 8) {
                Circle().fill(Theme.ember).frame(width: 6, height: 6)
                Text("Waiting for permission · mock status in the design build")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.inkDim)
            }
            Spacer()
        }
        .padding(36)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ContractRow: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.ember)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text(detail)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.inkDim)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
