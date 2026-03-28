# LabForgeTaskBarTool

`LabForgeTaskBarTool` is a native macOS menu bar utility for monitoring the public [LabForge](https://www.labforge.top/#model-status) status feeds.

It turns the LabForge web dashboard into a lightweight desktop experience: left click opens a monitoring popover, right click exposes quick controls, and the app can optionally launch at login.

## Highlights

- Native macOS menu bar app built with SwiftUI + AppKit
- Left-click popover and right-click control menu
- Recent status timeline for all tracked models
- Model remaining / budget cards sourced from the LabForge website
- Optional leaderboard section, hidden by default
- Menu bar text visibility toggle
- Launch at login support
- Local packaging scripts for `.app` and `.dmg`

## Data Sources

The app reads public LabForge endpoints directly:

- `https://www.labforge.top/model-status.json`
- `https://www.labforge.top/leaderboard-data.js`
- `https://www.labforge.top/budget-status.json`

## Requirements

- macOS 14 or later
- Xcode 26.4 or newer recommended
- Swift 6.3 or newer recommended

## Project Structure

```text
.
├── Assets/
│   ├── AppIcon.icns
│   ├── AppIcon.iconset/
│   └── AppIcon.png
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
│   ├── package_app.sh
│   └── package_dmg.sh
├── CHANGELOG.md
├── Package.swift
├── README.md
└── RELEASE.md
```

## Development

Open the repository in Xcode and run the executable target on macOS.

Terminal build:

```bash
swift build
```

## Packaging

Build a local `.app` bundle:

```bash
./scripts/package_app.sh
open ./dist/LabForgeMenuBar.app
```

Build a local `.dmg`:

```bash
./scripts/package_app.sh
./scripts/package_dmg.sh
open ./dist/LabForgeMenuBar.dmg
```

## Usage

Left click:

- Open the monitoring popover

Right click:

- `Refresh`
- `Open LabForge`
- `Show Menu Bar Text`
- `Show Leaderboard`
- `Launch at Login`
- `Quit`

## UI Overview

- `Model Remaining`: budget and remaining capacity cards for GPT and Claude
- `Recent Status`: health timeline, latency, success rate, and current status badge
- `Leaderboard`: top three usage ranking, hidden by default and toggled from the menu

## Notes

- The app refreshes automatically every 60 seconds.
- Leaderboard visibility is persisted with `UserDefaults`.
- Menu bar text visibility is also persisted with `UserDefaults`.
- Build outputs in `dist/` and transient build products are ignored by git.

## License

No license has been added yet. If you plan to open-source this repository publicly, add a license before wider distribution.
