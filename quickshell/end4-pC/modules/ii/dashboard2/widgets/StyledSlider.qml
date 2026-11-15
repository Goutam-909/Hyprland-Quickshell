pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.services
import QtQuick
import QtQuick.Templates as T
import qs.modules.common

T.Slider {
    id: root

    property color fgColour: enabled ? Appearance.m3colors.m3primary : Qt.alpha(Appearance.m3colors.m3secondary, 0.38)
    property color bgColour: enabled ? Appearance.m3colors.m3primaryContainer : Qt.alpha(Appearance.m3colors.m3secondary, 0.1)
    property int barRadius: Appearance.rounding.normal
    property bool interactionOnMove: true

    property real pos: visualPosition
    property real filledWidth

    signal interaction(real v)

    Component.onCompleted: filledWidth = Qt.binding(() => (width - handle.implicitWidth - handle.anchors.leftMargin) * pos)

    implicitWidth: 200
    implicitHeight: 12

    contentItem: Item {
        anchors.fill: parent

        StyledRect {
            id: remaining

            anchors.left: handle.right
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Appearance.dashboard.spacing.small

            implicitHeight: parent.height * (parent.height <= 12 ? opacity : Math.min(opacity * 2, 1))
            opacity: Math.min(width, 12) / 12

            radius: root.barRadius
            topLeftRadius: Appearance.rounding.small / 2
            bottomLeftRadius: Appearance.rounding.small / 2
            color: root.bgColour
        }

        StyledRect {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 4 * remaining.opacity

            implicitWidth: implicitHeight
            implicitHeight: 4 * remaining.opacity
            opacity: remaining.opacity

            radius: Appearance.rounding.full
            color: root.fgColour
        }

        StyledRect {
            id: handle

            anchors.left: filled.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Appearance.dashboard.spacing.small

            implicitWidth: 4
            implicitHeight: {
                const t = Math.max(0, Math.min(1, (parent.height - 12) / 16));
                const lerp = (a, b) => a + (b - a) * t;
                return parent.height * (mouse.pressed ? lerp(3.5, 1.5) : lerp(3, 1.2));
            }

            radius: Appearance.rounding.full
            color: root.fgColour

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: Appearance.dashboard.durations.small
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.standard
                }
            }
        }

        StyledRect {
            id: filled

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            implicitWidth: root.filledWidth
            implicitHeight: root.height

            radius: root.barRadius
            topRightRadius: Appearance.rounding.small / 2
            bottomRightRadius: Appearance.rounding.small / 2
            color: root.fgColour
        }
    }

    Binding {
        id: posBinding

        target: root
        property: "pos"
        value: Math.max(0, Math.min(1, mouse.pressStartPos + mouse.dragMovement))
        when: mouse.pressed
    }

    MouseArea {
        id: mouse

        property real pressStartX
        property real pressStartPos
        property real dragMovement

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        preventStealing: true
        implicitHeight: handle.implicitHeight
        cursorShape: root.enabled ? Qt.PointingHandCursor : undefined
        enabled: root.enabled

        onPressed: event => {
            widthBehavior.enabled = false;
            pressStartX = event.x;
            pressStartPos = root.visualPosition;
        }
        onPositionChanged: event => {
            dragMovement = (event.x - pressStartX) / width;
            if (root.interactionOnMove)
                root.interaction(posBinding.value);
        }
        onReleased: event => {
            const clickPos = event.x / width;
            const finalPos = mouse.dragMovement !== 0 ? posBinding.value : Math.max(0, Math.min(1, clickPos));
            root.interaction(finalPos);
            widthBehavior.enabled = true;
            dragMovement = 0;
        }
    }

    Behavior on filledWidth {
        id: widthBehavior

        NumberAnimation {
            duration: Appearance.dashboard.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.standard
        }
    }
}



