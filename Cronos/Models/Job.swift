import Foundation

enum JobType: String, Codable, CaseIterable {
    case claude
    case customCommand
}

enum ClaudeModel: String, Codable, CaseIterable {
    case sonnet = "sonnet"
    case opus = "opus"
    case haiku = "haiku"

    var displayName: String {
        switch self {
        case .sonnet: return "Sonnet"
        case .opus: return "Opus"
        case .haiku: return "Haiku"
        }
    }
}

struct Job: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var command: String
    var workingDirectory: String
    var schedule: Schedule
    var isEnabled: Bool
    var lastRun: Date?
    var lastRunSuccessful: Bool?

    // Claude-specific fields
    var jobType: JobType
    var claudePrompt: String?
    var claudeModel: ClaudeModel?
    var contextDirectories: [String]

    // Explicit CodingKeys to support migration from old contextDirectory to contextDirectories
    private enum CodingKeys: String, CodingKey {
        case id, name, command, workingDirectory, schedule, isEnabled
        case lastRun, lastRunSuccessful
        case jobType, claudePrompt, claudeModel
        case contextDirectories
        case contextDirectory // For migration from old format
    }

    init(
        id: UUID = UUID(),
        name: String,
        command: String = "",
        workingDirectory: String,
        schedule: Schedule,
        isEnabled: Bool = true,
        lastRun: Date? = nil,
        lastRunSuccessful: Bool? = nil,
        jobType: JobType = .claude,
        claudePrompt: String? = nil,
        claudeModel: ClaudeModel? = nil,
        contextDirectories: [String] = []
    ) {
        self.id = id
        self.name = name
        self.command = command
        self.workingDirectory = workingDirectory
        self.schedule = schedule
        self.isEnabled = isEnabled
        self.lastRun = lastRun
        self.lastRunSuccessful = lastRunSuccessful
        self.jobType = jobType
        self.claudePrompt = claudePrompt
        self.claudeModel = claudeModel
        self.contextDirectories = contextDirectories
    }

    /// The command to actually execute, generated from job type and fields
    var effectiveCommand: String {
        switch jobType {
        case .claude:
            let prompt = claudePrompt ?? ""
            let escapedPrompt = prompt.replacingOccurrences(of: "'", with: "'\\''")

            // Get model (job override or global default)
            let model = claudeModel
                ?? ClaudeModel(rawValue: UserDefaults.standard.string(forKey: "defaultClaudeModel") ?? "")
                ?? .sonnet
            var cmd = "claude --model \(model.rawValue) -p '\(escapedPrompt)'"

            // Append context directories
            for dir in contextDirectories where !dir.isEmpty {
                let expandedDir = (dir as NSString).expandingTildeInPath
                let escapedDir = expandedDir.replacingOccurrences(of: "'", with: "'\\''")
                cmd += " '\(escapedDir)'"
            }
            return cmd
        case .customCommand:
            return command
        }
    }

    // Custom decoder for backwards compatibility with existing jobs
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        command = try container.decode(String.self, forKey: .command)
        workingDirectory = try container.decode(String.self, forKey: .workingDirectory)
        schedule = try container.decode(Schedule.self, forKey: .schedule)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        lastRun = try container.decodeIfPresent(Date.self, forKey: .lastRun)
        lastRunSuccessful = try container.decodeIfPresent(Bool.self, forKey: .lastRunSuccessful)

        // New fields with defaults for migration
        jobType = try container.decodeIfPresent(JobType.self, forKey: .jobType) ?? .customCommand
        claudePrompt = try container.decodeIfPresent(String.self, forKey: .claudePrompt)
        claudeModel = try container.decodeIfPresent(ClaudeModel.self, forKey: .claudeModel)

        // Migration: support both old single contextDirectory and new contextDirectories array
        if let dirs = try container.decodeIfPresent([String].self, forKey: .contextDirectories) {
            contextDirectories = dirs
        } else if let singleDir = try container.decodeIfPresent(String.self, forKey: .contextDirectory) {
            contextDirectories = singleDir.isEmpty ? [] : [singleDir]
        } else {
            contextDirectories = []
        }
    }

    // Custom encoder to write new format (contextDirectories, not contextDirectory)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(command, forKey: .command)
        try container.encode(workingDirectory, forKey: .workingDirectory)
        try container.encode(schedule, forKey: .schedule)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encodeIfPresent(lastRun, forKey: .lastRun)
        try container.encodeIfPresent(lastRunSuccessful, forKey: .lastRunSuccessful)
        try container.encode(jobType, forKey: .jobType)
        try container.encodeIfPresent(claudePrompt, forKey: .claudePrompt)
        try container.encodeIfPresent(claudeModel, forKey: .claudeModel)
        try container.encode(contextDirectories, forKey: .contextDirectories)
    }
}
