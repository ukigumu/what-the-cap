import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var confirmReset = false
    @State private var exportingCSV = false

    var body: some View {
        @Bindable var model = model
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(Theme.displayTitle)
                        .foregroundStyle(Theme.ink)
                    Text("Everything stays on this Mac")
                        .font(Theme.mono)
                        .foregroundStyle(Theme.inkFaint)
                }
                .reveal(0)

                LedgerCard {
                    VStack(alignment: .leading, spacing: 18) {
                        SectionLabel("General")
                        SettingRow(
                            title: "Launch at login",
                            detail: "Start counting when you sign in."
                        ) {
                            Toggle("", isOn: $model.launchAtLogin)
                                .toggleStyle(.switch)
                                .tint(Theme.ember)
                                .labelsHidden()
                        }
                        Hairline()
                        SettingRow(
                            title: "Pause counting",
                            detail: model.captureState == .pausedByUser
                                ? "Paused. Nothing is recorded."
                                : "Stop tallying until you resume."
                        ) {
                            Toggle("", isOn: .init(
                                get: { model.captureState == .pausedByUser },
                                set: { _ in withAnimation(Theme.spring) { model.togglePause() } }
                            ))
                            .toggleStyle(.switch)
                            .tint(Theme.ember)
                            .labelsHidden()
                            .disabled(!model.captureState.isCounting && model.captureState != .pausedByUser)
                        }
                    }
                }
                .reveal(1)

                LedgerCard {
                    VStack(alignment: .leading, spacing: 18) {
                        SectionLabel("Data")
                        SettingRow(
                            title: "Export counts as CSV",
                            detail: "Key code, legend, and count. The export contains no typed text because none is stored."
                        ) {
                            Button("Export…") { exportingCSV = true }
                                .buttonStyle(EmberButtonStyle(prominent: false))
                        }
                        Hairline()
                        SettingRow(
                            title: "Reset all counts",
                            detail: "Deletes every tally on this Mac. There is no cloud copy to restore from."
                        ) {
                            Button("Reset…") { confirmReset = true }
                                .buttonStyle(EmberButtonStyle(prominent: false))
                                .foregroundStyle(Theme.danger)
                        }
                    }
                }
                .reveal(2)

                LedgerCard {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionLabel("Privacy")
                        PrivacyRow(symbol: "number", text: "Counts are kept per key code. Key order is never stored, so nothing can be replayed.")
                        PrivacyRow(symbol: "lock.shield", text: "Secure input fields, like password boxes, pause counting automatically.")
                        PrivacyRow(symbol: "externaldrive", text: "Data lives in a local file. WTC has no network access to your counts.")
                        PrivacyRow(symbol: "eye", text: "WTC is a visible app with a menu bar presence. No stealth mode exists.")
                    }
                }
                .reveal(3)

                LedgerCard {
                    VStack(alignment: .leading, spacing: 18) {
                        SectionLabel("Design demo")
                        Text("This build renders mock data so every state is reachable. The controls below exist only in the design build.")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.inkFaint)
                        SettingRow(title: "Capture state", detail: "Preview banners and blocked states.") {
                            Picker("", selection: $model.captureState.animation(Theme.spring)) {
                                ForEach(CaptureState.allCases) { state in
                                    Text(state.label).tag(state)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 160)
                        }
                        Hairline()
                        SettingRow(title: "Mock data", detail: "Restore the seeded dataset after a reset.") {
                            Button("Restore") { withAnimation(Theme.spring) { model.restoreDemoData() } }
                                .buttonStyle(EmberButtonStyle(prominent: false))
                        }
                        Hairline()
                        SettingRow(title: "Onboarding", detail: "Run the permission flow again.") {
                            Button("Show") { model.hasCompletedOnboarding = false }
                                .buttonStyle(EmberButtonStyle(prominent: false))
                        }
                    }
                }
                .reveal(4)
            }
            .padding(Theme.pagePadding)
            .frame(maxWidth: 640, alignment: .leading)
        }
        .confirmationDialog(
            "Reset all counts?",
            isPresented: $confirmReset,
            titleVisibility: .visible
        ) {
            Button("Reset counts", role: .destructive) {
                withAnimation(Theme.spring) { model.resetCounts() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Every per-key and per-app tally on this Mac is deleted.")
        }
        .fileExporter(
            isPresented: $exportingCSV,
            document: CSVDocument(text: model.store.csv(for: .month)),
            contentType: .commaSeparatedText,
            defaultFilename: "wtc-key-counts"
        ) { _ in }
    }
}

struct SettingRow<Accessory: View>: View {
    let title: String
    let detail: String
    @ViewBuilder var accessory: Accessory

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.ink)
                Text(detail)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.inkDim)
            }
            Spacer()
            accessory
        }
    }
}

struct PrivacyRow: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.ember)
                .frame(width: 16)
            Text(text)
                .font(Theme.caption)
                .foregroundStyle(Theme.inkDim)
        }
    }
}

struct CSVDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.commaSeparatedText]

    var text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        text = String(decoding: configuration.file.regularFileContents ?? Data(), as: UTF8.self)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}
