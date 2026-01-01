import SwiftUI

struct JobRowView: View {
    let job: Job
    @EnvironmentObject var jobManager: JobManager

    var body: some View {
        HStack(spacing: 8) {
            // Status indicator
            statusIndicator
                .font(.system(size: 8))

            // Job name
            Text(job.name)
                .lineLimit(1)

            Spacer()

            // Next run or running status
            if jobManager.isRunning(job) {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: 12, height: 12)
                Text("running...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(nextRunText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.clear)
    }

    @ViewBuilder
    private var statusIndicator: some View {
        if jobManager.isRunning(job) {
            Image(systemName: "circle.dotted")
                .foregroundStyle(.blue)
        } else if !job.isEnabled {
            Image(systemName: "circle")
                .foregroundStyle(.secondary)
        } else {
            Image(systemName: "circle.fill")
                .foregroundStyle(.green)
        }
    }

    private var nextRunText: String {
        guard job.isEnabled else { return "disabled" }

        let nextRun = job.schedule.nextRun()
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: nextRun, relativeTo: Date())
    }
}
