import qs.modules.ii.dashboard2.services
//import qs.modules.ii.dashboard2.modules.osd as Osd
import qs.modules.ii.dashboard2.modules.session as Session
import qs.modules.ii.dashboard2.modules.dashboard as Dashboard
import qs.modules.ii.dashboard2.modules.launcher as Launcher
import qs.modules.ii.dashboard2.modules.wallpaper as Wallpaper
import Quickshell
import QtQuick

Item {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities

    //readonly property Osd.Wrapper osd: osd
    readonly property Session.Wrapper session: session
    readonly property Dashboard.Wrapper dashboard: dashboard
    readonly property Launcher.Wrapper launcher: launcher
    readonly property Wallpaper.Wrapper wallpaper: wallpaper

    anchors.fill: parent

    Component.onCompleted: Visibilities.panels[screen] = this

  /*  Osd.Wrapper {
        id: osd

        screen: root.screen
        visibility: root.visibilities.osd

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
    }*/

    // Session (power) menu - docked to the right edge, same spot and
    // slide-in-from-the-edge technique as Caelestia's session menu.
    Session.Wrapper {
        id: session

        visibilities: root.visibilities

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
    }

    Dashboard.Wrapper {
        id: dashboard

        visibilities: root.visibilities

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
    }

    // Separate from the dashboard on purpose - its own PersistentProperties
    // flag (visibilities.launcher, already declared in Drawers.qml) and its
    // own panel, just docked to the same bottom-center spot and reusing the
    // exact same height-animation technique as Dashboard.Wrapper.
    Launcher.Wrapper {
        id: launcher

        visibilities: root.visibilities

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
    }

    // Also separate on purpose - its own PersistentProperties flag
    // (visibilities.wallpaper) and its own panel/wrapper, so the wallpaper
    // carousel's sizing and open/close animation no longer share anything
    // with the launcher's. Docked to the same bottom-center spot and
    // reusing the exact same height-animation technique as
    // Dashboard.Wrapper / Launcher.Wrapper.
    Wallpaper.Wrapper {
        id: wallpaper

        visibilities: root.visibilities

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
    }
}
