pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules.common

// Lightweight replacement for Caelestia's compiled NetworkUsage service.
// Polls /proc/net/dev (skipping loopback) and derives instantaneous
// upload/download speed plus running session totals and small ring
// buffers for a sparkline.
Singleton {
    id: root

    readonly property int historyLength: 60
    property bool active: false

    property real downloadSpeed: 0 // bytes/sec
    property real uploadSpeed: 0 // bytes/sec
    property real downloadTotal: 0 // bytes, since shell start
    property real uploadTotal: 0 // bytes, since shell start

    property list<real> downloadHistory: []
    property list<real> uploadHistory: []
    // Kept for API-compatibility with a Sparkline that wants {values,maximum,count}
    readonly property var downloadBuffer: ({
            values: downloadHistory,
            maximum: Math.max(1024, ...downloadHistory, 0),
            count: downloadHistory.length
        })
    readonly property var uploadBuffer: ({
            values: uploadHistory,
            maximum: Math.max(1024, ...uploadHistory, 0),
            count: uploadHistory.length
        })

    property var _lastRx: ({})
    property var _lastTx: ({})
    property bool _firstSample: true

    function formatBytes(bytesPerSec: real): var {
        if (!isFinite(bytesPerSec) || bytesPerSec < 0)
            bytesPerSec = 0;

        const units = ["B/s", "KB/s", "MB/s", "GB/s"];
        let value = bytesPerSec;
        let i = 0;
        while (value >= 1024 && i < units.length - 1) {
            value /= 1024;
            i++;
        }
        return {
            value,
            unit: units[i]
        };
    }

    function formatBytesTotal(bytes: real): var {
        if (!isFinite(bytes) || bytes < 0)
            bytes = 0;

        const units = ["B", "KB", "MB", "GB", "TB"];
        let value = bytes;
        let i = 0;
        while (value >= 1024 && i < units.length - 1) {
            value /= 1024;
            i++;
        }
        return {
            value,
            unit: units[i]
        };
    }

    Timer {
        interval: Config.options.caelestiaDashboard.dashboard.resourceUpdateInterval
        running: root.active        // was: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    Process {
        id: proc

        command: ["cat", "/proc/net/dev"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").slice(2); // skip the two header lines
                let rx = 0;
                let tx = 0;

                for (const line of lines) {
                    const trimmed = line.trim();
                    if (!trimmed)
                        continue;

                    const [iface, rest] = trimmed.split(":");
                    if (!rest || iface.startsWith("lo"))
                        continue;

                    const fields = rest.trim().split(/\s+/).map(Number);
                    rx += fields[0] ?? 0; // bytes received
                    tx += fields[8] ?? 0; // bytes transmitted
                }

                const now = Date.now();
                const dtSec = root._lastTime ? Math.max(0.001, (now - root._lastTime) / 1000) : 1;

                if (!root._firstSample) {
                    const drx = Math.max(0, rx - root._lastRxTotal);
                    const dtx = Math.max(0, tx - root._lastTxTotal);

                    root.downloadSpeed = drx / dtSec;
                    root.uploadSpeed = dtx / dtSec;
                    root.downloadTotal += drx;
                    root.uploadTotal += dtx;

                    root.downloadHistory = [...root.downloadHistory, root.downloadSpeed].slice(-root.historyLength);
                    root.uploadHistory = [...root.uploadHistory, root.uploadSpeed].slice(-root.historyLength);
                }

                root._lastRxTotal = rx;
                root._lastTxTotal = tx;
                root._lastTime = now;
                root._firstSample = false;
            }
        }
    }

    property real _lastRxTotal: 0
    property real _lastTxTotal: 0
    property real _lastTime: 0
}



