pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import QtQuick
import QtQuick.Effects
import M3Shapes
import qs.modules.common
import qs.services

Item {
    id: root

    readonly property alias shape: shape

    property color fallbackColour: Appearance.m3colors.m3primaryContainer

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        blurMax: 1
        shadowColor: Appearance.m3colors.m3shadow
        shadowOpacity: 0.3
    }

    Behavior on fallbackColour {
        ColorAnimation {
            duration: Appearance.dashboard.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.standard
        }
    }

    Item {
        id: shapeWrapper

        anchors.fill: parent
        layer.enabled: true

        MaterialShape {
            id: shape

            implicitSize: root.width
            shape: MaterialShape.Cookie12Sided
            color: root.fallbackColour

            NumberAnimation on rotation {
                running: MprisController.activePlayer?.isPlaying ?? false
                from: 360
                to: 0
                duration: 23500
                easing.type: Easing.Linear
                loops: Animation.Infinite
            }
        }
    }

    MaterialIcon {
        anchors.centerIn: parent

        text: image.status === Image.Error ? "broken_image" : "art_track"
        color: Appearance.m3colors.m3secondary
        font.pointSize: (parent.width * 0.35) || 1
        opacity: image.status === Image.Null || image.status === Image.Error ? 1 : 0
        animate: true

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.dashboard.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.standard
            }
        }
    }

    Loader {
        anchors.centerIn: parent
        asynchronous: true
        active: opacity > 0
        opacity: image.status === Image.Loading ? 1 : 0

        sourceComponent: LoadingIndicator {
            implicitSize: (root.width * 0.3) || 1
            color: Appearance.m3colors.m3primaryContainer
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.dashboard.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.standard
            }
        }
    }

    Image {
        id: image

        anchors.fill: parent

        source: MprisController.activePlayer?.trackArtUrl ?? ""
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: width
        sourceSize.height: height

        layer.enabled: true
        layer.effect: Mask {
            maskSource: shapeWrapper
        }
    }
}



