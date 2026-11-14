pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.modules.components
import qs.modules.theme
import qs.modules.services
import qs.modules.globals
import qs.config

PanelWindow {
    id: root

    property ShellScreen targetScreen
    screen: targetScreen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "ambxst:osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    WlrLayershell.margins.bottom: 100

    color: "transparent"

    visible: GlobalStates.osdVisible

    // Internal state for responsiveness
    property real osdValue: 0
    property bool osdMuted: false

    // Centering wrapper
    Item {
        anchors.fill: parent

        StyledRect {
            id: osdRect
            variant: "popup"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            implicitWidth: 220
            implicitHeight: 52
            radius: Styling.radius(16)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 24
                anchors.topMargin: 8
                anchors.bottomMargin: 8
                spacing: 14

                Text {
                    id: iconText
                    text: {
                        if (GlobalStates.osdIndicator === "volume") {
                            return Audio.volumeIcon(root.osdValue, root.osdMuted);
                        } else if (GlobalStates.osdIndicator === "mic") {
                            return root.osdMuted ? Icons.micSlash : Icons.mic;
                        } else {
                            return Icons.sun;
                        }
                    }
                    font.family: Icons.font
                    font.pixelSize: 22
                    color: Colors.overBackground
                    Layout.alignment: Qt.AlignVCenter

                    rotation: GlobalStates.osdIndicator === "brightness" ? (root.osdValue * 180) : 0
                    scale: GlobalStates.osdIndicator === "brightness" ? (0.8 + (root.osdValue * 0.2)) : 1

                    Behavior on rotation {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutQuart
                        }
                    }

                    Behavior on scale {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutQuart
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: {
                                if (GlobalStates.osdIndicator === "volume")
                                    return "Volume";
                                if (GlobalStates.osdIndicator === "mic")
                                    return "Microphone";
                                if (GlobalStates.osdIndicator === "brightness")
                                    return "Brightness";
                                return "";
                            }
                            font.family: Config.theme.font
                            font.pixelSize: 15
                            font.bold: false
                            color: Colors.overBackground
                            Layout.alignment: Qt.AlignBottom
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            text: Math.round(root.osdValue * 100)
                            font.family: Config.theme.font
                            font.pixelSize: 15
                            font.bold: false
                            color: Colors.overBackground
                            Layout.alignment: Qt.AlignBottom
                        }
                    }

                    // GNOME-style level bar (replaces StyledSlider)
                    Item {
                        id: levelBar
                        Layout.fillWidth: true
                        Layout.preferredHeight: 12

                        // Same colors as the original slider
                        readonly property color fillColor: root.osdMuted ? Colors.outline : Styling.srItem("overprimary")
                        readonly property color trackColor: Qt.rgba(Colors.overBackground.r, Colors.overBackground.g, Colors.overBackground.b, 0.2)

                        Rectangle {
                            id: track
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: 6
                            radius: height / 2
                            color: levelBar.trackColor
                        }

                        Rectangle {
                            anchors.left: track.left
                            anchors.verticalCenter: track.verticalCenter
                            height: track.height
                            radius: height / 2
                            // never narrower than the bar's height so the end stays round
                            width: Math.max(height, track.width * Math.min(1, Math.max(0, root.osdValue)))
                            color: levelBar.fillColor

                            Behavior on width {
                                enabled: Config.animDuration > 0
                                NumberAnimation {
                                    duration: Config.animDuration / 2
                                    easing.type: Easing.OutQuart
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Close on click or hover
    MouseArea {
        anchors.fill: parent
        onEntered: {
            hideTimer.stop();
            hideTimer.triggered();
        }
        hoverEnabled: true
    }

    Timer {
        id: hideTimer
        interval: 2500
        onTriggered: GlobalStates.osdVisible = false
    }

    Connections {
        target: GlobalStates
        function onOsdVisibleChanged() {
            if (GlobalStates.osdVisible) {
                hideTimer.restart();
            }
        }
    }

    // Services connections - Direct and responsive
    Connections {
        target: Audio
        function onVolumeChanged(volume, muted, node) {
            root.osdValue = volume;
            root.osdMuted = muted;
            GlobalStates.osdIndicator = "volume";
            GlobalStates.osdVisible = true;
            hideTimer.restart();
        }
        function onMicVolumeChanged(volume, muted, node) {
            root.osdValue = volume;
            root.osdMuted = muted;
            GlobalStates.osdIndicator = "mic";
            GlobalStates.osdVisible = true;
            hideTimer.restart();
        }
    }

    Connections {
        target: Brightness
        function onBrightnessChanged(value, screen) {
            // Check if the change happened on THIS screen or if it's a sync change
            if (!screen || !root.targetScreen || screen.name === root.targetScreen.name || Brightness.syncBrightness) {
                root.osdValue = value;
                root.osdMuted = false;
                GlobalStates.osdIndicator = "brightness";
                GlobalStates.osdVisible = true;
                hideTimer.restart();
            }
        }
    }
}
