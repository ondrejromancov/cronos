# Cronos

A lightweight macOS menu bar app for scheduling bash commands.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)

## Features

- **Menu bar app** — lives in your menu bar, not the Dock
- **Schedule commands** — run any bash command daily or weekly
- **Live log streaming** — watch stdout/stderr as jobs run
- **Log history** — browse all past runs with duration and exit codes
- **Failure notifications** — get notified when jobs fail
- **Keyboard navigation** — arrow keys, Enter, Escape
- **Search** — filter jobs by name or command
- **Launch at login** — starts automatically with your Mac

## Installation

1. Clone the repo
2. Open `Cronos.xcodeproj` in Xcode
3. Build and run (⌘R)

## Usage

Click the clock icon in the menu bar to open the job list.

### Managing Jobs

- **Add a job** — click `+` to create a new scheduled command
- **View details** — click any job to expand its detail panel
- **Run now** — trigger a job immediately
- **Enable/disable** — toggle jobs without deleting them
- **Edit/delete** — modify or remove existing jobs

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| ↑/↓ | Navigate between jobs |
| Enter | Expand/collapse job details |
| Escape | Clear search or close panel |

### Logs

Each job shows a preview of the last log line. Click "Logs" to open the full log history:

- View all past runs (newest first)
- See duration, exit code, and timestamp for each run
- Switch between stdout and stderr tabs
- Live streaming while jobs run

### Storage

Jobs and logs are stored locally:

```
~/.cronos/
├── jobs.json          # Job configurations
└── logs/              # Per-run log files
    ├── {runId}.stdout
    └── {runId}.stderr
```

## Example

Schedule a Claude CLI command to run daily:

```
Name: Daily Summary
Command: claude -p "summarize today's git commits"
Working Directory: ~/projects/myapp
Schedule: Daily at 9:00
```

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 15+ to build

## License

MIT
