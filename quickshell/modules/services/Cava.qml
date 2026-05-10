// modules/services/Cava.qml
// Drop this alongside your other singletons in qs.modules.services
pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Live bar data — list of ints 0-100
    property list<int> values: []

    // How many bars cava outputs (keep ≤ 64 for the notch canvas size)
    property int barCount: 30

    // Startup delay so PipeWire/PulseAudio is ready before cava connects
    property int startupDelay: 2000
    // How long to wait before restarting if cava crashes
    property int restartDelay: 3000

    property bool _ready: false

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
        onTriggered: {
            if (root._ready)
                cavaProcess.running = true
        }
    }

    Process {
        id: cavaProcess
        running: root._ready
        // Passes config via stdin so no config file is needed
        command: [
            "sh", "-c",
            `printf '[general]\nframerate=120\nbars=${root.barCount}\n[output]\nchannels=mono\nmethod=raw\nraw_target=/dev/stdout\ndata_format=ascii\nascii_max_range=100' | cava -p /dev/stdin`
        ]

        onRunningChanged: {
            if (!running && root._ready) {
                root.values = []
                restartTimer.restart()
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
