pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.services
import QtQuick
import QtQuick.Controls
import qs.modules.common

TextField {
    id: root

    color: Appearance.m3colors.m3secondary
    placeholderTextColor: Appearance.colors.colPrimary
    font.family: Appearance.font.family.main
    font.pointSize: Appearance.dashboard.fontSize.smaller

    cursorDelegate: StyledRect {
        id: cursor

        property bool disableBlink

        implicitWidth: 2
        color: Appearance.m3colors.m3primary
        radius: Appearance.rounding.normal
        onXChanged: {
            opacity = 1;
            disableBlink = true;
            enableBlink.start();
        }

        Timer {
            id: enableBlink

            interval: 100
            onTriggered: cursor.disableBlink = false
        }

        Timer {
            running: root.cursorVisible && !cursor.disableBlink
            repeat: true
            interval: 500
            onTriggered: parent.opacity = parent.opacity === 1 ? 0 : 1
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.dashboard.durations.small
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.standard
            }
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: Appearance.dashboard.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.standard
        }
    }

    Behavior on placeholderTextColor {
        ColorAnimation {
            duration: Appearance.dashboard.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.standard
        }
    }
}



