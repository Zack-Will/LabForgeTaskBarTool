pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

Rectangle {
    id: root

    required property var budget

    radius: 16
    color: Kirigami.Theme.backgroundColor
    border.color: Qt.alpha(Kirigami.Theme.textColor, 0.12)
    border.width: 1

    property real ratio: root.budget ? root.budget.usageRatio : 0
    property color accentColor: root.ratio >= 0.95 ? Kirigami.Theme.negativeTextColor : root.ratio >= 0.7 ? Kirigami.Theme.neutralTextColor : Kirigami.Theme.positiveTextColor
    property color accentSoft: Qt.alpha(root.accentColor, 0.14)
    property string badgeText: root.ratio >= 0.95 ? "High" : root.ratio >= 0.7 ? "Busy" : "OK"

    implicitHeight: 88

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 5

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: root.budget ? root.budget.title : "Budget"
                color: Kirigami.Theme.textColor
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            Text {
                Layout.fillWidth: true
                visible: !!(root.budget && root.budget.description)
                text: root.budget ? root.budget.description : ""
                color: Kirigami.Theme.disabledTextColor
                wrapMode: Text.NoWrap
                maximumLineCount: 1
                elide: Text.ElideRight
                font.pixelSize: 10
            }

            Rectangle {
                radius: 9
                color: root.accentSoft
                implicitHeight: badgeLabel.implicitHeight + 6
                implicitWidth: badgeLabel.implicitWidth + 14

                Text {
                    id: badgeLabel
                    anchors.centerIn: parent
                    text: root.badgeText
                    color: root.accentColor
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: root.budget ? ("Spent $" + root.budget.spent.toFixed(2)) : "Spent --"
                color: Kirigami.Theme.textColor
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }

            Text {
                text: root.budget ? (" / Budget $" + Number(root.budget.budget).toFixed(0)) : ""
                color: Kirigami.Theme.disabledTextColor
                font.pixelSize: 10
            }

            Item { Layout.fillWidth: true }

            Text {
                text: root.budget ? ("Left $" + root.budget.remaining.toFixed(2)) : ""
                color: Kirigami.Theme.disabledTextColor
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }

            Text {
                text: root.budget ? ("  " + (root.ratio * 100).toFixed(2) + "% used") : ""
                color: root.accentColor
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 8
            radius: 4
            color: Qt.alpha(Kirigami.Theme.textColor, 0.08)

            Rectangle {
                width: parent.width * root.ratio
                height: parent.height
                radius: 4
                color: root.accentColor
            }
        }
    }
}
