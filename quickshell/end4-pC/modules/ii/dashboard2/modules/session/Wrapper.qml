import qs.modules.ii.dashboard2.services
import Quickshell
import QtQuick
import qs.modules.common

Item {
    id: root

    required property PersistentProperties visibilities

    visible: width > 0
    implicitWidth: 0
    implicitHeight: content.implicitHeight

    states: State {
        name: "visible"
        when: root.visibilities.session

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
                duration: root.visibilities.osd ? Appearance.dashboard.durations.expressiveFastSpatial : Appearance.dashboard.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.visibilities.osd ? Appearance.animationCurves.expressiveFastSpatial : Appearance.animationCurves.emphasized
            }
        }
    ]

    Content {
        id: content

        visibilities: root.visibilities
    }
}



