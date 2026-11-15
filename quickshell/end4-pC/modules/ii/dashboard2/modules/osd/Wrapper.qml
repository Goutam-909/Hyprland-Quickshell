import qs.modules.ii.dashboard2.services
import Quickshell
import QtQuick
import qs.modules.common
import qs.services

Item {
    id: root

    required property ShellScreen screen
    required property bool visibility

    visible: width > 0 // visibilities.osd
    implicitWidth: 0
    implicitHeight: content.implicitHeight

    states: State {
        name: "visible"
        when: root.visibility

        PropertyChanges {
            root.implicitWidth: content.implicitWidth
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            NumberAnimation {
                target: root
                property: "implicitWidth"
                duration: Appearance.dashboard.durations.expressiveFastSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
            }
        },
        Transition {
            from: "visible"
            to: ""

            NumberAnimation {
                target: root
                property: "implicitWidth"
                duration: Appearance.dashboard.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasized
            }
        }
    ]

    Content {
        id: content

        monitor: Brightness.getMonitorForScreen(root.screen)
    }
}



