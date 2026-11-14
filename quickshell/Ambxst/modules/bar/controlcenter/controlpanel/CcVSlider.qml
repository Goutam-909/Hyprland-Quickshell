// controlpanel/CcVSlider.qml
// Vertical pill slider (brightness / volume).
//   value          0..1, driven by the service
//   moved(v)       emitted while the user drags / scrolls
//   iconClicked()  click on the icon at the bottom (e.g. mute)
//   secondaryClicked()  right click (e.g. open the mixer page)
import QtQuick
import QtQuick.Effects
import qs.common
import qs.modules.theme

Item {
    id: root

    property real value: 0
    property string icon: ""
    property bool hasIconAction: false

    signal moved(real v)
    signal iconClicked()
    signal secondaryClicked()

    property bool dragging: false
    property real dragValue: 0
    readonly property real shown: Math.max(0, Math.min(1, dragging ? dragValue : value))
    readonly property real pillRadius: Math.min(width / 2, 28)

    implicitWidth: 70
    implicitHeight: 200

    Timer {
        id: holdTimer
        interval: 220
        onTriggered: root.dragging = false
    }

    // mask shape (rounded pill)
    Item {
        id: maskItem
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Rectangle {
            anchors.fill: parent
            radius: root.pillRadius
            color: "black"
        }
    }

    Item {
        id: body
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: maskItem
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }

        Rectangle {
            anchors.fill: parent
            color: Appearance.colors.colSurfaceContainerHighest
        }
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * root.shown
            color: Appearance.colors.colPrimary

            Behavior on height {
                enabled: !root.dragging
                NumberAnimation { duration: 120 }
            }
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        font.family: Icons.font
        font.pixelSize: 18
        text: root.icon
        color: (root.height * root.shown > 46) ? Appearance.colors.colOnPrimary
                                               : Appearance.colors.colOnSurface
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        property bool iconPress: false
        property real pressY: 0

        function setFrom(y) {
            const v = Math.max(0, Math.min(1, 1 - y / height))
            root.dragValue = v
            root.moved(v)
        }

        onPressed: m => {
            if (m.button === Qt.RightButton) {
                root.secondaryClicked()
                return
            }
            holdTimer.stop()
            root.dragValue = root.value
            root.dragging = true
            pressY = m.y
            iconPress = root.hasIconAction && m.y > height - 56
            if (!iconPress) setFrom(m.y)
        }
        onPositionChanged: m => {
            if (!pressed || (pressedButtons & Qt.RightButton)) return
            if (iconPress) {
                if (Math.abs(m.y - pressY) > 6) iconPress = false
                else return
            }
            setFrom(m.y)
        }
        onReleased: m => {
            if (iconPress) root.iconClicked()
            iconPress = false
            holdTimer.restart()
        }
        onWheel: w => {
            const v = Math.max(0, Math.min(1, root.shown + (w.angleDelta.y > 0 ? 0.05 : -0.05)))
            root.dragValue = v
            root.dragging = true
            holdTimer.restart()
            root.moved(v)
        }
    }
}
