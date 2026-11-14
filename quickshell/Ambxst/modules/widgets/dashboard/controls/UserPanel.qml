pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.modules.theme
import qs.modules.components

// Settings → User (opened by clicking your name in the sidebar).
Item {
    id: root

    property int maxContentWidth: 480
    readonly property int contentWidth: Math.min(width, maxContentWidth)
    readonly property real sideMargin: (width - contentWidth) / 2

    readonly property string userName: Quickshell.env("USER") || "User"
    readonly property string homeDir: Quickshell.env("HOME") || ""

    // tiny helper: run a command once and expose its trimmed output
    component Sys: Item {
        id: sys
        property var command: []
        property string output: ""
        Process {
            running: true
            command: sys.command
            stdout: StdioCollector {
                waitForEnd: true
                onStreamFinished: sys.output = text.trim()
            }
        }
    }

    Sys {
        id: hostName
        command: ["hostname"]
    }
    Sys {
        id: kernel
        command: ["uname", "-sr"]
    }
    Sys {
        id: uptime
        command: ["uptime", "-p"]
    }
    Sys {
        id: osName
        command: ["sh", "-c", ". /etc/os-release 2>/dev/null; echo \"${PRETTY_NAME:-Linux}\""]
    }

    // one trailing value inside a MacRow
    component Value: Text {
        Layout.maximumWidth: 260
        elide: Text.ElideMiddle
        font.family: MacStyle.fontFamily
        font.pixelSize: MacStyle.fsBody
        color: MacStyle.labelSecondary
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: col
            width: root.contentWidth
            x: root.sideMargin
            spacing: 10

            // ── avatar header ───────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 170

                ClippingRectangle {
                    id: avatar
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 12
                    width: 96
                    height: 96
                    radius: 48
                    color: MacStyle.tileGray

                    Text {
                        anchors.centerIn: parent
                        visible: face.status !== Image.Ready
                        text: root.userName.charAt(0).toUpperCase()
                        font.family: MacStyle.fontFamily
                        font.pixelSize: 42
                        font.weight: Font.Medium
                        color: "#FFFFFF"
                    }
                    Image {
                        id: face
                        anchors.fill: parent
                        source: `file://${root.homeDir}/.face`
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: avatar.bottom
                    anchors.topMargin: 10
                    text: root.userName
                    font.family: MacStyle.fontFamily
                    font.pixelSize: MacStyle.fsLarge - 4
                    font.weight: Font.DemiBold
                    color: MacStyle.label
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    text: hostName.output !== "" ? hostName.output : "Ambxst"
                    font.family: MacStyle.fontFamily
                    font.pixelSize: MacStyle.fsSmall
                    color: MacStyle.labelSecondary
                }
            }

            // ── account ─────────────────────────────────────────────────
            MacHeader {
                text: "Account"
            }
            MacGroup {
                MacRow {
                    label: "Username"
                    Value {
                        text: root.userName
                    }
                }
                MacRow {
                    label: "Home folder"
                    Value {
                        text: root.homeDir
                    }
                }
                MacRow {
                    label: "Shell"
                    showSeparator: false
                    Value {
                        text: Quickshell.env("SHELL") || "-"
                    }
                }
            }
            MacFooter {
                text: "Your picture is read from ~/.face. Put an image there to change it."
            }

            // ── this computer ───────────────────────────────────────────
            MacHeader {
                text: "This Computer"
            }
            MacGroup {
                MacRow {
                    label: "Name"
                    Value {
                        text: hostName.output
                    }
                }
                MacRow {
                    label: "System"
                    Value {
                        text: osName.output
                    }
                }
                MacRow {
                    label: "Kernel"
                    Value {
                        text: kernel.output
                    }
                }
                MacRow {
                    label: "Desktop"
                    Value {
                        text: Quickshell.env("XDG_CURRENT_DESKTOP") || "-"
                    }
                }
                MacRow {
                    label: "Uptime"
                    showSeparator: false
                    Value {
                        text: uptime.output
                    }
                }
            }
        }
    }
}
