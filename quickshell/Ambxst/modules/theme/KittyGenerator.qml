import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

/**
 * Kitty: only the background opacity. Colours come from matugen (shared pipeline); opacity is not
 * part of it, so it is written straight into kitty.conf (like GtkGenerator does for GTK) and kitty
 * is told to reload (SIGUSR1).
 *
 * Needs `allow_remote_control`-free reload only: SIGUSR1 reloads the config of every running kitty.
 */
QtObject {
    id: root

    // kitty.conf that gets edited (symlinks are followed, so dotfile setups keep working)
    readonly property string confPath: Quickshell.env("HOME") + "/.config/kitty/kitty.conf"

    property string _lastOpacity: ""

    function generate() {
        const opacity = Math.max(0, Math.min(1, Config.theme.srBg.opacity)).toFixed(2);
        if (opacity === root._lastOpacity)
            return; // nothing changed -> don't touch the file or reload kitty
        root._lastOpacity = opacity;

        // $1 = conf, $2 = opacity. Replaces the active `background_opacity` line (commented ones are left
        // alone); appends it if there is none. Then reloads running kitty windows.
        const script = 'conf=$(readlink -f "$1" 2>/dev/null || echo "$1"); mkdir -p "$(dirname "$conf")"; touch "$conf"; ' +
            'if grep -qE "^[[:space:]]*background_opacity[[:space:]]" "$conf"; then ' +
            'sed -i -E "s/^[[:space:]]*background_opacity[[:space:]].*/background_opacity $2/" "$conf"; ' +
            'else printf "\\nbackground_opacity %s\\n" "$2" >> "$conf"; fi; ' +
            'pkill -SIGUSR1 kitty; exit 0';
        writerProcess.command = ["bash", "-c", script, "_", root.confPath, opacity];
        writerProcess.running = true;
    }

    property Process writerProcess: Process {
        running: false
        stderr: StdioCollector {
            onStreamFinished: err => {
                if (err)
                    console.error("KittyGenerator Error:", err);
            }
        }
    }
}
