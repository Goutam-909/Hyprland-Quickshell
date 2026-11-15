import qs.modules.ii.dashboard2.services
import QtQuick
import QtQuick.Shapes
import qs.modules.common

ShapePath {
    id: root

    required property Wrapper wrapper
    readonly property real rounding: Config.options.caelestiaDashboard.border.rounding
    readonly property bool flatten: wrapper.width < rounding * 2
    readonly property real roundingX: flatten ? wrapper.width / 2 : rounding

    strokeWidth: -1
    fillColor: Appearance.colors.colLayer0

    PathArc {
        relativeX: root.roundingX
        relativeY: root.rounding
        radiusX: Math.min(root.rounding, root.wrapper.width)
        radiusY: root.rounding
        direction: PathArc.Counterclockwise
    }
    PathLine {
        relativeX: (root.wrapper.width - root.roundingX * 2)
        relativeY: 0
    }
    PathArc {
        relativeX: root.roundingX
        relativeY: root.rounding
        radiusX: Math.min(root.rounding, root.wrapper.width)
        radiusY: root.rounding
    }
    PathLine {
        relativeX: 0
        relativeY: root.wrapper.height - root.rounding * 2
    }
    PathArc {
        relativeX: -root.roundingX
        relativeY: root.rounding
        radiusX: Math.min(root.rounding, root.wrapper.width)
        radiusY: root.rounding
    }
    PathLine {
        relativeX: -(root.wrapper.width - root.roundingX * 2)
        relativeY: 0
    }
    PathArc {
        relativeX: -root.roundingX
        relativeY: root.rounding
        radiusX: Math.min(root.rounding, root.wrapper.width)
        radiusY: root.rounding
        direction: PathArc.Counterclockwise
    }

    Behavior on fillColor {
        ColorAnimation {
            duration: Appearance.dashboard.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.standard
        }
    }
}



