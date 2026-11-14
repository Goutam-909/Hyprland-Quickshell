// modules/services/Cava.qml
// Shared cava feed for the media widgets (CompactPlayer, MediaPlayerView).
// cava now runs ONLY when it can actually be seen:
//   - the toggle Config.desktop.cavaPlayerVisualizer is on (Shell settings)
//   - not on battery (unless Config.desktop.cavaDisableOnBattery is turned off)
//   - media is actually playing
//   - the system is not suspending
pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    // Live bar data — list of ints 0-100
    property list<int> values: []

    // How many bars cava outputs (keep <= 64 for the notch canvas size)
    property int barCount: 30

    // Fixed low rate: the widgets don't need more and it cuts CPU a lot.
    property int framerate: 30

    // Startup delay so PipeWire/PulseAudio is ready before cava connects
    property int startupDelay: 2000
    // How long to wait before restarting if cava crashes
    property int restartDelay: 3000

    property bool _ready: false
    property bool _crashBackoff: false

    readonly property bool onBattery: Battery.available && !Battery.isPluggedIn

    // Master gate. Everything cheap to evaluate, nothing is polled.
    readonly property bool wanted:
        (Config.desktop.cavaPlayerVisualizer ?? true)
        && !(onBattery && (Config.desktop.cavaDisableOnBattery ?? true))
        && MprisController.isPlaying
        && !SuspendManager.isSuspending

    // True only while cava is really supposed to be producing data.
    // UI (notch) uses this to fall back to the track title when it is false.
    readonly property bool active: _ready && wanted && !_crashBackoff

    Timer {
        id: startupTimer
        interval: root.startupDelay
        running: true
        repeat: false
        onTriggered: root._ready = true
    }

    Timer {
        id: restartTimer
        interval: root.restartDelay
        repeat: false
        onTriggered: root._crashBackoff = false
    }

    Process {
        id: cavaProcess
        // Declarative binding only (never assign running imperatively).
        running: root._ready && root.wanted && !root._crashBackoff
        // Passes config via stdin so no config file is needed
        command: [
            "sh", "-c",
            `printf '[general]\nframerate=${root.framerate}\nbars=${root.barCount}\n[output]\nchannels=mono\nmethod=raw\nraw_target=/dev/stdout\ndata_format=ascii\nascii_max_range=100' | cava -p /dev/stdin`
        ]

        onRunningChanged: {
            if (!running) {
                root.values = []
                // Died while we still wanted it -> crash, back off before retrying
                if (root._ready && root.wanted) {
                    root._crashBackoff = true
                    restartTimer.restart()
                }
            }
        }

        stdout: SplitParser {
            onRead: data => {
                if (data && data.length > 0) {
                    // cava ascii output: "val;val;val;\n" — strip trailing semicolon
                    root.values = data.slice(0, -1).split(";").map(v => parseInt(v, 10))
                }
            }
        }
    }
}
