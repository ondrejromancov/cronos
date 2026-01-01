import SwiftUI

struct JobDetailSidebar: View {
    let job: Job
    @EnvironmentObject var jobManager: JobManager
    @Environment(\.openWindow) private var openWindow
    @State private var showingDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text(job.name)
                .font(.headline)
                .lineLimit(1)

            // Command
            Text(job.command)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(2)
                .foregroundStyle(.secondary)

            // Schedule + Last run
            HStack(spacing: 4) {
                Text(job.schedule.displayString)
                    .font(.caption)
                if let success = job.lastRunSuccessful {
                    Image(systemName: success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(success ? .green : .red)
                        .font(.caption)
                }
            }

            Spacer()

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    Task {
                        await jobManager.runJob(job)
                    }
                } label: {
                    Image(systemName: "play.fill")
                }
                .disabled(jobManager.isRunning(job))
                .help("Run Now")

                Button {
                    jobManager.editingJob = job
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "edit-job")
                } label: {
                    Image(systemName: "pencil")
                }
                .help("Edit")

                Button {
                    jobManager.selectedJobForLogs = job
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "logs")
                } label: {
                    Image(systemName: "doc.text")
                }
                .help("View Logs")

                Spacer()

                Button {
                    Task {
                        await jobManager.toggleJob(job)
                    }
                } label: {
                    Image(systemName: job.isEnabled ? "pause.fill" : "play.circle")
                }
                .help(job.isEnabled ? "Disable" : "Enable")

                Button(role: .destructive) {
                    showingDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
                .help("Delete")
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .confirmationDialog("Delete '\(job.name)'?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    await jobManager.deleteJob(job)
                    jobManager.selectedJob = nil
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}
