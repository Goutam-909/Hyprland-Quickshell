pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import QtQuick
import QtQuick.Shapes
import Quickshell
import M3Shapes
import qs.modules.common

Item {
    id: root

    readonly property real centerX: width / 2
    readonly property real centerY: height / 2
    readonly property real spacing: Appearance.dashboard.spacing.normal
    readonly property real maxMagnitude: (implicitWidth - cover.implicitWidth) / 2 - spacing

    Shape {
        anchors.fill: parent
        asynchronous: true
        preferredRendererType: Shape.CurveRenderer
        data: bars.instances
    }

    Variants {
        id: bars

        model: Array.from({
            length: Config.options.caelestiaDashboard.dashboard.visualiserBars
        }, (_, i) => i)

        ShapePath {
            id: bar

            required property int modelData
            // Cava.values is bound directly, so this re-evaluates on its own
            // whenever new samples come in - no manual requestPaint needed.
            readonly property real value: Math.max(1e-2, Math.min(1, (Cava.values[modelData] ?? 0) / 100))

            readonly property real angle: modelData * 2 * Math.PI / Config.options.caelestiaDashboard.dashboard.visualiserBars
            readonly property real dist: shapeEdgeDist + value * root.maxMagnitude
            readonly property real shapeEdgeDist: {
                cover.shape.rotation; // Re-evaluate whenever the shape rotates
                const sDist = cover.shape.distanceAtAngle(modelData * 360 / Config.options.caelestiaDashboard.dashboard.visualiserBars + 90);
                return sDist + root.spacing + strokeWidth / 2;
            }
            readonly property real cos: Math.cos(angle)
            readonly property real sin: Math.sin(angle)

            asynchronous: true
            capStyle: ShapePath.RoundCap
            strokeWidth: 360 / Config.options.caelestiaDashboard.dashboard.visualiserBars - Appearance.dashboard.spacing.small / 4
            strokeColor: Appearance.m3colors.m3primary

            startX: root.centerX + shapeEdgeDist * cos
            startY: root.centerY + shapeEdgeDist * sin

            PathLine {
                x: root.centerX + bar.dist * bar.cos
                y: root.centerY + bar.dist * bar.sin
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

    CoverArt {
        id: cover

        anchors.centerIn: parent
        shape.shape: MaterialShape.Cookie9Sided
        implicitWidth: Config.options.caelestiaDashboard.dashboard.sizes.newMediaCoverArtSize
        implicitHeight: Config.options.caelestiaDashboard.dashboard.sizes.newMediaCoverArtSize
    }
}



