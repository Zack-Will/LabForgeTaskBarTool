pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

Rectangle {
    id: root

    required property var modelInfo
    required property int pingMs

    radius: 16
    color: Kirigami.Theme.backgroundColor
    border.color: Qt.alpha(Kirigami.Theme.textColor, 0.12)
    border.width: 1
    implicitHeight: 74

    readonly property color upColor: "#1f9d62"
    readonly property color downColor: "#d64545"
    readonly property color neutralBarColor: Qt.alpha(Kirigami.Theme.textColor, 0.18)
    property var historyBars: root.modelInfo && root.modelInfo.historyBars ? root.modelInfo.historyBars : []
    property real successRatePct: root.modelInfo ? root.modelInfo.successRate * 100 : 0
    property color statusColor: root.modelInfo && root.modelInfo.isUp === true
        ? root.upColor
        : root.modelInfo && root.modelInfo.isUp === false
            ? root.downColor
            : Kirigami.Theme.disabledTextColor
    property color availabilityColor: root.statusColor

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: root.modelInfo ? root.modelInfo.name : "Model"
                color: Kirigami.Theme.textColor
                font.pixelSize: 13
                font.weight: Font.Bold
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: root.modelInfo ? ("Latency " + root.modelInfo.latencyMs + " ms") : "Latency --"
                    color: Kirigami.Theme.disabledTextColor
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }

                Repeater {
                    model: [
                        root.modelInfo ? (root.modelInfo.successCount + "/" + root.modelInfo.totalCount + " success") : "",
                        "Avail " + root.successRatePct.toFixed(2) + "%"
                    ]

                    Text {
                        required property string modelData

                        text: modelData
                        color: root.availabilityColor
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }
            }

            Rectangle {
                radius: 9
                color: Qt.alpha(root.statusColor, 0.14)
                implicitHeight: 24
                implicitWidth: statusLabel.implicitWidth + 14

                Text {
                    id: statusLabel
                    anchors.centerIn: parent
                    text: root.modelInfo && root.modelInfo.isUp ? "UP" : "DOWN"
                    color: root.statusColor
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 2

            Repeater {
                model: root.historyBars

                Rectangle {
                    required property var modelData

                    readonly property var probe: modelData

                    Layout.fillWidth: true
                    implicitWidth: 4
                    implicitHeight: 18
                    radius: 2
                    color: probe === null || probe.ok === null
                        ? root.neutralBarColor
                        : probe.ok === true ? root.upColor : root.downColor
                    opacity: probe ? 0.92 : 1
                }
            }
        }
    }
}
