// CircleToggleButton.qml
// macOS-style round icon-only toggle. Generic and reusable — each instance
// gets its own icon(s)/active-state/click handling from the caller.
//
// Two modes:
//  - Pass `iconOn`/`iconOff` + bind `active` externally for a real toggle
//    (e.g. the Dark/Light mode button).
//  - Leave `iconOn === iconOff` (just set `icon`) and `toggleLocal: true`
//    for a placeholder that just flips its own look when clicked, with no
//    backend yet — swap in real wiring later via onClicked.
import QtQuick
import Quickshell
import qs.common

Item {
    id: root
    implicitWidth: 70
    implicitHeight: 70

    property string icon: "add"        // used when iconOn/iconOff aren't set
    property string iconOn: icon
    property string iconOff: icon
    property bool active: false
    property bool toggleLocal: false   // flips `active` itself on click (for placeholders with no backend yet)

    signal clicked()

    Rectangle {
        id: circle
        anchors.fill: parent
        radius: width / 2
        color: mouseArea.pressed
        ? Appearance.colors.colLayer2Active
        : (mouseArea.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colSurfaceContainerHigh)
        scale: mouseArea.pressed ? 0.92 : 1

        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.centerIn: parent
            width: 40
            height: 40
            radius: 20
            color: root.active
            ? Appearance.colors.colPrimary
            : Appearance.colors.colSurfaceContainerHighest

            Behavior on color { ColorAnimation { duration: 200 } }

            MaterialSymbol {
                anchors.centerIn: parent
                icon: root.active ? root.iconOn : root.iconOff
                iconSize: 20
                color: root.active
                ? Appearance.colors.colOnPrimary
                : Appearance.colors.colOnSurfaceVariant
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.toggleLocal) root.active = !root.active
                root.clicked()
            }
        }
    }
}
