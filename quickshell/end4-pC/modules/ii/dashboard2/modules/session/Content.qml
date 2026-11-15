pragma ComponentBehavior: Bound

import qs.modules.ii.dashboard2.widgets
import qs.modules.ii.dashboard2.services
import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules.common

Column {
    id: root

    required property PersistentProperties visibilities

    padding: Appearance.dashboard.padding.large

    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left

    spacing: Appearance.dashboard.spacing.large

    SessionButton {
        id: logout

        icon: "logout"
        command: ["sh", "-c", "(uwsm stop | grep -q 'Compositor is not running' && loginctl terminate-user $USER) || uwsm stop"]

        KeyNavigation.down: shutdown

        Connections {
            target: root.visibilities

            function onSessionChanged(): void {
                if (root.visibilities.session)
                    logout.focus = true;
            }
        }
    }

    SessionButton {
        id: shutdown

        icon: "power_settings_new"
        command: ["systemctl", "poweroff"]

        KeyNavigation.up: logout
        KeyNavigation.down: hibernate
    }

    AnimatedImage {
        width: Config.options.caelestiaDashboard.session.sizes.button
        height: Config.options.caelestiaDashboard.session.sizes.button
        sourceSize.width: width
        sourceSize.height: height

        playing: visible
        asynchronous: true
        speed: 0.7
        source: "root:/assets/kurukuru.gif"
    }

    SessionButton {
        id: hibernate

        icon: "downloading"
        command: ["systemctl", "hibernate"]

        KeyNavigation.up: shutdown
        KeyNavigation.down: reboot
    }

    SessionButton {
        id: reboot

        icon: "cached"
        command: ["systemctl", "reboot"]

        KeyNavigation.up: hibernate
    }

    component SessionButton: StyledRect {
        id: button

        required property string icon
        required property list<string> command

        implicitWidth: Config.options.caelestiaDashboard.session.sizes.button
        implicitHeight: Config.options.caelestiaDashboard.session.sizes.button

        radius: Appearance.rounding.large
        color: button.activeFocus ? Appearance.m3colors.m3primaryContainer : Appearance.m3colors.m3surfaceContainer

        Keys.onEnterPressed: proc.startDetached()
        Keys.onReturnPressed: proc.startDetached()
        Keys.onEscapePressed: root.visibilities.session = false

        Process {
            id: proc

            command: button.command
        }

        StateLayer {
            radius: parent.radius

            function onClicked(): void {
                proc.startDetached();
            }
        }

        MaterialIcon {
            anchors.centerIn: parent

            text: button.icon
            color: button.activeFocus ? Appearance.m3colors.m3secondary : Appearance.m3colors.m3secondary
            font.pointSize: Appearance.dashboard.fontSize.extraLarge
        }
    }
}



