import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var jobManager: JobManager
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Cronos")
                    .font(.system(.headline, weight: .medium))
                    .foregroundStyle(.primary)
                Spacer()
                Button(action: {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "add-job")
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Add new job")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            // Job list
            if jobManager.jobs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(.tertiary)
                    Text("No jobs")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Add Job") {
                        NSApp.activate(ignoringOtherApps: true)
                        openWindow(id: "add-job")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                JobListView()
            }

            // Footer
            HStack(spacing: 16) {
                SettingsLink {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Settings")

                Spacer()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Image(systemName: "power")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Quit")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(width: 260)
    }
}
