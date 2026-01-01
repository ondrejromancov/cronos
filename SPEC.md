# Cronos

A simple macOS menu bar app for scheduling bash commands.

## Overview

Cronos lets you schedule recurring bash commands (like `claude --plugin-dir <paths> -p "<prompt>"`) to run at specific times. Create, inspect, and manage jobs directly from the menu bar.

## Core Features (MVP)

- **Menu bar presence**: Lives in the menu bar, launches at login
- **View jobs**: List all scheduled jobs with name and next run time
- **Create jobs**: Form with name, command, working directory, and schedule
- **Job details**: Click a job to see details, view logs, and access actions
- **Enable/disable jobs**: Toggle jobs on/off without deleting
- **Delete jobs**: Remove jobs with confirmation
- **Run now**: Manually trigger any job immediately (runs in background)
- **Running indicator**: Show spinner next to currently executing jobs
- **Logs**: Stdout/stderr saved to per-job log files

## Design Decisions

| Aspect | Decision |
|--------|----------|
| Storage | Single `~/.cronos/jobs.json` file |
| Logs | Per-job files in `~/.cronos/logs/` |
| Scheduler | In-app timer (app must be running) |
| Auto-launch | On by default, toggle in settings |
| Schedules | Time-based (daily/weekly at specific time) |
| Overlap | Skip run if previous still executing |

## Technical Approach

### Stack
- **Language**: Swift 5.9+
- **UI**: SwiftUI with MenuBarExtra
- **Target**: macOS 14+ (Sonoma)
- **Architecture**: MVVM

### Data Model

```swift
struct Job: Identifiable, Codable {
    let id: UUID
    var name: String
    var command: String
    var workingDirectory: String
    var schedule: Schedule
    var isEnabled: Bool
    var lastRun: Date?
    var lastRunSuccessful: Bool?
}

enum Schedule: Codable {
    case daily(hour: Int, minute: Int)
    case weekly(weekday: Int, hour: Int, minute: Int)  // weekday: 1=Sun, 7=Sat
}
```

### File Structure

```
~/.cronos/
├── jobs.json           # All job configurations
└── logs/
    ├── <job-id>.log    # Latest output per job
    └── <job-id>.err    # Latest stderr per job

cronos/
├── Cronos.xcodeproj
└── Cronos/
    ├── CronosApp.swift
    ├── Models/
    │   ├── Job.swift
    │   └── Schedule.swift
    ├── Views/
    │   ├── MenuBarView.swift
    │   ├── JobListView.swift
    │   ├── JobRowView.swift
    │   ├── JobDetailPopover.swift
    │   ├── AddJobView.swift
    │   └── SettingsView.swift
    ├── ViewModels/
    │   └── JobManager.swift
    ├── Services/
    │   ├── JobStore.swift        # Read/write jobs.json
    │   ├── JobScheduler.swift    # Timer-based scheduling
    │   └── JobRunner.swift       # Execute commands, capture output
    └── Resources/
        └── Assets.xcassets
```

## UI Design

### Menu Bar (Collapsed)
```
⏱ (icon in menu bar)
```

### Menu Bar (Expanded)
```
┌────────────────────────────────┐
│  Cronos                   [+]  │
├────────────────────────────────┤
│  ● Daily Backup     → 9:00am  │
│  ◐ Sync Files       running... │  (◐ = running)
│  ○ Weekly Report    → Mon 8am │  (○ = disabled)
├────────────────────────────────┤
│  Settings...                   │
│  Quit Cronos                   │
└────────────────────────────────┘
```

### Job Detail Popover (on click)
```
┌─────────────────────────────────┐
│  Daily Backup                   │
├─────────────────────────────────┤
│  Command:                       │
│  claude -p "backup files"       │
│                                 │
│  Working Dir: ~/projects        │
│  Schedule: Daily at 9:00am      │
│  Last run: Today 9:00am ✓       │
│  Next run: Tomorrow 9:00am      │
├─────────────────────────────────┤
│  [View Logs]  [Run Now]  [Edit] │
│  [Disable]    [Delete]          │
└─────────────────────────────────┘
```

### Add/Edit Job Form
```
┌─────────────────────────────────┐
│  New Job                        │
├─────────────────────────────────┤
│  Name: [________________]       │
│                                 │
│  Command:                       │
│  [______________________________│
│  ______________________________]│
│                                 │
│  Working Directory:             │
│  [~/projects           ] [📁]   │
│                                 │
│  Schedule:                      │
│  (•) Daily  ( ) Weekly          │
│  Time: [09] : [00]              │
│  Day:  [Monday ▼]  (if weekly)  │
├─────────────────────────────────┤
│         [Cancel]  [Save]        │
└─────────────────────────────────┘
```

## Success Criteria

- [ ] App appears in menu bar on launch
- [ ] Can create a job with name, command, working dir, and schedule
- [ ] Jobs run automatically at scheduled times (when app is running)
- [ ] Can view job details and logs from menu bar
- [ ] Can manually trigger "Run Now"
- [ ] Can enable/disable and delete jobs
- [ ] Shows running indicator for active jobs
- [ ] Logs captured to ~/.cronos/logs/
- [ ] App launches at login (with toggle)
- [ ] Feels native and responsive
