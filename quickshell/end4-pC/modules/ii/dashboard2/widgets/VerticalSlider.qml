import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import qs.modules.common
import qs.modules.common.functions

Slider {
    id: root

    required property string icon
    property real oldValue

    orientation: Qt.Vertical

    background: StyledRect {
        color: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainer, Appearance.contentTransparency)
        radius: Appearance.rounding.full

        StyledRect {
            anchors.left: parent.left
            anchors.right: parent.right

            y: root.handle.y
            implicitHeight: parent.height - y

            color: ColorUtils.transparentize(Appearance.m3colors.m3tertiary, Appearance.contentTransparency)
            radius: Appearance.rounding.full
        }
    }

    handle: Item {
        id: handle

        property bool moving

        y: root.visualPosition * (root.availableHeight - height)
        implicitWidth: root.width
        implicitHeight: root.width

        RectangularShadow {
            anchors.fill: parent
            radius: rect.radius
            color: Appearance.m3colors.m3shadow
            blur: 5
            spread: 0
        }

        StyledRect {
            id: rect

            anchors.fill: parent

            color: ColorUtils.transparentize(Appearance.m3colors.m3secondary, Appearance.contentTransparency)
            radius: Appearance.rounding.full

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPressed: event => event.accepted = false
            }

            MaterialIcon {
                id: icon

                property bool moving: handle.moving

                function update(): void {
                    animate = !moving;
                    text = moving ? Qt.binding(() => Math.round(root.value * 100)) : Qt.binding(() => root.icon);
                    font.pointSize = moving ? Appearance.dashboard.fontSize.small : Appearance.dashboard.fontSize.normal;
                    font.family = moving ? Appearance.font.family.main : Appearance.font.family.iconMaterial;
                }

                animate: true
                text: root.icon
                color: Appearance.m3colors.m3surface
                anchors.centerIn: parent

                Behavior on moving {
                    SequentialAnimation {
                        NumberAnimation {
                            target: icon
                            property: "scale"
                            from: 1
                            to: 0
                            duration: Appearance.dashboard.durations.normal / 2
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animationCurves.standardAccel
                        }
                        ScriptAction {
                            script: icon.update()
                        }
                        NumberAnimation {
                            target: icon
                            property: "scale"
                            from: 0
                            to: 1
                            duration: Appearance.dashboard.durations.normal / 2
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animationCurves.standardDecel
                        }
                    }
                }
            }
        }
    }

    onPressedChanged: handle.moving = pressed

    onValueChanged: {
        if (Math.abs(value - oldValue) < 0.01)
            return;
        oldValue = value;
        handle.moving = true;
        stateChangeDelay.restart();
    }

    Timer {
        id: stateChangeDelay

        interval: 500
        onTriggered: {
            if (!root.pressed)
                handle.moving = false;
        }
    }

    Behavior on value {
        NumberAnimation {
            duration: Appearance.dashboard.durations.large
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.standard
        }
    }
}



