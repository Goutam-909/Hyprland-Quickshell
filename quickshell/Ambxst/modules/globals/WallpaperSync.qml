pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ii's (Uchiha's) shared config file
    readonly property string iiConfigFile: Quickshell.env("HOME") + "/.config/uchiha/quickshell/config.json"
    // VERIFY this actual path on disk — wherever you placed switchwall.sh for the ii config
    readonly property string switchwallScript: Quickshell.env("HOME") + "/.config/quickshell/ii/scripts/colors/switchwall.sh"

    // true while we're applying a change that CAME FROM ii, so we don't echo it straight back
    property bool applyingRemoteSync: false

    function pushToIi(path, scheme) {
        if (applyingRemoteSync || !path) return;
        pushProcess.command = ["bash", switchwallScript, "--image", path, "--type", scheme || "scheme-tonal-spot"];
        pushProcess.running = true;
    }

    Process {
        id: pushProcess
        running: false
        stdout: StdioCollector { onStreamFinished: console.log("[wallpaper-sync -> ii]", text) }
        stderr: StdioCollector { onStreamFinished: console.warn("[wallpaper-sync -> ii] error:", text) }
    }

    FileView {
        id: iiConfig
        path: root.iiConfigFile
        watchChanges: true
        onFileChanged: reload()

        adapter: JsonAdapter {
            property JsonObject background: JsonObject {
                property string wallpaperPath: ""
            }
        }
    }

    readonly property string remoteWallpaperPath: iiConfig.adapter.background.wallpaperPath

    onRemoteWallpaperPathChanged: {
        if (!remoteWallpaperPath) return;
        if (remoteWallpaperPath === Wallpaper.currentWallpaper) return; // already matches

        applyingRemoteSync = true;
        Wallpaper.setWallpaper(remoteWallpaperPath);
        applyingRemoteSync = false;
    }
}
