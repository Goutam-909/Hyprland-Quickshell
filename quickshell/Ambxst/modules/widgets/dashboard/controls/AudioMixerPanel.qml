pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

Item {
    id: root

    property int maxContentWidth: 480
    readonly property int contentWidth: Math.min(width, maxContentWidth)
    readonly property real sideMargin: (width - contentWidth) / 2

    property bool showOutput: true  // true = output, false = input

    Flickable {
        id: flickable
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentColumn.implicitHeight + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: contentColumn
            width: root.contentWidth
            x: root.sideMargin
            spacing: 10

            PanelTitlebar {
                id: titlebar
                Layout.fillWidth: true
                title: "Sound"

                actions: [
                    {
                        icon: Audio.protectionEnabled ? Icons.shieldCheck : Icons.shield,
                        tooltip: Audio.protectionEnabled ? "Volume protection enabled" : "Volume protection disabled",
                        onClicked: function () {
                            Audio.setProtectionEnabled(!Audio.protectionEnabled);
                        }
                    },
                    {
                        icon: Icons.popOpen,
                        tooltip: "Open PipeWire Volume Control",
                        onClicked: function () {
                            Quickshell.execDetached(["kcmshell6", "kcm_pulseaudio"]);
                        }
                    }
                ]

                // Output / Input switcher
                MacSegmented {
                    options: [
                        { label: "Output", value: "out", icon: Icons.speakerHigh },
                        { label: "Input", value: "in", icon: Icons.mic }
                    ]
                    value: root.showOutput ? "out" : "in"
                    onValueSelected: v => root.showOutput = (v === "out")
                }
            }

            MacHeader {
                text: root.showOutput ? "Output Device" : "Input Device"
            }

            MacGroup {
                Repeater {
                    model: root.showOutput ? Audio.outputDevices : Audio.inputDevices

                    delegate: AudioDeviceItem {
                        required property var modelData
                        node: modelData
                        isOutput: root.showOutput
                        isSelected: (root.showOutput ? Audio.sink : Audio.source) === modelData
                    }
                }
            }

            MacHeader {
                text: root.showOutput ? "Output Volume" : "Input Volume"
            }

            MacGroup {
                AudioVolumeEntry {
                    node: root.showOutput ? Audio.sink : Audio.source
                    icon: root.showOutput ? Icons.speakerHigh : Icons.mic
                    isMainDevice: true
                }
            }

            MacHeader {
                text: "Applications"
                visible: (root.showOutput ? Audio.outputAppNodes : Audio.inputAppNodes).length > 0
            }

            MacGroup {
                Repeater {
                    model: root.showOutput ? Audio.outputAppNodes : Audio.inputAppNodes

                    delegate: AudioVolumeEntry {
                        required property var modelData
                        node: modelData
                        isMainDevice: false
                    }
                }
            }

            Text {
                visible: (root.showOutput ? Audio.outputAppNodes : Audio.inputAppNodes).length === 0
                text: "No applications using audio"
                font.family: MacStyle.fontFamily
                font.pixelSize: MacStyle.fsBody
                color: MacStyle.labelSecondary
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 16
            }
        }
    }
}
