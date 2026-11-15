import qs.modules.ii.dashboard2.services
import QtQuick
import M3Shapes
import qs.modules.common

// Small morphing/rotating loading indicator. Cycles through a pool of
// M3 shapes every 650ms while continuously rotating - same visual
// signature as Caelestia's compiled LoadingIndicator, just without its
// spring-physics overshoot (that needs their ElapsedTimer/FrameAnimation
// spring math, which isn't worth reimplementing for a spinner).
MaterialShape {
    id: root

    readonly property list<int> shapes: containsIcon ? [MaterialShape.SoftBurst, MaterialShape.Cookie9Sided, MaterialShape.Pill, MaterialShape.Sunny, MaterialShape.Cookie4Sided, MaterialShape.Oval] : [MaterialShape.SoftBurst, MaterialShape.Cookie9Sided, MaterialShape.Pentagon, MaterialShape.Pill, MaterialShape.Sunny, MaterialShape.Cookie4Sided, MaterialShape.Oval]
    property int shapeIndex: 0
    property bool animated: true
    property bool containsIcon: false

    implicitSize: 38
    color: Appearance.m3colors.m3primary
    shape: shapes[shapeIndex]

    Behavior on shape {
        NumberAnimation {
            duration: 550
            easing.type: Easing.OutBack
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: Appearance.dashboard.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.standard
        }
    }

    Timer {
        interval: 650
        repeat: true
        triggeredOnStart: true
        running: root.animated
        onTriggered: root.shapeIndex = (root.shapeIndex + 1) % root.shapes.length
    }

    RotationAnimation on rotation {
        running: root.animated
        from: 0
        to: 360
        easing.type: Easing.Linear
        loops: Animation.Infinite
        duration: 4666
    }
}



