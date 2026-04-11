# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

## [0.1.3] - 2026-04-11

### Changed

- Added compatibility for the current model status feed schema that uses `s` status values
- Added direct `notices.json` support with homepage fallback for announcements
- Changed leaderboard display from top-three only to a nested scroll list of all entries
- Made refreshes preserve successfully fetched sections when another feed fails

## [0.1.2] - 2026-03-30

### Added

- Added announcement display based on the latest LabForge homepage notices
- Added a marquee-style announcement banner inside the popover

### Changed

- Synced the budget section with the latest LabForge website schema and copy

### Fixed

- Fixed announcement text clipping so marquee content stays inside the rounded container

## [0.1.1] - 2026-03-29

### Fixed

- Prevented the menu bar popover from jumping or repositioning during manual refresh when the scrollable layout is open

## [0.1.0] - 2026-03-28

### Added

- Initial macOS menu bar implementation for LabForge monitoring
- Recent model status timeline
- Model remaining / budget cards based on LabForge public budget feed
- Optional leaderboard panel
- Right-click menu with refresh, open, visibility toggles, launch at login, and quit
- LabForge-style application icon
- Packaging scripts for `.app` and `.dmg`
