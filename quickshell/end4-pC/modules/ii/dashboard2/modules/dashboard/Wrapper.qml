import QtQuick
import Quickshell
import qs.modules.common

Item {
    id: root

    required property PersistentProperties visibilities

    readonly property bool shouldBeActive: root.visibilities.dashboard

    visible: height > 0
    implicitHeight: 0
    // height never auto-tracks implicitHeight in QtQuick - without this,
    // `visible` and anything reading panel.height (Interactions.qml's
    // hover-trigger sizing) were working off a stale/frozen value.
    height: implicitHeight
    implicitWidth: contentLoader.item?.implicitWidth ?? 0

    states: State {
        name: "visible"
        when: root.shouldBeActive

        PropertyChanges {
            root.implicitHeight: contentLoader.item?.implicitHeight ?? 0
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            NumberAnimation {
                target: root
                property: "implicitHeight"
                duration: Appearance.dashboard.durations.expressiveDefaultSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
            }
        },
        Transition {
            from: "visible"
            to: ""

            NumberAnimation {
                target: root
                property: "implicitHeight"
                duration: Appearance.dashboard.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.emphasized
            }
        }
    ]

    Loader {
        id: contentLoader

        // The only existence switch for the whole dashboard. Synchronous -
        // no incubation phase to race, no pop-in. Active while it should
        // be open, OR while still visible (mid close-animation, which now
        // actually resolves correctly since height tracks implicitHeight).
        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            visibilities: root.visibilities
        }
    }
}
