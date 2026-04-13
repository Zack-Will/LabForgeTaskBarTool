#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_DIR="$ROOT_DIR/plasma/org.kde.plasma.labforge"

if ! command -v kpackagetool6 >/dev/null 2>&1; then
  echo "kpackagetool6 is required." >&2
  exit 1
fi

if kpackagetool6 --type Plasma/Applet --list | grep -q '^org.kde.plasma.labforge\b'; then
  kpackagetool6 --type Plasma/Applet --upgrade "$PACKAGE_DIR"
else
  kpackagetool6 --type Plasma/Applet --install "$PACKAGE_DIR"
fi

echo "Installed org.kde.plasma.labforge"
echo "Open Plasma Add or Manage Widgets and search for: LabForge Status"
