import qs.modules.ii.dashboard2.services
import Quickshell
import QtQuick
import qs.modules.common
import qs.services

Scope {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property bool hovered
    readonly property Brightness.BrightnessMonitor monitor: Brightness.getMonitorForScreen(screen)

    function show(): void {
        root.visibilities.osd = true;
        timer.restart();
    }

    Connections {
        target: Audio.sink?.audio ?? null

        function onMutedChanged(): void {
            root.show();
        }

        function onVolumeChanged(): void {
            root.show();
        }
    }

    Connections {
        target: root.monitor

        function onBrightnessChanged(): void {
            root.show();
        }
    }

    Timer {
        id: timer

        interval: Config.options.caelestiaDashboard.osd.hideDelay
        onTriggered: {
            if (!root.hovered)
                root.visibilities.osd = false;
        }
    }
}
