pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

// Volume row: name … 42%   /   [mute]  ———●———
Item {
    id: root

    required property PwNode node
    property string icon: ""
    property bool isMainDevice: false

    Layout.fillWidth: true
    implicitHeight: 76
    implicitWidth: parent?.width ?? 300

    PwObjectTracker {
        objects: [root.node]
    }

    readonly property bool isMuted: root.node?.audio?.muted ?? false
    readonly property real volume: root.node?.audio?.volume ?? 0

    // Guard: true while we are pushing a PipeWire value into the slider.
    property bool syncingFromPipewire: false

    Connections {
        target: root.node?.audio ?? null
        ignoreUnknownSignals: true

        function onVolumeChanged() {
            if (!root.node?.audio)
                return;
            root.syncingFromPipewire = true;
            volumeSlider.value = root.node.audio.volume;
            root.syncingFromPipewire = false;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: MacStyle.rowPadding
        anchors.rightMargin: MacStyle.rowPadding
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: root.isMainDevice ? Audio.friendlyDeviceName(root.node) : Audio.appNodeDisplayName(root.node)
                elide: Text.ElideRight
                font.family: MacStyle.fontFamily
                font.pixelSize: MacStyle.fsBody
                color: MacStyle.label
            }

            Text {
                visible: Audio.protectionTriggered && root.isMainDevice
                text: Icons.shieldCheck
                font.family: Icons.font
                font.pixelSize: 15
                color: MacStyle.warning

                StyledToolTip {
                    visible: parent.visible && protectionIndicatorMa.containsMouse
                    tooltipText: "Volume protection active"
                }

                MouseArea {
                    id: protectionIndicatorMa
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }

            Text {
                text: `${Math.round(root.volume * 100)}%`
                font.family: MacStyle.fontFamily
                font.pixelSize: MacStyle.fsSmall
                color: MacStyle.labelSecondary
                horizontalAlignment: Text.AlignRight
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Item {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                Text {
                    anchors.centerIn: parent
                    text: {
                        if (root.isMuted)
                            return Icons.speakerSlash;
                        if (root.icon)
                            return root.icon;
                        return Icons.speakerHigh;
                    }
                    font.family: Icons.font
                    font.pixelSize: 20
                    color: root.isMuted ? MacStyle.destructive : MacStyle.labelSecondary
                }
                MouseArea {
                    id: muteArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.node?.audio) {
                            root.node.audio.muted = !root.node.audio.muted;
                        }
                    }
                }
                StyledToolTip {
                    visible: muteArea.containsMouse
                    tooltipText: root.isMuted ? "Unmute" : "Mute"
                }
            }

            MacSlider {
                id: volumeSlider
                Layout.fillWidth: true
                Layout.preferredHeight: 28

                value: root.volume
                scroll: false
                tooltip: false

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => {
                        const step = 0.05;
                        const delta = event.angleDelta.y > 0 ? step : -step;
                        const newValue = Math.max(0, Math.min(1, volumeSlider.value + delta));
                        if (root.node?.audio && Math.abs(newValue - root.volume) > 0.001) {
                            Audio.setNodeVolume(root.node, newValue);
                        }
                    }
                }

                progressColor: {
                    if (root.isMuted)
                        return MacStyle.labelTertiary;
                    if (Audio.protectionTriggered && root.isMainDevice)
                        return MacStyle.warning;
                    return MacStyle.accent;
                }

                onValueChanged: {
                    if (root.syncingFromPipewire)
                        return;
                    if (root.node?.audio && Math.abs(value - root.volume) > 0.001) {
                        Audio.setNodeVolume(root.node, value);
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: MacStyle.rowPadding
        height: 1
        color: MacStyle.separator
    }
}
