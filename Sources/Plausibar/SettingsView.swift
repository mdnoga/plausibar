import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: StatsStore
    @Environment(\.dismiss) private var dismiss

    @AppStorage("siteID") private var siteID: String = ""
    @AppStorage("baseURL") private var baseURL: String = "https://plausible.io"
    @AppStorage("refreshSeconds") private var refreshSeconds: Int = 30

    @State private var apiKey: String = ""
    @State private var launchAtLogin: Bool = LaunchAtLogin.isEnabled
    @State private var launchStatus: String = LaunchAtLogin.statusDescription
    @State private var launchError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Plausibar Settings")
                .font(.title2).bold()

            Form {
                TextField("Site ID", text: $siteID, prompt: Text("example.com"))
                SecureField("API Key", text: $apiKey)
                TextField("Base URL", text: $baseURL)
                Stepper(value: $refreshSeconds, in: 10...600, step: 5) {
                    Text("Refresh every \(refreshSeconds)s")
                }
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        if let err = LaunchAtLogin.set(newValue) {
                            launchError = err.localizedDescription
                            launchAtLogin = LaunchAtLogin.isEnabled
                        } else {
                            launchError = nil
                        }
                        launchStatus = LaunchAtLogin.statusDescription
                    }
            }

            if let err = launchError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if launchStatus != "On" && launchStatus != "Off" {
                Text(launchStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Create a key at Plausible → Account Settings → API Keys. The key is stored in the macOS Keychain.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    if !apiKey.isEmpty { Keychain.save(apiKey) }
                    store.start()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 440)
        .onAppear {
            apiKey = Keychain.load() ?? ""
            launchAtLogin = LaunchAtLogin.isEnabled
            launchStatus = LaunchAtLogin.statusDescription
        }
    }
}
