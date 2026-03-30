pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid

    PlasmaExtras.Representation {
        id: root

    required property PlasmoidItem plasmoidItem
    required property var appState

    component TextActionButton: QQC2.Button {
        flat: true
        hoverEnabled: true
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0

        background: Item {}

        contentItem: Text {
            text: parent.text
            color: parent.enabled
                ? (parent.hovered ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor)
                : Kirigami.Theme.disabledTextColor
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }
    }

    collapseMarginsHint: true
    Layout.minimumWidth: 560
    Layout.maximumWidth: 560
    Layout.minimumHeight: column.implicitHeight + 24
    Layout.maximumHeight: column.implicitHeight + 24

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: 18
        spacing: 10

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                spacing: 2

                Text {
                    text: "LabForge Status"
                    color: Kirigami.Theme.textColor
                    font.pixelSize: 22
                    font.weight: Font.Bold
                }

                Text {
                    text: root.appState.subtitle
                    color: Kirigami.Theme.disabledTextColor
                    font.pixelSize: 11
                }
            }

            Item { Layout.fillWidth: true }

            TextActionButton {
                text: root.appState.loading ? "Refreshing..." : "Refresh"
                enabled: !root.appState.loading
                onClicked: root.plasmoidItem.refreshRequested()
            }

            TextActionButton {
                text: "Open"
                onClicked: Qt.openUrlExternally("https://www.labforge.top/#model-status")
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: root.appState.notices.length > 0
            radius: 16
            color: Qt.alpha(Kirigami.Theme.highlightColor, 0.1)
            border.color: Qt.alpha(Kirigami.Theme.highlightColor, 0.2)
            border.width: 1
            implicitHeight: noticeText.implicitHeight + 20

            Text {
                id: noticeText
                anchors.fill: parent
                anchors.margins: 12
                text: root.appState.notices.join("  ·  ")
                color: Kirigami.Theme.textColor
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }
        }

        Text {
            text: "Budget"
            color: Kirigami.Theme.textColor
            font.pixelSize: 14
            font.weight: Font.Bold
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            BudgetCard {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                budget: root.appState.budgetStatus ? root.appState.budgetStatus.gpt : null
            }

            BudgetCard {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                budget: root.appState.budgetStatus ? root.appState.budgetStatus.claude : null
            }
        }

        Text {
            text: "Model Status"
            color: Kirigami.Theme.textColor
            font.pixelSize: 14
            font.weight: Font.Bold
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 1
            columnSpacing: 10
            rowSpacing: 8

            Repeater {
                model: root.appState.modelStatus ? root.appState.modelStatus.models : []

                ModelCard {
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    modelInfo: modelData
                    pingMs: root.appState.modelStatus ? root.appState.modelStatus.pingMs : -1
                }
            }
        }

        Text {
            visible: Plasmoid.configuration.showLeaderboard
            text: "Leaderboard"
            color: Kirigami.Theme.textColor
            font.pixelSize: 14
            font.weight: Font.Bold
        }

        RowLayout {
            visible: Plasmoid.configuration.showLeaderboard
            Layout.fillWidth: true
            spacing: 10

            Repeater {
                model: [0, 1, 2]

                LeaderboardCard {
                    required property int modelData

                    Layout.fillWidth: true
                    rank: modelData + 1
                    entry: root.appState.leaderboard && root.appState.leaderboard.topEntries.length > modelData
                        ? root.appState.leaderboard.topEntries[modelData]
                        : null
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.appState.footer
            color: root.appState.lastError ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.disabledTextColor
            font.pixelSize: 10
            wrapMode: Text.Wrap
        }
    }
}
