pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

Item {
    id: root

    property int maxContentWidth: 480
    readonly property int contentWidth: Math.min(width, maxContentWidth)
    readonly property real sideMargin: (width - contentWidth) / 2

    Flickable {
        id: mainFlickable
        anchors.fill: parent
        contentWidth: width
        contentHeight: presetsColumn.implicitHeight + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: presetsColumn
            width: root.contentWidth
            x: root.sideMargin
            spacing: 10

            PanelTitlebar {
                id: titlebar
                Layout.fillWidth: true
                title: "EasyEffects"
                statusText: EasyEffectsService.bypassed ? "Bypassed" : ""
                statusColor: MacStyle.destructive
                showToggle: EasyEffectsService.available
                toggleChecked: !EasyEffectsService.bypassed

                actions: EasyEffectsService.available ? [
                    {
                        icon: Icons.popOpen,
                        tooltip: "Open EasyEffects",
                        onClicked: function () {
                            EasyEffectsService.openApp();
                        }
                    },
                    {
                        icon: Icons.sync,
                        tooltip: "Refresh",
                        onClicked: function () {
                            EasyEffectsService.refresh();
                        }
                    }
                ] : []

                onToggleChanged: checked => {
                    if (checked !== !EasyEffectsService.bypassed) {
                        EasyEffectsService.setBypass(!checked);
                    }
                }
            }

            Text {
                visible: !EasyEffectsService.available
                text: "EasyEffects not installed"
                font.family: MacStyle.fontFamily
                font.pixelSize: MacStyle.fsBody
                color: MacStyle.labelSecondary
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 32
            }

            // Output presets
            MacHeader {
                text: "Output Presets"
                visible: EasyEffectsService.available && EasyEffectsService.outputPresets.length > 0
            }
            MacGroup {
                visible: EasyEffectsService.available && EasyEffectsService.outputPresets.length > 0
                Repeater {
                    model: EasyEffectsService.outputPresets
                    delegate: MacRow {
                        id: outRow
                        required property string modelData
                        readonly property bool isActive: EasyEffectsService.activeOutputPreset === modelData
                        label: modelData
                        hoverable: true
                        onClicked: EasyEffectsService.loadOutputPreset(modelData)
                        Text {
                            visible: outRow.isActive
                            text: Icons.accept
                            font.family: Icons.font
                            font.pixelSize: 17
                            color: MacStyle.accent
                        }
                    }
                }
            }

            // Input presets
            MacHeader {
                text: "Input Presets"
                visible: EasyEffectsService.available && EasyEffectsService.inputPresets.length > 0
            }
            MacGroup {
                visible: EasyEffectsService.available && EasyEffectsService.inputPresets.length > 0
                Repeater {
                    model: EasyEffectsService.inputPresets
                    delegate: MacRow {
                        id: inRow
                        required property string modelData
                        readonly property bool isActive: EasyEffectsService.activeInputPreset === modelData
                        label: modelData
                        hoverable: true
                        onClicked: EasyEffectsService.loadInputPreset(modelData)
                        Text {
                            visible: inRow.isActive
                            text: Icons.accept
                            font.family: Icons.font
                            font.pixelSize: 17
                            color: MacStyle.accent
                        }
                    }
                }
            }

            Text {
                visible: EasyEffectsService.available && EasyEffectsService.outputPresets.length === 0 && EasyEffectsService.inputPresets.length === 0
                text: "No presets configured"
                font.family: MacStyle.fontFamily
                font.pixelSize: MacStyle.fsBody
                color: MacStyle.labelSecondary
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 16
            }

            // Active
            MacHeader {
                text: "Active"
                visible: EasyEffectsService.available && (EasyEffectsService.activeOutputPreset || EasyEffectsService.activeInputPreset)
            }
            MacGroup {
                visible: EasyEffectsService.available && (EasyEffectsService.activeOutputPreset || EasyEffectsService.activeInputPreset)
                MacRow {
                    visible: EasyEffectsService.activeOutputPreset
                    iconGlyph: Icons.speakerHigh
                    iconColor: MacStyle.tileBlue
                    label: EasyEffectsService.activeOutputPreset
                    description: "Output"
                }
                MacRow {
                    visible: EasyEffectsService.activeInputPreset
                    iconGlyph: Icons.mic
                    iconColor: MacStyle.tileOrange
                    label: EasyEffectsService.activeInputPreset
                    description: "Input"
                }
            }
        }
    }
}
