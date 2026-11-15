import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import QtQuick
import qs.modules.common

StyledRect {
    id: root

    readonly property alias hovered: mouse.hovered
    readonly property alias pressed: mouse.pressed
    property bool disabled

    function onClicked(event: MouseEvent): void {
    }

    anchors.fill: parent

    color: Appearance.m3colors.m3secondary
    opacity: disabled ? 0 : mouse.pressed ? 0.1 : mouse.hovered ? 0.08 : 0

    MouseArea {
        id: mouse

        property bool hovered

        anchors.fill: parent
        cursorShape: root.disabled ? undefined : Qt.PointingHandCursor
        hoverEnabled: true

        onEntered: hovered = true
        onExited: hovered = false

        onClicked: event => !root.disabled && root.onClicked(event)
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Appearance.dashboard.durations.small
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.standard
        }
    }
}



