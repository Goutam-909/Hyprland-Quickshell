import qs.modules.ii.dashboard2.services
import QtQuick
import QtQuick.Controls
import qs.modules.common

ScrollBar {
    id: root

    contentItem: StyledRect {
        implicitWidth: 6
        opacity: root.pressed ? 1 : root.policy === ScrollBar.AlwaysOn || (root.active && root.size < 1) ? 0.8 : 0
        radius: Appearance.rounding.full
        color: Appearance.m3colors.m3secondary

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.dashboard.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.standard
            }
        }
    }

    MouseArea {
        z: -1
        anchors.fill: parent
        onWheel: event => {
            if (event.angleDelta.y > 0)
                root.decrease();
            else if (event.angleDelta.y < 0)
                root.increase();
        }
    }
}



