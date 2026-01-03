import SwiftUI

struct LogViewerView: View {
    let job: Job
    @EnvironmentObject var jobManager: JobManager
    @Environment(\.dismiss) var dismiss
    @State private var stdout = ""
    @State private var stderr = ""
    @State private var isLoading = true

    /// Combined output with stderr appended if present
    private var combinedOutput: String {
        var output = stdout
        if !stderr.isEmpty && stderr != "(empty)" {
            if !output.isEmpty && output != "(empty)" {
                output += "\n\n--- stderr ---\n"
            }
            output += stderr
        }
        if output.isEmpty || output == "(empty)" {
            return "(empty)"
        }
        return output
    }

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

            // Log content
            if isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(0.8)
                Spacer()
            } else {
                ScrollView {
                    Text(combinedOutput)
                        .font(.system(.caption, design: .monospaced))
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
        stdout = logs.stdout
        stderr = logs.stderr
        isLoading = false
    }
}
