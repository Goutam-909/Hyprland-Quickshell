import QtQuick
import QtQuick.Shapes
import qs.modules.ii.dashboard2.services
import qs.modules.common

// Identical shape logic to ../launcher/Background.qml and
// ../dashboard/Background.qml - kept as its own file for the same reason
// as the launcher's copy: Backgrounds.qml addresses each panel's outline
// by type (Dashboard.Background, Launcher.Background, Wallpaper.Background,
// ...) and wires startX/startY per-panel. Copy stays in sync manually if
// you ever tweak the corner-rounding math in one of them.
ShapePath {
    id: root

    required property Wrapper wrapper
    readonly property real rounding: Config.options.caelestiaDashboard.border.rounding
    readonly property bool flatten: wrapper.height < rounding * 2
    readonly property real roundingY: flatten ? wrapper.height / 2 : rounding

    strokeWidth: -1
    fillColor: Appearance.colors.colLayer0

    PathArc {
        relativeX: root.rounding
        relativeY: -root.roundingY
        radiusX: root.rounding
        radiusY: Math.min(root.rounding, root.wrapper.height)
        direction: PathArc.Counterclockwise
    }

    PathLine {
        relativeX: 0
        relativeY: -(root.wrapper.height - root.roundingY * 2)
    }

    PathArc {
        relativeX: root.rounding
        relativeY: -root.roundingY
        radiusX: root.rounding
        radiusY: Math.min(root.rounding, root.wrapper.height)
    }

    PathLine {
        relativeX: root.wrapper.width - root.rounding * 2
        relativeY: 0
    }

    PathArc {
        relativeX: root.rounding
        relativeY: root.roundingY
        radiusX: root.rounding
        radiusY: Math.min(root.rounding, root.wrapper.height)
    }

    PathLine {
        relativeX: 0
        relativeY: root.wrapper.height - root.roundingY * 2
    }

    PathArc {
        relativeX: root.rounding
        relativeY: root.roundingY
        radiusX: root.rounding
        radiusY: Math.min(root.rounding, root.wrapper.height)
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
