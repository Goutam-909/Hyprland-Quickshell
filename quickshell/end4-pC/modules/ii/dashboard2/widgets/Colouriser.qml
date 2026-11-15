import QtQuick
import QtQuick.Effects
import qs.modules.common

MultiEffect {
    colorization: 1

    Behavior on colorizationColor {
        ColorAnimation {
            duration: Appearance.dashboard.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.standard
        }
    }
}



