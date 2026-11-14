pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

// Output/input device row: name … ✓ when it is the default device.
Item {
    id: root

    required property PwNode node
    property bool isOutput: true
    property bool isSelected: false

    Layout.fillWidth: true
    implicitHeight: 50
    implicitWidth: parent?.width ?? 300

    PwObjectTracker {
        objects: [root.node]
    }

    Rectangle {
        anchors.fill: parent
        color: mouseArea.pressed ? MacStyle.cardPress : (mouseArea.containsMouse ? MacStyle.cardHover : "transparent")
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.isOutput) {
                Audio.setDefaultSink(root.node);
            } else {
                Audio.setDefaultSource(root.node);
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: MacStyle.rowPadding
        anchors.rightMargin: MacStyle.rowPadding
        spacing: 10

        MacIconTile {
            size: 30
            glyph: root.isOutput ? Icons.speakerHigh : Icons.mic
            tint: root.isSelected ? MacStyle.tileBlue : MacStyle.tileGray
        }

        Text {
            Layout.fillWidth: true
            text: Audio.friendlyDeviceName(root.node)
            elide: Text.ElideRight
            font.family: MacStyle.fontFamily
            font.pixelSize: MacStyle.fsBody
            color: MacStyle.label
        }

        Text {
            visible: root.isSelected
            text: Icons.accept
            font.family: Icons.font
            font.pixelSize: 17
            color: MacStyle.accent
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: MacStyle.rowPadding + 30 + 10
        height: 1
        color: MacStyle.separator
    }
}
