pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components
import qs.config

// Page header, macOS style.
//  • showToggle  → a card row:  Title ........ [actions] (switch)       (Wi-Fi / Bluetooth look)
//  • otherwise   → a light toolbar row: [‹ Parent] Title ..... [actions]
//    (the title is hidden when it would just repeat the window toolbar title)
// Same API as the previous PanelTitlebar, so every panel keeps working.
Item {
    id: root

    property string title: ""
    property string statusText: ""
    property color statusColor: MacStyle.accent
    property bool showToggle: false

    // Icon tile in the toggle card (auto-picked from the title when empty)
    property string iconGlyph: ""
    property color iconColor: MacStyle.tileBlue
    readonly property var autoIcon: {
        const t = title.toLowerCase();
        if (t.indexOf("wi-fi") >= 0)
            return [Icons.wifiHigh, MacStyle.tileBlue];
        if (t.indexOf("bluetooth") >= 0)
            return [Icons.bluetooth, MacStyle.tileBlue];
        if (t.indexOf("easyeffects") >= 0)
            return [Icons.waveform, MacStyle.tilePurple];
        if (t.indexOf("sound") >= 0)
            return [Icons.speakerHigh, MacStyle.tilePink];
        return null;
    }
    property bool toggleChecked: false

    // Each action: { icon, tooltip, onClicked, enabled, loading }
    property var actions: []

    // Custom content slot (appears before the action buttons)
    default property alias customContent: customContentContainer.data

    signal toggleChanged(bool checked)

    readonly property var backActions: (actions || []).filter(a => a && a.tooltip === "Back")
    readonly property var toolActions: (actions || []).filter(a => a && a.tooltip !== "Back")
    readonly property bool titleVisible: title !== "" && (showToggle || backActions.length > 0 || title !== MacStyle.pageTitle)

    Layout.fillWidth: true
    readonly property bool hasContent: titleVisible || statusText !== "" || toolActions.length > 0 || backActions.length > 0 || customContentContainer.children.length > 0
    implicitHeight: showToggle ? 58 : (hasContent ? 42 : 0)
    visible: implicitHeight > 0

    onToggleCheckedChanged: {
        if (sw.checked !== toggleChecked)
            sw.checked = toggleChecked;
    }

    // Card behind the toggle variant
    Rectangle {
        anchors.fill: parent
        visible: root.showToggle
        radius: MacStyle.cardRadius
        color: MacStyle.card
        border.width: 1
        border.color: MacStyle.cardBorder
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.showToggle ? MacStyle.rowPadding : 0
        anchors.rightMargin: root.showToggle ? MacStyle.rowPadding : 0
        spacing: 8

        // ‹ Back
        Repeater {
            model: root.backActions

            delegate: Item {
                id: backBtn
                required property var modelData
                implicitWidth: backRow.implicitWidth + 18
                implicitHeight: 32

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: backArea.pressed ? MacStyle.controlPress : (backArea.containsMouse ? MacStyle.controlHover : MacStyle.control)
                    border.width: 1
                    border.color: MacStyle.controlBorder
                }

                Row {
                    id: backRow
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Icons.caretLeft
                        font.family: Icons.font
                        font.pixelSize: 15
                        color: MacStyle.accent
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: MacStyle.pageTitle !== "" ? MacStyle.pageTitle : "Back"
                        font.family: MacStyle.fontFamily
                        font.pixelSize: MacStyle.fsBody
                        color: MacStyle.accent
                    }
                }

                MouseArea {
                    id: backArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (backBtn.modelData.onClicked)
                            backBtn.modelData.onClicked();
                    }
                }
            }
        }

        MacIconTile {
            visible: root.showToggle && glyph !== ""
            glyph: root.iconGlyph !== "" ? root.iconGlyph : (root.autoIcon ? root.autoIcon[0] : "")
            tint: root.iconGlyph !== "" ? root.iconColor : (root.autoIcon ? root.autoIcon[1] : root.iconColor)
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            visible: root.titleVisible
            text: root.title
            font.family: MacStyle.fontFamily
            font.pixelSize: root.showToggle ? MacStyle.fsBody + 1 : MacStyle.fsTitle + 4
            font.weight: root.showToggle ? Font.Normal : Font.DemiBold
            color: MacStyle.label
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            visible: root.statusText !== ""
            text: root.statusText
            font.family: MacStyle.fontFamily
            font.pixelSize: MacStyle.fsSmall
            color: root.statusColor
            Layout.alignment: Qt.AlignVCenter
        }

        Item {
            Layout.fillWidth: true
        }

        Item {
            id: customContentContainer
            Layout.preferredWidth: childrenRect.width
            Layout.preferredHeight: childrenRect.height
            Layout.alignment: Qt.AlignVCenter
            visible: children.length > 0
        }

        // tool buttons
        Repeater {
            model: root.toolActions

            delegate: Item {
                id: toolBtn
                required property var modelData
                readonly property bool isEnabled: (modelData.enabled !== undefined ? modelData.enabled : true) && !(modelData.loading ?? false)
                readonly property bool isLoading: modelData.loading ?? false

                implicitWidth: 34
                implicitHeight: 34
                opacity: isEnabled || isLoading ? 1 : 0.4

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: toolArea.pressed ? MacStyle.controlPress : (toolArea.containsMouse && toolBtn.isEnabled ? MacStyle.controlHover : MacStyle.control)
                    border.width: 1
                    border.color: MacStyle.controlBorder
                }

                Text {
                    anchors.centerIn: parent
                    text: toolBtn.modelData.icon || ""
                    font.family: Icons.font
                    font.pixelSize: 17
                    color: toolBtn.isLoading ? MacStyle.accent : MacStyle.label

                    RotationAnimation on rotation {
                        running: toolBtn.isLoading
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                    }
                }

                MouseArea {
                    id: toolArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: toolBtn.isEnabled
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (toolBtn.modelData.onClicked)
                            toolBtn.modelData.onClicked();
                    }
                }

                StyledToolTip {
                    visible: toolArea.containsMouse && (toolBtn.modelData.tooltip ?? "") !== ""
                    tooltipText: toolBtn.modelData.tooltip || ""
                }
            }
        }

        MacSwitch {
            id: sw
            visible: root.showToggle
            checked: root.toggleChecked
            Layout.alignment: Qt.AlignVCenter
            onToggled: root.toggleChanged(checked)
        }
    }
}
