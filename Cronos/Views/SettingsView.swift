import SwiftUI

struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = true

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        LaunchAtLogin.setEnabled(newValue)
                    }
            }

            Section("Storage") {
                LabeledContent("Jobs file") {
                    Text("~/.cronos/jobs.json")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                LabeledContent("Logs directory") {
                    Text("~/.cronos/logs/")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                Button("Open in Finder") {
                    let url = FileManager.default.homeDirectoryForCurrentUser
                        .appendingPathComponent(".cronos")
                    NSWorkspace.shared.open(url)
                }
            }

            Section("About") {
                LabeledContent("Version") {
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 250)
        .onAppear {
            // Sync with actual state on appear
            launchAtLogin = LaunchAtLogin.isEnabled
        }
    }
}
