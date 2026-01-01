import SwiftUI

struct JobRowView: View {
    let job: Job
    @EnvironmentObject var jobManager: JobManager
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            // Status dot
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
                .opacity(jobManager.isRunning(job) ? 1 : 0.9)
                .animation(
                    jobManager.isRunning(job)
                        ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                        : .default,
                    value: jobManager.isRunning(job)
                )

            // Job name
            Text(job.name)
                .lineLimit(1)
                .foregroundStyle(job.isEnabled ? .primary : .secondary)

            Spacer()

            // Status text
            Text(statusText)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isHovered ? Color.primary.opacity(0.04) : Color.clear)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var statusColor: Color {
        if jobManager.isRunning(job) {
            return .blue
        } else if !job.isEnabled {
            return .secondary.opacity(0.5)
        } else {
            return .green
        }
    }

    private var statusText: String {
        if jobManager.isRunning(job) {
            return "running"
        }
        guard job.isEnabled else { return "disabled" }

        let nextRun = job.schedule.nextRun()
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: nextRun, relativeTo: Date())
    }
}
