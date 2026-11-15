pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.services
import QtQuick
import qs.modules.common

Text {
    id: root

    property bool animate: false
    property string animateProp: "scale"
    property real animateFrom: 0
    property real animateTo: 1
    property int animateDuration: Appearance.dashboard.durations.normal

    renderType: Text.NativeRendering
    textFormat: Text.PlainText
    color: Appearance.m3colors.m3secondary
    font.family: Appearance.font.family.main
    font.pointSize: Appearance.dashboard.fontSize.smaller

    Behavior on color {
        ColorAnimation {
            duration: Appearance.dashboard.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.standard
        }
    }

    Behavior on text {
        enabled: root.animate

        SequentialAnimation {
            Anim {
                to: root.animateFrom
                easing.bezierCurve: Appearance.animationCurves.standardAccel
            }
            PropertyAction {}
            Anim {
                to: root.animateTo
                easing.bezierCurve: Appearance.animationCurves.standardDecel
            }
        }
    }

    component Anim: NumberAnimation {
        target: root
        property: root.animateProp
        duration: root.animateDuration / 2
        easing.type: Easing.BezierSpline
    }
}



