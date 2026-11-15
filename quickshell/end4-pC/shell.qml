//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
// Remove two slashes below and adjust the value to change the UI scale
////@ pragma Env QT_SCALE_FACTOR=1
import "modules/common"
import "services"
import "panelFamilies"
import qs.modules.ii.dashboard2.modules.drawers as Dashboard2
import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    id: root

    ReloadPopup {}

    Process {
        id: autostartProc
        command: ["python3", `${Directories.scriptPath}/hyprland/autostart.py`]
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (!Config.ready) return

                if (WM.compositor === "niri") {
                    Config.options.background.lockWall = ""
                    Config.options.overview.enable = false
                }

                if (Config.options.hyprland.autostartApps.enable &&
                    Config.options.hyprland.autostartApps.apps.length > 0) {
                    autostartProc.running = true
                    }
        }
    }

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        Hyprsunset.load()
        FirstRunExperience.load()
        ConflictKiller.load()
        Cliphist.refresh()
        Wallpapers.load()
        Updates.load()
        LyricsService.restartLyrics()
        StudyScheduler.load()
        PhoneSync.load()
    }

    PanelFamilyLoader {
        identifier: "ii"
        component: IllogicalImpulseFamily {}
    }

    // Ported caelestia dashboard/osd/session/drawers (modules/ii/dashboard2).
    // Loaded independently of the panel-family switch above so it's always
    // available regardless of which family is active. Remove this loader if
    // you'd rather gate it behind a config toggle - just add a property like
    // Config.options.caelestiaDashboard.enable and reference it in `active`.

    Dashboard2.Drawers {}

    component PanelFamilyLoader: LazyLoader {
        required property string identifier
        active: Config.ready && Config.options.panelFamily === identifier
    }
}
