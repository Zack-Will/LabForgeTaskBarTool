pragma ComponentBehavior: Bound

import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

import "../code/Data.js" as Data

PlasmoidItem {
    id: root

    property var modelStatus: null
    property var budgetStatus: null
    property var leaderboard: null
    property var notices: []
    property string lastError: ""
    property bool loading: false

    readonly property string compactLabel: modelStatus ? (modelStatus.upCount + "/" + modelStatus.totalCount) : "--/--"
    readonly property color statusColor: {
        if (!modelStatus) {
            return "#7d8fa3";
        }
        return modelStatus.upCount === modelStatus.totalCount ? "#1f9d62" : "#d7891d";
    }
    readonly property string shortUpdatedAt: {
        if (!modelStatus || !modelStatus.updatedAt) {
            return "--";
        }
        var normalized = modelStatus.updatedAt.replace("T", " ");
        var parts = normalized.split(" ");
        if (parts.length < 2) {
            return normalized;
        }
        var dateParts = parts[0].split("-");
        var timeParts = parts[1].split(":");
        if (dateParts.length !== 3 || timeParts.length < 2) {
            return normalized;
        }
        return dateParts[1] + "-" + dateParts[2] + " " + timeParts[0] + ":" + timeParts[1];
    }
    readonly property string subtitle: {
        if (lastError.length > 0) {
            return "Refresh failed: " + lastError;
        }
        if (loading) {
            return "Refreshing LabForge feeds...";
        }
        if (!modelStatus) {
            return "Waiting for first update...";
        }
        return compactLabel + " online  |  Ping " + modelStatus.pingMs + " ms  |  Updated " + shortUpdatedAt;
    }
    readonly property string footer: {
        var parts = [];
        if (modelStatus) {
            parts.push("Status " + modelStatus.updatedAt);
        }
        if (budgetStatus) {
            parts.push("Budget " + budgetStatus.updatedAt);
        }
        if (leaderboard && leaderboard.updatedAt) {
            parts.push("Leaderboard " + leaderboard.updatedAt);
        }
        if (lastError.length > 0) {
            parts.push("Error: " + lastError);
        }
        return parts.length > 0 ? parts.join("  |  ") : "No data yet";
    }

    signal refreshRequested()

    Plasmoid.icon: "network-server-symbolic"
    Plasmoid.title: "LabForge Status"
    Plasmoid.status: modelStatus && modelStatus.upCount === modelStatus.totalCount
        ? PlasmaCore.Types.ActiveStatus
        : PlasmaCore.Types.PassiveStatus
    switchWidth: compactRepresentationItem ? compactRepresentationItem.implicitWidth : Kirigami.Units.gridUnit * 2
    switchHeight: compactRepresentationItem ? compactRepresentationItem.implicitHeight : Kirigami.Units.gridUnit * 2

    compactRepresentation: CompactRepresentation {
        plasmoidItem: root
        appState: root
    }

    fullRepresentation: FullRepresentation {
        plasmoidItem: root
        appState: root
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: "Refresh"
            icon.name: "view-refresh"
            onTriggered: root.reload()
        },
        PlasmaCore.Action {
            text: "Open LabForge"
            icon.name: "globe"
            onTriggered: Qt.openUrlExternally("https://www.labforge.top/#model-status")
        }
    ]

    function reload() {
        loading = true;
        Data.loadAll(function(result) {
            root.modelStatus = result.modelStatus;
            root.budgetStatus = result.budgetStatus;
            root.leaderboard = result.leaderboard;
            root.notices = result.notices;
            root.lastError = "";
            root.loading = false;
        }, function(message) {
            root.lastError = message;
            root.loading = false;
        });
    }

    onRefreshRequested: reload()

    Component.onCompleted: reload()

    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: root.reload()
    }
}
