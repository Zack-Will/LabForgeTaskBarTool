# LabForgeMenuBar

`LabForgeMenuBar` is a lightweight macOS menu bar app for monitoring the public LabForge model status feed.

It displays recent model health, current latency, availability trends, and optionally the top three leaderboard entries, all from the public LabForge endpoints.

## Features

- Native macOS menu bar app built with SwiftUI and AppKit
- Left click opens a status popover
- Right click opens a control menu
- Monitors recent status history for the tracked models
- Shows current ping, latency, and success rate
- Optional leaderboard section, hidden by default and toggled from the right-click menu
- `Launch at Login` support
- Packaged `.app` bundle with LabForge-style app icon

## Data Sources

- `https://www.labforge.top/model-status.json`
- `https://www.labforge.top/leaderboard-data.js`

## Requirements

- macOS 14 or later
- Xcode 26.4 or newer recommended
- Swift 6.3 toolchain recommended

## Project Structure

```text
.
├── Assets/
├── Sources/
│   ├── AppDelegate.swift
│   ├── LabForgeMenuBarApp.swift
│   ├── LabForgeService.swift
│   ├── MenuBarContentView.swift
│   ├── MenuBarController.swift
│   ├── MenuBarViewModel.swift
│   └── Models.swift
├── scripts/
│   ├── generate_icon.swift
│   └── package_app.sh
└── Package.swift
```

## Development

Open the project directory in Xcode and run the executable target directly on macOS.

You can also build it from the terminal:

```bash
swift build
```

## Package a Local App

```bash
./scripts/package_app.sh
open ./dist/LabForgeMenuBar.app
```

## Package a Local DMG

```bash
./scripts/package_app.sh
./scripts/package_dmg.sh
open ./dist/LabForgeMenuBar.dmg
```

## Usage

- Left click the menu bar item to open the monitoring popover.
- Right click the menu bar item to access:
  - `Refresh`
  - `Open LabForge`
  - `Show Leaderboard`
  - `Launch at Login`
  - `Quit`

## Notes

- The app refreshes automatically every 60 seconds.
- The menu bar title shows the current healthy model count, for example `LabForge 3/5`.
- Leaderboard visibility is persisted locally with `UserDefaults`.
- The packaged app in `dist/` is intentionally ignored by git.
