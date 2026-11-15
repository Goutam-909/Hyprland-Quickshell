pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.services
import QtQuick
import QtQuick.Shapes
import qs.modules.common

// Matches Caelestia's real CircularProgress design: the filled portion
// and the remaining (background) arc are separated by a small gap, with
// a small dot capping the tip of the filled arc, and the remaining arc
// fades out smoothly as it shrinks to nothing near 100%. The one thing
// left out is the wavy variant - that needs their compiled WavyLine -
// but Caelestia's default (`wavy: false`) is a plain arc anyway, which
// is exactly what this draws.
Item {
    id: root

    property real value // 0..1
    property int startAngle: -90
    property int sweepAngle: 360
    property int strokeWidth: Config.options.caelestiaDashboard.dashboard.sizes.perfRingThickness
    property int padding: 0
    property int spacing: Appearance.dashboard.spacing.small
    property color fgColour: Appearance.m3colors.m3primary
    property color bgColour: Appearance.m3colors.m3primaryContainer
    property bool hasEndIndicator: true

    readonly property real size: Math.min(width, height)
    readonly property real arcRadius: (size - padding - strokeWidth) / 2
    property real clampedVal: Math.max(1 / 360, Math.min(1, isNaN(value) ? 0 : value)) // Not readonly - animated
    readonly property real gapAngle: ((spacing + strokeWidth) / (arcRadius || 1)) * (180 / Math.PI)
    readonly property real dotAngleRad: (startAngle + clampedVal * sweepAngle) * Math.PI / 180
    readonly property real remainingSweep: Math.max(1 / 360, sweepAngle * (1 - clampedVal) - gapAngle * (sweepAngle < 360 ? 1 : 2))

    readonly property real thickness: strokeWidth * 2 // For consumers
    property int implicitSize

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    Behavior on fgColour {
        ColorAnimation {
            duration: Appearance.dashboard.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.standard
        }
    }

    Behavior on clampedVal {
        NumberAnimation {
            duration: Appearance.dashboard.durations.large
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.standard
        }
    }

    // Filled portion - full extent from startAngle, no gap subtracted
    // on this side (matches the original: only the remaining arc yields
    // ground to the gap).
    Shape {
        anchors.fill: parent
        asynchronous: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.fgColour
            strokeWidth: root.strokeWidth
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                radiusX: root.arcRadius
                radiusY: root.arcRadius
                centerX: root.size / 2
                centerY: root.size / 2
                startAngle: root.startAngle
                sweepAngle: root.clampedVal * root.sweepAngle
            }

            Behavior on strokeColor {
                ColorAnimation {
                    duration: Appearance.dashboard.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.standard
                }
            }
        }
    }

    // Remaining (background) arc - starts a gap after the filled
    // portion ends, and fades out as it shrinks towards nothing.
    Shape {
        anchors.fill: parent
        asynchronous: true
        preferredRendererType: Shape.CurveRenderer
        opacity: Math.min(1, remainingArc.sweepAngle)

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.bgColour
            strokeWidth: Math.min(1, remainingArc.sweepAngle) * root.strokeWidth
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                id: remainingArc

                radiusX: root.arcRadius
                radiusY: root.arcRadius
                centerX: root.size / 2
                centerY: root.size / 2
                startAngle: root.startAngle + root.clampedVal * root.sweepAngle + root.gapAngle
                sweepAngle: root.remainingSweep
            }

            Behavior on strokeColor {
                ColorAnimation {
                    duration: Appearance.dashboard.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.standard
                }
            }
        }
    }

    // Small dot capping the tip of the filled arc, right before the gap.
    Loader {
        active: root.hasEndIndicator

        x: root.size / 2 + root.arcRadius * Math.cos(root.dotAngleRad) - width / 2
        y: root.size / 2 + root.arcRadius * Math.sin(root.dotAngleRad) - height / 2

        sourceComponent: StyledRect {
            radius: Appearance.rounding.full
            color: root.fgColour
            opacity: Math.min(1, remainingArc.sweepAngle)
            implicitWidth: Math.min(1, remainingArc.sweepAngle) * Math.min(4, root.strokeWidth)
            implicitHeight: Math.min(1, remainingArc.sweepAngle) * Math.min(4, root.strokeWidth)
        }
    }
}



