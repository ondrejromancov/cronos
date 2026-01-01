import Foundation

/// Represents a single execution run of a job
struct LogRun: Identifiable, Codable, Equatable {
    let id: UUID
    let jobId: UUID
    let startedAt: Date
    var endedAt: Date?
    var exitCode: Int32?
    var success: Bool?

    /// Filename for stdout log file
    var stdoutFilename: String { "\(id.uuidString).stdout" }

    /// Filename for stderr log file
    var stderrFilename: String { "\(id.uuidString).stderr" }

    /// Duration of the run, if completed
    var duration: TimeInterval? {
        guard let endedAt = endedAt else { return nil }
        return endedAt.timeIntervalSince(startedAt)
    }

    /// Human-readable duration string
    var durationString: String? {
        guard let duration = duration else { return nil }
        if duration < 1 {
            return "<1s"
        } else if duration < 60 {
            return "\(Int(duration))s"
        } else if duration < 3600 {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return "\(minutes)m \(seconds)s"
        } else {
            let hours = Int(duration) / 3600
            let minutes = (Int(duration) % 3600) / 60
            return "\(hours)h \(minutes)m"
        }
    }

    init(jobId: UUID, startedAt: Date = Date()) {
        self.id = UUID()
        self.jobId = jobId
        self.startedAt = startedAt
    }
}
