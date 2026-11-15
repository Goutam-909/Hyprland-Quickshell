import qs.modules.ii.dashboard2.services
import QtQuick
import qs.modules.common

Item {
    id: root

    property real value: 0 // 0..1
    property bool indeterminate: false
    property color fgColour: Appearance.m3colors.m3primary
    property color bgColour: Appearance.m3colors.m3primaryContainer

    implicitWidth: 200
    implicitHeight: 4

    readonly property real gap: Appearance.dashboard.spacing.small
    readonly property real clampedValue: Math.max(0, Math.min(1, value))

    Behavior on fgColour {
        ColorAnimation {
            duration: Appearance.dashboard.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.standard
        }
    }

    // Remaining track
    StyledRect {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        implicitWidth: root.indeterminate ? parent.width : parent.width - fill.implicitWidth - root.gap
        implicitHeight: parent.height

        radius: Appearance.rounding.full
        color: root.bgColour
    }

    // Small end-cap dot, matching the little circle Caelestia draws at
    // the tip of the remaining track.
    StyledRect {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        implicitWidth: parent.height
        implicitHeight: parent.height
        radius: Appearance.rounding.full
        color: root.fgColour
        visible: !root.indeterminate
    }

    // Filled portion
    StyledRect {
        id: fill

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        implicitWidth: root.indeterminate ? parent.width * 0.35 : parent.width * root.clampedValue
        implicitHeight: parent.height

        radius: Appearance.rounding.full
        color: root.fgColour

        x: root.indeterminate ? indAnim.x : 0

        Behavior on implicitWidth {
            enabled: !root.indeterminate
            NumberAnimation {
                duration: Appearance.dashboard.durations.large
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.standard
            }
        }

        SequentialAnimation {
            running: root.indeterminate
            loops: Animation.Infinite

            NumberAnimation {
                id: indAnim
                target: fill
                property: "x"
                from: -fill.implicitWidth
                to: root.width
                duration: 1100
                easing.type: Easing.InOutSine
            }
        }
    }
}



