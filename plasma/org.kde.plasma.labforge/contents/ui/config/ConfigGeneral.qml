pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_showLeaderboard: showLeaderboard.checked
    property alias cfg_showCompactText: showCompactText.checked

    QQC2.CheckBox {
        id: showLeaderboard
        Kirigami.FormData.label: "Popup:"
        text: "Show leaderboard"
    }

    QQC2.CheckBox {
        id: showCompactText
        Kirigami.FormData.label: "Panel:"
        text: "Show compact text"
    }
}
