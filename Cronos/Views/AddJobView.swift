import SwiftUI

struct AddJobView: View {
    @EnvironmentObject var jobManager: JobManager
    @Environment(\.dismiss) var dismiss

    let editing: Job?

    @State private var name = ""
    @State private var jobType: JobType = .claude
    @State private var command = ""
    @State private var claudePrompt = ""
    @State private var claudeModel: ClaudeModel? = nil
    @State private var useDefaultModel = true
    @State private var contextDirectories: [String] = []
    @State private var workingDirectory = "~"
    @State private var scheduleType: ScheduleType = .daily
    @State private var hour = 9
    @State private var minute = 0
    @State private var weekday = 2 // Monday
    @State private var shakeNameField = false
    @State private var shakeContentField = false

    enum ScheduleType: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
    }

    init(editing: Job? = nil) {
        self.editing = editing
    }

    private var isFormValid: Bool {
        guard !name.isEmpty else { return false }
        switch jobType {
        case .claude:
            return !claudePrompt.isEmpty
        case .customCommand:
            return !command.isEmpty
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Form
            Form {
                Section {
                    Picker("Type", selection: $jobType) {
                        Text("Claude").tag(JobType.claude)
                        Text("Custom Command").tag(JobType.customCommand)
                    }
                    .pickerStyle(.segmented)

                    TextField("Name", text: $name)
                        .modifier(ShakeEffect(shakes: shakeNameField ? 2 : 0))
                        .animation(.default, value: shakeNameField)

                    if jobType == .claude {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Prompt")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            TextEditor(text: $claudePrompt)
                                .font(.system(.body, design: .monospaced))
                                .frame(minHeight: 60)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                                .background(Color.primary.opacity(HoverOpacity.subtle))
                                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonCornerRadius))
                        }
                        .modifier(ShakeEffect(shakes: shakeContentField ? 2 : 0))
                        .animation(.default, value: shakeContentField)

                        HStack {
                            Toggle("Use default model", isOn: $useDefaultModel)
                            Spacer()
                            if !useDefaultModel {
                                Picker("", selection: Binding(
                                    get: { claudeModel ?? .sonnet },
                                    set: { claudeModel = $0 }
                                )) {
                                    ForEach(ClaudeModel.allCases, id: \.self) { model in
                                        Text(model.displayName).tag(model)
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 100)
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Context Directories")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                Spacer()
                                Button(action: addContextDirectory) {
                                    Image(systemName: "plus.circle")
                                }
                                .buttonStyle(.borderless)
                                .help("Add directory")
                            }

                            if contextDirectories.isEmpty {
                                Text("No directories added (optional)")
                                    .font(.caption)
                                    .foregroundStyle(.quaternary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 4)
                            } else {
                                ForEach(Array(contextDirectories.enumerated()), id: \.offset) { index, dir in
                                    HStack(spacing: 4) {
                                        Text(dir)
                                            .font(.system(.caption, design: .monospaced))
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                        Spacer()
                                        Button(action: { contextDirectories.remove(at: index) }) {
                                            Image(systemName: "minus.circle")
                                                .foregroundStyle(.secondary)
                                        }
                                        .buttonStyle(.borderless)
                                        .help("Remove")
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Command")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            TextEditor(text: $command)
                                .font(.system(.body, design: .monospaced))
                                .frame(minHeight: 60)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                                .background(Color.primary.opacity(HoverOpacity.subtle))
                                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonCornerRadius))
                        }
                        .modifier(ShakeEffect(shakes: shakeContentField ? 2 : 0))
                        .animation(.default, value: shakeContentField)
                    }

                    HStack {
                        TextField("Working Directory", text: $workingDirectory)
                            .font(.system(.body, design: .monospaced))
                        Button(action: selectWorkingDirectory) {
                            Image(systemName: "folder")
                        }
                        .buttonStyle(.borderless)
                    }
                }

                Section {
                    Picker("Schedule", selection: $scheduleType) {
                        ForEach(ScheduleType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text("Time")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Picker("", selection: $hour) {
                            ForEach(0..<24, id: \.self) { h in
                                Text(String(format: "%02d", h)).tag(h)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 60)
                        Text(":")
                            .foregroundStyle(.tertiary)
                        Picker("", selection: $minute) {
                            ForEach(0..<60, id: \.self) { m in
                                Text(String(format: "%02d", m)).tag(m)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 60)
                    }

                    if scheduleType == .weekly {
                        Picker("Day", selection: $weekday) {
                            Text("Sunday").tag(1)
                            Text("Monday").tag(2)
                            Text("Tuesday").tag(3)
                            Text("Wednesday").tag(4)
                            Text("Thursday").tag(5)
                            Text("Friday").tag(6)
                            Text("Saturday").tag(7)
                        }
                    }
                }
            }
            .formStyle(.grouped)

            // Buttons
            HStack {
                Button("Cancel") {
                    closeWindow()
                }
                .keyboardShortcut(.escape)
                .foregroundStyle(.secondary)

                Spacer()

                Button(editing == nil ? "Add" : "Save") {
                    attemptSave()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
            }
            .padding()
        }
        .frame(width: 380)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            if let job = editing {
                name = job.name
                jobType = job.jobType
                command = job.command
                claudePrompt = job.claudePrompt ?? ""
                claudeModel = job.claudeModel
                useDefaultModel = job.claudeModel == nil
                contextDirectories = job.contextDirectories
                workingDirectory = job.workingDirectory

                switch job.schedule {
                case .daily(let h, let m):
                    scheduleType = .daily
                    hour = h
                    minute = m
                case .weekly(let w, let h, let m):
                    scheduleType = .weekly
                    weekday = w
                    hour = h
                    minute = m
                }
            }
        }
    }

    private func addContextDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true

        if panel.runModal() == .OK {
            for url in panel.urls {
                let path = url.path
                if !contextDirectories.contains(path) {
                    contextDirectories.append(path)
                }
            }
        }
    }

    private func selectWorkingDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            workingDirectory = url.path
        }
    }

    private func attemptSave() {
        if name.isEmpty {
            shakeNameField.toggle()
            return
        }

        let contentEmpty = jobType == .claude ? claudePrompt.isEmpty : command.isEmpty
        if contentEmpty {
            shakeContentField.toggle()
            return
        }

        save()
    }

    private func save() {
        let schedule: Schedule = scheduleType == .daily
            ? .daily(hour: hour, minute: minute)
            : .weekly(weekday: weekday, hour: hour, minute: minute)

        let effectiveModel: ClaudeModel? = useDefaultModel ? nil : claudeModel

        if let existing = editing {
            var updated = existing
            updated.name = name
            updated.jobType = jobType
            updated.command = command
            updated.claudePrompt = claudePrompt.isEmpty ? nil : claudePrompt
            updated.claudeModel = effectiveModel
            updated.contextDirectories = contextDirectories
            updated.workingDirectory = workingDirectory
            updated.schedule = schedule
            Task {
                await jobManager.updateJob(updated)
            }
        } else {
            let job = Job(
                name: name,
                command: command,
                workingDirectory: workingDirectory,
                schedule: schedule,
                jobType: jobType,
                claudePrompt: claudePrompt.isEmpty ? nil : claudePrompt,
                claudeModel: effectiveModel,
                contextDirectories: contextDirectories
            )
            Task {
                await jobManager.addJob(job)
            }
        }

        closeWindow()
    }

    private func closeWindow() {
        if editing != nil {
            jobManager.editingJob = nil
        }
        dismiss()
    }
}

struct ShakeEffect: GeometryEffect {
    var shakes: Int
    var animatableData: CGFloat {
        get { CGFloat(shakes) }
        set { shakes = Int(newValue) }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = sin(animatableData * .pi * 2) * 6
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}
