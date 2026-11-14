import QtQuick
import qs.modules.theme

// The little up/down stepper that sits beside numeric fields.
Item {
    id: root

    signal increment
    signal decrement

    implicitWidth: 20
    implicitHeight: 30
    opacity: enabled ? 1 : 0.5

    Rectangle {
        anchors.fill: parent
        radius: MacStyle.controlRadius
        color: MacStyle.control
        border.width: 1
        border.color: MacStyle.controlBorder
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: MacStyle.separator
    }

    Item {
        id: up
        width: parent.width
        height: parent.height / 2
        Text {
            anchors.centerIn: parent
            text: Icons.caretUp
            font.family: Icons.font
            font.pixelSize: 10
            color: upArea.pressed ? MacStyle.accent : MacStyle.labelSecondary
        }
        MouseArea {
            id: upArea
            anchors.fill: parent
            onClicked: root.increment()
        }
    }

    Item {
        y: parent.height / 2
        width: parent.width
        height: parent.height / 2
        Text {
            anchors.centerIn: parent
            text: Icons.caretDown
            font.family: Icons.font
            font.pixelSize: 10
            color: downArea.pressed ? MacStyle.accent : MacStyle.labelSecondary
        }
        MouseArea {
            id: downArea
            anchors.fill: parent
            onClicked: root.decrement()
        }
    }
}
