pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

Item {
    id: root

    required property PlasmoidItem plasmoidItem
    required property var appState

    readonly property bool horizontalPanel: [
        PlasmaCore.Types.TopEdge,
        PlasmaCore.Types.BottomEdge
    ].indexOf(Plasmoid.location) >= 0
    readonly property int compactPadding: Kirigami.Units.smallSpacing * 2

    implicitWidth: compactRow.implicitWidth + root.compactPadding
    implicitHeight: Math.max(Kirigami.Units.iconSizes.smallMedium, compactRow.implicitHeight)
    Layout.minimumWidth: implicitWidth
    Layout.preferredWidth: implicitWidth
    Layout.minimumHeight: implicitHeight
    Layout.preferredHeight: implicitHeight
    width: implicitWidth
    height: implicitHeight

    MouseArea {
        anchors.fill: parent
        onClicked: root.plasmoidItem.expanded = !root.plasmoidItem.expanded
    }

    RowLayout {
        id: compactRow
        anchors.centerIn: parent
        spacing: Kirigami.Units.smallSpacing

        Rectangle {
            width: Kirigami.Units.iconSizes.smallMedium
            height: width
            radius: width / 2
            color: root.appState.statusColor

            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 6
                height: width
                radius: width / 2
                color: Qt.alpha(Kirigami.Theme.highlightedTextColor, 0.2)
                opacity: 0.25
            }
        }

        Text {
            visible: Plasmoid.configuration.showCompactText && root.horizontalPanel
            text: root.appState.compactLabel
            color: Kirigami.Theme.textColor
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
            font.weight: Font.DemiBold
        }
    }
}
