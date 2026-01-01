import SwiftUI

struct LogHistoryView: View {
    let job: Job
    @EnvironmentObject var jobManager: JobManager
    @State private var runs: [LogRun] = []
    @State private var selectedRunId: UUID?
    @State private var selectedTab: LogTab = .stdout
    @State private var logs: (stdout: String, stderr: String) = ("", "")
    @State private var isLoadingRuns = true
    @State private var isLoadingLogs = false

    enum LogTab: String, CaseIterable {
        case stdout = "stdout"
        case stderr = "stderr"
    }

    private var selectedRun: LogRun? {
        runs.first { $0.id == selectedRunId }
    }

    var body: some View {
        HSplitView {
            // Left: List of runs
            runsList
                .frame(minWidth: 180, idealWidth: 200, maxWidth: 250)

            // Right: Log content
            logContent
                .frame(minWidth: 350)
        }
        .frame(minWidth: 600, minHeight: 400)
        .task {
            await loadRuns()
        }
    }

    private var runsList: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Runs")
                    .font(.headline)
                Spacer()
                Text("\(runs.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.primary.opacity(0.02))

            Divider()

            if isLoadingRuns {
                Spacer()
                ProgressView()
                Spacer()
            } else if runs.isEmpty {
                Spacer()
                Text("No runs yet")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                List(runs, selection: $selectedRunId) { run in
                    RunRow(run: run)
                        .tag(run.id)
                }
                .listStyle(.plain)
            }
        }
        .onChange(of: selectedRunId) { _, newId in
            if let id = newId {
                Task { await loadLogs(for: id) }
            }
        }
    }

    private var logContent: some View {
        VStack(spacing: 0) {
            if let run = selectedRun {
                // Header with tabs
                HStack(spacing: 12) {
                    Picker("", selection: $selectedTab) {
                        ForEach(LogTab.allCases, id: \.self) { tab in
                            HStack(spacing: 4) {
                                Text(tab.rawValue)
                                if hasContent(for: tab) {
                                    Circle()
                                        .fill(tab == .stderr ? Color.red : Color.green)
                                        .frame(width: 6, height: 6)
                                }
                            }
                            .tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)

                    Spacer()

                    // Run info
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatTimestamp(run.startedAt))
                            .font(.caption)

                        if let duration = run.durationString {
                            Text("Duration: \(duration)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Status indicator
                    if let success = run.success {
                        Circle()
                            .fill(success ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.primary.opacity(0.02))

                Divider()

                // Log content
                if isLoadingLogs {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    ScrollView {
                        let content = selectedTab == .stdout ? logs.stdout : logs.stderr
                        if content.isEmpty {
                            Text("(empty)")
                                .foregroundStyle(.secondary)
                                .font(.system(.caption, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            Text(content)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(selectedTab == .stderr ? .secondary : .primary)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                        }
                    }
                    .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
                }
            } else {
                // No selection
                ContentUnavailableView(
                    "Select a Run",
                    systemImage: "doc.text",
                    description: Text("Choose a run from the list to view its logs")
                )
            }
        }
    }

    private func hasContent(for tab: LogTab) -> Bool {
        switch tab {
        case .stdout:
            return !logs.stdout.isEmpty
        case .stderr:
            return !logs.stderr.isEmpty
        }
    }

    private func loadRuns() async {
        isLoadingRuns = true
        defer { isLoadingRuns = false }

        runs = await jobManager.loadRuns(for: job.id)

        // Auto-select the most recent run
        if let firstRun = runs.first {
            selectedRunId = firstRun.id
        }
    }

    private func loadLogs(for runId: UUID) async {
        isLoadingLogs = true
        defer { isLoadingLogs = false }

        logs = await jobManager.readLogForRun(runId)
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Run Row

private struct RunRow: View {
    let run: LogRun

    var body: some View {
        HStack(spacing: 8) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(formatTimestamp(run.startedAt))
                    .font(.system(.body))

                if let duration = run.durationString {
                    Text(duration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        if let success = run.success {
            return success ? .green : .red
        }
        return .gray
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}
