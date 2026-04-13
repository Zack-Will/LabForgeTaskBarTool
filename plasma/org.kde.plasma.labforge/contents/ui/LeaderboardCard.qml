pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

Rectangle {
    id: root

    required property int rank
    required property var entry

    radius: 14
    color: Kirigami.Theme.backgroundColor
    border.color: Qt.alpha(Kirigami.Theme.textColor, 0.12)
    border.width: 1
    implicitHeight: 98

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 4

        Text {
            text: "#" + root.rank
            color: Kirigami.Theme.highlightColor
            font.pixelSize: 11
            font.weight: Font.Bold
        }

        Text {
            text: root.entry ? root.entry.alias : "No data"
            color: Kirigami.Theme.textColor
            font.pixelSize: 12
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            text: root.entry ? (root.entry.tokens + " tokens") : "--"
            color: Kirigami.Theme.disabledTextColor
            font.pixelSize: 10
        }

        Text {
            visible: !!root.entry
            text: root.entry ? ("Claude " + root.entry.claudeTokens + " | GPT " + root.entry.gptTokens) : ""
            color: Kirigami.Theme.disabledTextColor
            font.pixelSize: 9
            elide: Text.ElideRight
        }
    }
}
