pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

/**
 * Desktop clock placement + auto colour — same approach as end4-pC's AbstractBackgroundWidget.
 *
 * Runs end4's own scripts/images/least-busy-region-venv.sh (copied together with the rest of
 * its scripts/ folder) on the wallpaper, and from its JSON output:
 *   • moves the clock to the least busy part of the picture (Config.desktop.clockX / clockY)
 *   • remembers the dominant colour behind the clock, so `autoColor` can pick a light or dark
 *     variant of the theme's primary that stays readable (end4's colText rule).
 *
 * Wallpaper.qml calls update() a couple of seconds after a wallpaper change, so this python
 * run never competes with switchwall.sh or the transition. It also runs at nice 19.
 * This replaces scripts/clock_position.sh (which had a hard-coded venv path).
 */
Singleton {
    id: root

    readonly property string script: Quickshell.shellPath("scripts/images/least-busy-region-venv.sh")

    // Approximate clock size used for the search (same numbers the old script used)
    readonly property int clockWidth: 560
    readonly property int clockHeight: 210
    readonly property int padding: 100

    // Dominant colour of the region behind the clock (updated by update())
    property color dominantColor: Colors.primary
    readonly property bool dominantIsDark: dominantColor.hslLightness < 0.5

    // What the clock uses when its colour is set to "auto" (end4: primary, lightness 0.8 on dark
    // backgrounds / 0.12 on light ones). Tracks theme changes live.
    readonly property color autoColor: {
        const p = Colors.primary;
        return Qt.hsla(p.hslHue < 0 ? 0 : p.hslHue, p.hslSaturation, root.dominantIsDark ? 0.8 : 0.12, 1);
    }

    signal finished()

    property string _queued: ""

    function update(path) {
        if (!path)
            return;
        if (!(Config.desktop.clockEnabled ?? false))
            return;
        if (proc.running) {
            _queued = path; // newest wins
            return;
        }
        _start(path);
    }

    function _start(path) {
        const screen = Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
        const sw = screen ? Math.round(screen.width) : 1920;
        const sh = screen ? Math.round(screen.height) : 1080;
        proc.screenW = sw;
        proc.screenH = sh;
        proc.command = ["nice", "-n", "19", root.script,
            "--screen-width", sw, "--screen-height", sh,
            "--width", root.clockWidth, "--height", root.clockHeight,
            "--horizontal-padding", root.padding, "--vertical-padding", root.padding,
            path];
        proc.running = true;
    }

    function _apply(text) {
        if (!text || text.trim().length === 0)
            return;
        let out;
        try {
            out = JSON.parse(text);
        } catch (e) {
            console.warn("[ClockPlacement] bad output:", text);
            return;
        }
        if (out.error || out.center_x === undefined)
            return;

        if (out.dominant_color)
            root.dominantColor = out.dominant_color;

        // centre -> top-left, clamped to the screen
        let x = Math.round(out.center_x - root.clockWidth / 2);
        let y = Math.round(out.center_y - root.clockHeight / 2);
        x = Math.max(0, Math.min(x, proc.screenW - root.clockWidth));
        y = Math.max(0, Math.min(y, proc.screenH - root.clockHeight));

        if (Config.desktop.clockX !== x || Config.desktop.clockY !== y) {
            Config.desktop.clockX = x;
            Config.desktop.clockY = y;
            Config.saveDesktop();
        }
    }

    Process {
        id: proc
        property int screenW: 1920
        property int screenH: 1080

        stdout: StdioCollector {
            onStreamFinished: root._apply(text)
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) console.warn("[ClockPlacement]", text.trim())
        }
        onExited: {
            root.finished();
            if (root._queued !== "") {
                const next = root._queued;
                root._queued = "";
                root._start(next);
            }
        }
    }
}
