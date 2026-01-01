import Foundation

actor JobStore {
    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private var cronosDirectory: URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".cronos")
    }

    private var jobsFile: URL {
        cronosDirectory.appendingPathComponent("jobs.json")
    }

    var logsDirectory: URL {
        cronosDirectory.appendingPathComponent("logs")
    }

    private var runsDirectory: URL {
        logsDirectory.appendingPathComponent("runs")
    }

    private var runsIndexFile: URL {
        logsDirectory.appendingPathComponent("index.json")
    }

    init() {
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    /// Ensures ~/.cronos/, ~/.cronos/logs/, and ~/.cronos/logs/runs/ exist
    func ensureDirectoriesExist() throws {
        try fileManager.createDirectory(
            at: cronosDirectory,
            withIntermediateDirectories: true
        )
        try fileManager.createDirectory(
            at: logsDirectory,
            withIntermediateDirectories: true
        )
        try fileManager.createDirectory(
            at: runsDirectory,
            withIntermediateDirectories: true
        )
    }

    /// Load all jobs from disk
    func loadJobs() throws -> [Job] {
        try ensureDirectoriesExist()

        guard fileManager.fileExists(atPath: jobsFile.path) else {
            return []
        }

        let data = try Data(contentsOf: jobsFile)
        return try decoder.decode([Job].self, from: data)
    }

    /// Save all jobs to disk
    func saveJobs(_ jobs: [Job]) throws {
        try ensureDirectoriesExist()
        let data = try encoder.encode(jobs)
        try data.write(to: jobsFile, options: .atomic)
    }

    /// Get log file URLs for a job
    func logFiles(for jobId: UUID) -> (stdout: URL, stderr: URL) {
        let stdout = logsDirectory.appendingPathComponent("\(jobId.uuidString).log")
        let stderr = logsDirectory.appendingPathComponent("\(jobId.uuidString).err")
        return (stdout, stderr)
    }

    /// Read log content for a job
    func readLog(for jobId: UUID) -> (stdout: String, stderr: String) {
        let files = logFiles(for: jobId)
        let stdout = (try? String(contentsOf: files.stdout, encoding: .utf8)) ?? ""
        let stderr = (try? String(contentsOf: files.stderr, encoding: .utf8)) ?? ""
        return (stdout, stderr)
    }

    /// Delete log files for a job (legacy - single file per job)
    func deleteLog(for jobId: UUID) {
        let files = logFiles(for: jobId)
        try? fileManager.removeItem(at: files.stdout)
        try? fileManager.removeItem(at: files.stderr)
    }

    // MARK: - Log Run History

    /// Load all runs from the index
    func loadRunsIndex() throws -> [LogRun] {
        try ensureDirectoriesExist()

        guard fileManager.fileExists(atPath: runsIndexFile.path) else {
            return []
        }

        let data = try Data(contentsOf: runsIndexFile)
        return try decoder.decode([LogRun].self, from: data)
    }

    /// Save all runs to the index
    private func saveRunsIndex(_ runs: [LogRun]) throws {
        try ensureDirectoriesExist()
        let data = try encoder.encode(runs)
        try data.write(to: runsIndexFile, options: .atomic)
    }

    /// Create a new run for a job
    func createRun(for jobId: UUID) throws -> LogRun {
        var runs = try loadRunsIndex()
        let run = LogRun(jobId: jobId)
        runs.append(run)
        try saveRunsIndex(runs)
        return run
    }

    /// Complete a run with exit status
    func completeRun(_ run: LogRun, exitCode: Int32, success: Bool) throws {
        var runs = try loadRunsIndex()
        guard let index = runs.firstIndex(where: { $0.id == run.id }) else { return }
        runs[index].endedAt = Date()
        runs[index].exitCode = exitCode
        runs[index].success = success
        try saveRunsIndex(runs)
    }

    /// Get all runs for a specific job, sorted by date (newest first)
    func runsFor(jobId: UUID) throws -> [LogRun] {
        let runs = try loadRunsIndex()
        return runs
            .filter { $0.jobId == jobId }
            .sorted { $0.startedAt > $1.startedAt }
    }

    /// Get the latest run for a job
    func latestRun(for jobId: UUID) throws -> LogRun? {
        try runsFor(jobId: jobId).first
    }

    /// Get log file URLs for a specific run
    func logFilesForRun(_ runId: UUID) -> (stdout: URL, stderr: URL) {
        let stdout = runsDirectory.appendingPathComponent("\(runId.uuidString).stdout")
        let stderr = runsDirectory.appendingPathComponent("\(runId.uuidString).stderr")
        return (stdout, stderr)
    }

    /// Read log content for a specific run
    func readLogForRun(_ runId: UUID) -> (stdout: String, stderr: String) {
        let files = logFilesForRun(runId)
        let stdout = (try? String(contentsOf: files.stdout, encoding: .utf8)) ?? ""
        let stderr = (try? String(contentsOf: files.stderr, encoding: .utf8)) ?? ""
        return (stdout, stderr)
    }

    /// Delete all runs for a job
    func deleteRunsFor(jobId: UUID) throws {
        var runs = try loadRunsIndex()
        let jobRuns = runs.filter { $0.jobId == jobId }

        // Delete log files for each run
        for run in jobRuns {
            let files = logFilesForRun(run.id)
            try? fileManager.removeItem(at: files.stdout)
            try? fileManager.removeItem(at: files.stderr)
        }

        // Remove from index
        runs.removeAll { $0.jobId == jobId }
        try saveRunsIndex(runs)
    }
}
