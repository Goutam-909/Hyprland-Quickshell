pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.services
import QtQuick
import M3Shapes
import qs.modules.common
import qs.services

// Slow-drifting Material shapes behind the media tab, only animating
// while something is actually playing (so it doesn't waste cycles
// sitting idle).
Item {
    id: root

    readonly property list<int> shapePool: [MaterialShape.Circle, MaterialShape.Cookie4Sided, MaterialShape.Cookie6Sided, MaterialShape.Cookie7Sided, MaterialShape.Cookie9Sided, MaterialShape.Cookie12Sided, MaterialShape.Sunny, MaterialShape.VerySunny, MaterialShape.SoftBurst, MaterialShape.Pentagon, MaterialShape.Gem, MaterialShape.Arch, MaterialShape.Arrow, MaterialShape.Pill, MaterialShape.Triangle, MaterialShape.Fan, MaterialShape.Oval]

    property int count: 14
    property real minSize: 36
    property real maxSize: 124
    property real minSpeed: 4
    property real maxSpeed: 18
    property real minRotSpeed: -12
    property real maxRotSpeed: 12
    property list<real> lightOpacities: [0.34, 0.34, 0.08, 0.2]
    property list<real> darkOpacities: [0.16, 0.16, 0.04, 0.16]

    function rand(min: real, max: real): real {
        return min + Math.random() * (max - min);
    }

    function signedRand(min: real, max: real): real {
        return rand(min, max) * (Math.random() < 0.5 ? -1 : 1);
    }

    clip: true
    Component.onCompleted: shapes.model = count

    Repeater {
        id: shapes

        DriftingShape {}
    }

    FrameAnimation {
        running: root.visible && root.width > 0 && root.height > 0 && (MprisController.activePlayer?.isPlaying ?? false)
        onTriggered: {
            const dt = frameTime;
            for (let i = 0; i < shapes.count; i++) {
                const s = shapes.itemAt(i);
                if (!s)
                    continue;

                s.x += s.vx * dt;
                s.y += s.vy * dt;
                s.rotation += s.vr * dt;

                if (s.x + s.width < 0)
                    s.x = root.width;
                else if (s.x > root.width)
                    s.x = -s.width;

                if (s.y + s.height < 0)
                    s.y = root.height;
                else if (s.y > root.height)
                    s.y = -s.height;
            }
        }
    }

    component DriftingShape: MaterialShape {
        id: shapeItem

        required property int index

        property real vx: root.signedRand(root.minSpeed, root.maxSpeed)
        property real vy: root.signedRand(root.minSpeed, root.maxSpeed)
        property real vr: root.rand(root.minRotSpeed, root.maxRotSpeed)
        readonly property int colourIdx: Math.floor(Math.random() * 4)

        implicitSize: root.minSize + (index / root.count) * (root.maxSize - root.minSize)
        shape: root.shapePool[Math.floor(Math.random() * root.shapePool.length)]
        color: [Appearance.m3colors.m3primaryContainer, Appearance.m3colors.m3error, Appearance.m3colors.m3tertiary, Appearance.m3colors.m3surfaceContainer][colourIdx]
        opacity: !Appearance.m3colors.darkmode ? root.lightOpacities[colourIdx] : root.darkOpacities[colourIdx]
        rotation: root.rand(0, 360)

        Component.onCompleted: {
            x = root.rand(0, root.width - implicitSize);
            y = root.rand(0, root.height - implicitSize);
        }

        Behavior on color {
            ColorAnimation {
                duration: Appearance.dashboard.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.standard
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.dashboard.durations.large
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.standard
            }
        }
    }
}



