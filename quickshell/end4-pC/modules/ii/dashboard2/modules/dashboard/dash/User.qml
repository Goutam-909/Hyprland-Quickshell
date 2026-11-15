import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import qs.modules.ii.dashboard2.utils as DashUtils
import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules.common

Row {
    id: root
    required property bool shouldUpdate

    padding: Appearance.dashboard.padding.large
    spacing: Appearance.dashboard.spacing.normal

    StyledClippingRect {
        implicitWidth: info.implicitHeight
        implicitHeight: info.implicitHeight

        radius: Appearance.rounding.large
        color: Appearance.m3colors.m3primaryContainer

        MaterialIcon {
            anchors.centerIn: parent

            text: "person"
            fill: 1
            font.pointSize: (info.implicitHeight / 2) || 1
        }

        CachingImage {
            anchors.fill: parent
            source: `${DashUtils.Paths.home}/Pictures/me.jpg`
        }
    }

    Column {
        id: info

        spacing: Appearance.dashboard.spacing.normal

        InfoLine {
            icon: DashUtils.Icons.osIcon
            text: DashUtils.Icons.osName
            colour: Appearance.m3colors.m3primary
        }

        InfoLine {
            icon: "select_window_2"
            text: Quickshell.env("XDG_CURRENT_DESKTOP") || Quickshell.env("XDG_SESSION_DESKTOP")
            colour: Appearance.m3colors.m3secondary
        }

        InfoLine {
            icon: "timer"
            text: uptimeProc.uptime
            colour: Appearance.m3colors.m3tertiary

            Timer {
                running: root.shouldUpdate   // <-- was: true
                repeat: true
                interval: 15000
                triggeredOnStart: true       // <-- refresh immediately when it becomes active
                onTriggered: uptimeProc.running = true
            }

            Process {
                id: uptimeProc

                property string uptime

                running: false
                command: ["uptime", "-p"]
                stdout: SplitParser {
                    onRead: data => uptimeProc.uptime = data
                }
            }
        }
    }

    component InfoLine: Item {
        id: line

        required property string icon
        required property string text
        required property color colour

        implicitWidth: icon.implicitWidth + text.width + text.anchors.leftMargin
        implicitHeight: Math.max(icon.implicitHeight, text.implicitHeight)

        MaterialIcon {
            id: icon

            anchors.left: parent.left
            anchors.leftMargin: (Config.options.caelestiaDashboard.dashboard.sizes.infoIconSize - implicitWidth) / 2

            text: line.icon
            color: line.colour
            font.pointSize: Appearance.dashboard.fontSize.normal
            font.variableAxes: ({
                FILL: 1
            })
        }

        StyledText {
            id: text

            anchors.verticalCenter: icon.verticalCenter
            anchors.left: icon.right
            anchors.leftMargin: icon.anchors.leftMargin
            text: `:  ${line.text}`
            font.pointSize: Appearance.dashboard.fontSize.normal

            width: Config.options.caelestiaDashboard.dashboard.sizes.infoWidth
            elide: Text.ElideRight
        }
    }
}
