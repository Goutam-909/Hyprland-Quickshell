import QtQuick
import Quickshell
import qs.modules.common

// Independent from ../launcher/Wrapper.qml on purpose. The wallpaper
// carousel used to live inside the launcher's Content.qml/Wrapper.qml as
// a third mode (alongside AppList/ClipboardList), sharing its
// implicitWidth/implicitHeight and open/close state - which meant any
// launcher-side sizing quirk could bleed into the wallpaper panel (and
// vice versa). This wrapper only knows about visibilities.wallpaper and
// only sizes itself off its own Content below; the launcher wrapper no
// longer has any concept of wallpaper mode at all.
//
// Same open/close technique as ../launcher/Wrapper.qml and
// ../dashboard/Wrapper.qml: implicitHeight is state-driven and animated
// with a NumberAnimation, while implicitWidth just tracks the content's
// natural width (never animated). Because this Item ends up as a direct
// child of Panels.qml's root, it's automatically picked up by
// Drawers.qml's per-panel Region mask, so the layershell surface only
// ever punches a hole exactly the size of however tall we currently are.
Item {
    id: root

    required property PersistentProperties visibilities

    visible: height > 0
    implicitWidth: content.implicitWidth
    implicitHeight: 0

    states: State {
        name: "visible"
        when: root.visibilities.wallpaper

        PropertyChanges {
            root.implicitHeight: content.implicitHeight
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

    Content {
        id: content

        visibilities: root.visibilities

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
