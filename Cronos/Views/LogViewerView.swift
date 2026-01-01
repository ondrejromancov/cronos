import SwiftUI

struct LogViewerView: View {
    let job: Job
    @EnvironmentObject var jobManager: JobManager
    @Environment(\.dismiss) var dismiss
    @State private var stdout = ""
    @State private var stderr = ""
    @State private var selectedTab = 0
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(job.name)
                    .font(.system(.body, weight: .medium))
                Spacer()
                Button {
                    Task { await loadLogs() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                }
                .buttonStyle(.borderless)
                .help("Refresh")

                Button("Done") {
                    jobManager.selectedJobForLogs = nil
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Tabs
            Picker("", selection: $selectedTab) {
                HStack(spacing: 6) {
                    Text("stdout")
                    if !stdout.isEmpty && stdout != "(empty)" {
                        Circle()
                            .fill(.green)
                            .frame(width: 5, height: 5)
                    }
                }
                .tag(0)

                HStack(spacing: 6) {
                    Text("stderr")
                    if !stderr.isEmpty && stderr != "(empty)" {
                        Circle()
                            .fill(.red)
                            .frame(width: 5, height: 5)
                    }
                }
                .tag(1)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            // Log content
            if isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(0.8)
                Spacer()
            } else {
                ScrollView {
                    Text(selectedTab == 0 ? stdout : stderr)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(selectedTab == 0 ? .primary : .secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .textSelection(.enabled)
                }
                .background(Color.primary.opacity(0.03))
            }
        }
        .frame(width: 560, height: 380)
        .task {
            await loadLogs()
        }
    }

    private func loadLogs() async {
        isLoading = true
        let logs = await jobManager.readLog(for: job)
        stdout = logs.stdout.isEmpty ? "(empty)" : logs.stdout
        stderr = logs.stderr.isEmpty ? "(empty)" : logs.stderr
        isLoading = false
    }
}
