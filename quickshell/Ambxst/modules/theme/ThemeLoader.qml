pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

/**
 * ThemeLoader — the ONLY place that knows how colours and wallpaper get into the shell.
 *
 *   switchwall.sh  (shared with end4-pC, never modified)
 *        │  writes  ~/.config/uchiha/quickshell/config.json   (wallpaperPath, palette.type, accent…)
 *        │  runs    matugen → ~/.config/uchiha/colors/colors.json
 *        ▼
 *   ThemeLoader (this file): FileViews + one debounce timer
 *        │  translates matugen/M3 snake_case names → this shell's names
 *        ▼
 *   Colors.qml  (plain property container)
 *
 * The shell never runs matugen itself. Every user action (new wallpaper, scheme,
 * light/dark, accent colour) is just a call to switchwall.sh; the result comes
 * back through the file watchers, exactly like end4-pC's MaterialThemeLoader.
 * switchwall runs are coalesced so that spamming next/previous never stacks them.
 */
Singleton {
    id: root

    // ───────────────────────── paths ─────────────────────────
    readonly property string home: Quickshell.env("HOME")
    // Same files end4-pC uses. Override here if your matugen/ii setup differs.
    readonly property string sharedConfigPath: home + "/.config/uchiha/quickshell/config.json"
    readonly property string colorsPath: home + "/.config/uchiha/colors/colors.json"
    // Optional extra matugen output (red/green/blue… families). See docs/SETUP.md
    readonly property string extraColorsPath: home + "/.config/uchiha/colors/colors-ambxst.json"
    readonly property string switchwallPath: Quickshell.shellPath("scripts/colors/switchwall.sh")
    readonly property string officialPresetDir: Quickshell.shellPath("assets/colors")
    readonly property string userPresetDir: home + "/.config/ambxst/colors"

    // ───────────────────────── tunables ─────────────────────────
    // The old template did `background | lighten: -2.5`. This keeps your look; set to 0
    // for the exact M3 background that end4-pC shows.
    readonly property real backgroundLightnessShift: -0.025
    readonly property int applyDelayMs: 100

    // ───────────────────────── state (read-only for the rest of the shell) ─────────────────────────
    readonly property string wallpaperPath: sharedAdapter.background.wallpaperPath
    readonly property string thumbnailPath: sharedAdapter.background.thumbnailPath
    readonly property string paletteType: sharedAdapter.appearance.palette.type || "auto"
    readonly property string accentColor: sharedAdapter.appearance.palette.accentColor
    property bool configLoaded: false
    property bool colorsLoaded: false
    property bool darkmode: true
    // Local colour preset (assets/colors/<Name>/{dark,light}.json) – set by Wallpaper.qml.
    // While set, the preset overrides colors.json for THIS shell only.
    property string activePreset: ""

    // Set by Wallpaper.qml while a wallpaper transition is loading/running. New colours are held
    // back until it is over so the transition and the shell-wide colour change never share frames.
    property bool uiBusy: false

    signal applied()

    // Call once from shell.qml; singletons are lazy.
    function load() {
        ensureConfigProc.running = true;
        restoreVideoProc.running = true;
        colorsFile.reload();
        extraFile.reload();
    }

    // ───────────────────────── actions → switchwall.sh ─────────────────────────
    function applyWallpaper(path) {
        if (!path)
            return;
        // Videos: no `nice` (mpvpaper is started by switchwall.sh and would inherit it, making playback choppy)
        const isVideo = /\.(mp4|webm|mkv|avi|mov)$/i.test(path);
        const base = isVideo ? ["bash"] : ["nice", "-n", "10", "bash"];
        _run(base.concat([switchwallPath, "--mode", darkmode ? "dark" : "light", "--image", path]));
    }

    // type: auto | scheme-content | scheme-expressive | scheme-fidelity | scheme-fruit-salad |
    //       scheme-monochrome | scheme-neutral | scheme-rainbow | scheme-tonal-spot
    // switchwall reads the type from config.json, so persist it first (same jq edit it does itself).
    function setScheme(type) {
        _run(["bash", "-c",
            'cfg="$1"; type="$2"; sw="$3"; mkdir -p "$(dirname "$cfg")"; [ -f "$cfg" ] || echo "{}" > "$cfg"; ' +
            'jq --arg t "$type" \'.appearance.palette.type = $t\' "$cfg" > "$cfg.tmp" && mv "$cfg.tmp" "$cfg"; ' +
            'exec nice -n 10 bash "$sw" --noswitch',
            "_", sharedConfigPath, type, switchwallPath]);
    }

    function setMode(light) {
        if (colorsLoaded && darkmode === !light)
            return;
        _run(["nice", "-n", "10", "bash", switchwallPath, "--mode", light ? "light" : "dark", "--noswitch"]);
    }

    // hex like "#aabbcc"; empty string clears the accent override (back to wallpaper colours)
    function setAccentColor(hex) {
        _run(["nice", "-n", "10", "bash", switchwallPath, "--noswitch", "--color", hex && hex.length ? hex : "clear"]);
    }

    function reapply() {
        _run(["nice", "-n", "10", "bash", switchwallPath, "--noswitch"]);
    }

    // ───────────────────────── switchwall runner (coalescing) ─────────────────────────
    property var _pending: null

    function _run(cmd) {
        if (switchProc.running) {
            _pending = cmd; // only the newest request matters
            return;
        }
        // switchwall.sh starts mpvpaper in the background (`mpvpaper ... &`). Run it in its own session
        // (setsid -w: still waits, so exit is detected) with output going to a log file, so mpvpaper is
        // never tied to Quickshell's process group or pipes and survives this Process finishing.
        switchProc.command = ["setsid", "-w", "bash", "-c",
            'log="${XDG_STATE_HOME:-$HOME/.local/state}/ambxst-switchwall.log"; mkdir -p "$(dirname "$log")"; ' +
            'exec "$@" >>"$log" 2>&1', "_"].concat(cmd);
        switchProc.running = true;
    }

    // After a reboot/Quickshell restart nothing restarts mpvpaper unless Hyprland does: do it here if
    // it isn't running (script is generated by switchwall.sh; empty when the wallpaper is not a video).
    Process {
        id: restoreVideoProc
        command: ["bash", "-c",
            'pgrep -x mpvpaper >/dev/null && exit 0; ' +
            's="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/custom/scripts/__restore_video_wallpaper.sh"; ' +
            '[ -x "$s" ] && setsid -f bash "$s" >/dev/null 2>&1; exit 0']
    }

    Process {
        id: switchProc
        stdout: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) console.log("[switchwall]", text.trim())
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) console.warn("[switchwall]", text.trim())
        }
        onExited: code => {
            if (code !== 0)
                console.warn("[ThemeLoader] switchwall exited with", code);
            if (root._pending) {
                const next = root._pending;
                root._pending = null;
                root._run(next);
            }
        }
    }

    // switchwall.sh edits config.json with jq and silently does nothing if it is missing.
    Process {
        id: ensureConfigProc
        command: ["bash", "-c", '[ -f "$1" ] || { mkdir -p "$(dirname "$1")" && echo "{}" > "$1"; }', "_", root.sharedConfigPath]
        onExited: sharedConfig.reload()
    }

    // ───────────────────────── watchers ─────────────────────────
    // Read-only view on end4-pC's config.json. Never call writeAdapter() on this:
    // the file belongs to switchwall.sh / end4's shell.
    FileView {
        id: sharedConfig
        path: root.sharedConfigPath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.configLoaded = true
        onLoadFailed: root.configLoaded = true

        adapter: JsonAdapter {
            id: sharedAdapter
            property JsonObject background: JsonObject {
                property string wallpaperPath: ""
                property string thumbnailPath: ""
            }
            property JsonObject appearance: JsonObject {
                property JsonObject palette: JsonObject {
                    property string type: "auto"
                    property string accentColor: ""
                }
            }
        }
    }

    FileView {
        id: colorsFile
        path: root.colorsPath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: applyTimer.restart()
    }

    FileView {
        id: extraFile
        path: root.extraColorsPath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: applyTimer.restart()
    }

    // Local presets (same lookup order as before: official first, then ~/.config/ambxst/colors)
    readonly property string _presetFileName: Config.lightMode ? "light.json" : "dark.json"

    FileView {
        id: officialPreset
        path: root.activePreset ? root.officialPresetDir + "/" + root.activePreset + "/" + root._presetFileName : ""
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: applyTimer.restart()
        onPathChanged: applyTimer.restart()
    }

    FileView {
        id: userPreset
        path: root.activePreset ? root.userPresetDir + "/" + root.activePreset + "/" + root._presetFileName : ""
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: applyTimer.restart()
        onPathChanged: applyTimer.restart()
    }

    onActivePresetChanged: applyTimer.restart()

    // One debounce for everything: matugen rewrites colors.json (and the extras file)
    // within a few ms of each other, and may truncate before writing.
    property int _deferCount: 0

    Timer {
        id: applyTimer
        interval: root.applyDelayMs
        repeat: false
        onTriggered: {
            if (root.uiBusy && root._deferCount < 30) {
                root._deferCount++;
                applyTimer.interval = 150;
                applyTimer.restart();
                return;
            }
            root._deferCount = 0;
            applyTimer.interval = root.applyDelayMs;
            root._apply();
        }
    }

    // Colours are written in small batches, one per frame, instead of ~100 property changes in a
    // single frame (every change re-evaluates the bindings that depend on it).
    readonly property int batchSize: 20
    property var _batchKeys: []
    property var _batchSet: ({})
    property int _batchIdx: 0
    property bool _batchDark: true
    property bool _batchLoaded: false

    Timer {
        id: batchTimer
        interval: 16
        repeat: true
        onTriggered: root._stepBatch()
    }

    function _startBatch(set, dark, loaded) {
        _batchSet = set;
        _batchKeys = Object.keys(set);
        _batchIdx = 0;
        _batchDark = dark;
        _batchLoaded = loaded;
        batchTimer.restart();
    }

    function _stepBatch() {
        const end = Math.min(_batchIdx + batchSize, _batchKeys.length);
        for (; _batchIdx < end; _batchIdx++) {
            const key = _batchKeys[_batchIdx];
            if (Colors[key] !== undefined)
                Colors[key] = _batchSet[key];
        }
        if (_batchIdx >= _batchKeys.length) {
            batchTimer.stop();
            _finishApply(_batchDark, _batchLoaded);
            pywalZenGenerator.generate(Colors);
            _regenGtk(1500); // GTK css is written a moment later, never in the same frame as the colour batch
            root.applied();
        }
    }

    // dark/light flags are published last, after all colours are in place
    function _finishApply(dark, loaded) {
        if (loaded) {
            root.colorsLoaded = true;
            root.darkmode = dark;
        }
        _checkSettled();
    }

    // ───────────────────────── translation: matugen / M3 names → this shell ─────────────────────────
    // `surface` and `surface_bright` are intentionally absent: Colors.qml derives them from
    // background/overBackground (unchanged behaviour). Add them here to use pure M3 values.
    readonly property var m3Map: ({
        "error": "error",
        "error_container": "errorContainer",
        "inverse_on_surface": "inverseOnSurface",
        "inverse_primary": "inversePrimary",
        "inverse_surface": "inverseSurface",
        "on_background": "overBackground",
        "on_error": "overError",
        "on_error_container": "overErrorContainer",
        "on_primary": "overPrimary",
        "on_primary_container": "overPrimaryContainer",
        "on_primary_fixed": "overPrimaryFixed",
        "on_primary_fixed_variant": "overPrimaryFixedVariant",
        "on_secondary": "overSecondary",
        "on_secondary_container": "overSecondaryContainer",
        "on_secondary_fixed": "overSecondaryFixed",
        "on_secondary_fixed_variant": "overSecondaryFixedVariant",
        "on_surface": "overSurface",
        "on_surface_variant": "overSurfaceVariant",
        "on_tertiary": "overTertiary",
        "on_tertiary_container": "overTertiaryContainer",
        "on_tertiary_fixed": "overTertiaryFixed",
        "on_tertiary_fixed_variant": "overTertiaryFixedVariant",
        "outline": "outline",
        "outline_variant": "outlineVariant",
        "primary": "primary",
        "primary_container": "primaryContainer",
        "primary_fixed": "primaryFixed",
        "primary_fixed_dim": "primaryFixedDim",
        "scrim": "scrim",
        "secondary": "secondary",
        "secondary_container": "secondaryContainer",
        "secondary_fixed": "secondaryFixed",
        "secondary_fixed_dim": "secondaryFixedDim",
        "shadow": "shadow",
        "surface_container": "surfaceContainer",
        "surface_container_high": "surfaceContainerHigh",
        "surface_container_highest": "surfaceContainerHighest",
        "surface_container_low": "surfaceContainerLow",
        "surface_container_lowest": "surfaceContainerLowest",
        "surface_dim": "surfaceDim",
        "surface_tint": "surfaceTint",
        "surface_variant": "surfaceVariant",
        "tertiary": "tertiary",
        "tertiary_container": "tertiaryContainer",
        "tertiary_fixed": "tertiaryFixed",
        "tertiary_fixed_dim": "tertiaryFixedDim",
        "source_color": "sourceColor"
    })

    // Keys of colors-ambxst.json (already in this shell's names) – matugen custom_colors families.
    readonly property var extraNames: [
        "blue",
        "blueContainer",
        "blueSource",
        "blueValue",
        "cyan",
        "cyanContainer",
        "cyanSource",
        "cyanValue",
        "green",
        "greenContainer",
        "greenSource",
        "greenValue",
        "lightBlue",
        "lightCyan",
        "lightGreen",
        "lightMagenta",
        "lightRed",
        "lightYellow",
        "magenta",
        "magentaContainer",
        "magentaSource",
        "magentaValue",
        "overBlue",
        "overBlueContainer",
        "overCyan",
        "overCyanContainer",
        "overGreen",
        "overGreenContainer",
        "overMagenta",
        "overMagentaContainer",
        "overRed",
        "overRedContainer",
        "overWhite",
        "overWhiteContainer",
        "overYellow",
        "overYellowContainer",
        "red",
        "redContainer",
        "redSource",
        "redValue",
        "white",
        "whiteContainer",
        "whiteSource",
        "whiteValue",
        "yellow",
        "yellowContainer",
        "yellowSource",
        "yellowValue"
    ]

    readonly property var _families: ({
        "red": 0.0, "yellow": 55 / 360, "green": 125 / 360, "cyan": 175 / 360, "blue": 215 / 360, "magenta": 300 / 360, "white": -1
    })

    property string _lastSignature: ""
    property bool _extrasWarned: false
    property bool _settled: false
    property bool _syncingMode: false

    function _readJson(view) {
        if (!view.loaded)
            return null;
        const raw = view.text();
        if (!raw || raw.trim().length === 0)
            return null;
        try {
            return JSON.parse(raw);
        } catch (e) {
            console.warn("[ThemeLoader] invalid JSON in", view.path, "-", e);
            return null;
        }
    }

    function _shiftLightness(hex, delta) {
        const c = Qt.color(hex);
        return Qt.hsla(c.hslHue, c.hslSaturation, Math.max(0, Math.min(1, c.hslLightness + delta)), 1);
    }

    // Only used when colors-ambxst.json is missing so the shell still looks sane.
    function _deriveFamilies(set, dark) {
        const primary = Qt.color(set.primary || "#888888");
        const ph = primary.hslHue < 0 ? 0 : primary.hslHue;
        const sat = Math.max(0.35, Math.min(0.7, primary.hslSaturation));
        for (const fam in _families) {
            const Fam = fam.charAt(0).toUpperCase() + fam.slice(1);
            let h = _families[fam];
            let s = sat;
            const neutral = h < 0;
            if (neutral) {
                h = ph;
                s = 0.12;
            } else {
                // nudge ~25% towards the wallpaper hue (what matugen's blend does)
                let diff = ph - h;
                if (diff > 0.5) diff -= 1;
                if (diff < -0.5) diff += 1;
                h = (h + Math.max(-0.04, Math.min(0.04, diff * 0.25)) + 1) % 1;
            }
            set[fam] = Qt.hsla(h, s, dark ? 0.75 : 0.38, 1);
            set[fam + "Container"] = Qt.hsla(h, s * 0.8, dark ? 0.24 : 0.88, 1);
            set["over" + Fam] = Qt.hsla(h, s * 0.8, dark ? 0.14 : 0.98, 1);
            set["over" + Fam + "Container"] = Qt.hsla(h, s * 0.8, dark ? 0.9 : 0.1, 1);
            set["light" + Fam] = Qt.hsla(h, s, dark ? 0.8 : 0.43, 1);
            const pure = neutral ? Qt.rgba(1, 1, 1, 1) : Qt.hsla(h, 1, 0.5, 1);
            set[fam + "Source"] = pure;
            set[fam + "Value"] = pure;
        }
    }

    function _apply() {
        const set = {};
        let dark = root.darkmode;

        // 1) local preset (already in this shell's names)
        let preset = null;
        if (activePreset)
            preset = _readJson(officialPreset) ?? _readJson(userPreset);

        // 2) shared matugen output (always read: it is the source of truth for dark/light)
        const m3 = _readJson(colorsFile);
        if (m3) {
            if (m3.background)
                dark = Qt.color(m3.background).hslLightness < 0.5;
            if (!preset) {
                for (const k in m3) {
                    const mapped = m3Map[k];
                    if (mapped)
                        set[mapped] = m3[k];
                }
                if (m3.background)
                    set.baseBackground = _shiftLightness(m3.background, backgroundLightnessShift);

                const extra = _readJson(extraFile);
                if (extra) {
                    for (let i = 0; i < extraNames.length; i++) {
                        const n = extraNames[i];
                        if (extra[n])
                            set[n] = extra[n];
                    }
                } else {
                    if (!_extrasWarned) {
                        console.warn("[ThemeLoader] " + extraColorsPath + " not found – deriving red/green/blue… from the palette. See docs/SETUP.md to get the exact matugen values.");
                        _extrasWarned = true;
                    }
                    _deriveFamilies(set, dark);
                }
            }
        } else if (!preset) {
            return; // nothing to apply yet
        }

        if (preset) {
            for (const k in preset) {
                if (k === "background")
                    set.baseBackground = preset[k];
                else if (k !== "surface" && k !== "surfaceBright")
                    set[k] = preset[k];
            }
        }

        // Cheap no-op detection (e.g. end4 rewrote an identical file)
        const sig = Object.keys(set).sort().map(k => k + "=" + set[k]).join("|"); // String() per value: JSON.stringify can't serialise QML colours
        if (sig === _lastSignature) {
            _finishApply(dark, !!m3);
            return;
        }
        _lastSignature = sig;
        _startBatch(set, dark, !!m3);
    }

    // ───────────────────────── light/dark ↔ Config.theme.lightMode ─────────────────────────
    // The system (colors.json) is the source of truth. Config.theme.lightMode is mirrored from it,
    // and only a user flip *after* startup is turned into a switchwall run.
    function _checkSettled() {
        if (root._settled || !root.colorsLoaded || !Config.initialLoadComplete)
            return;
        root._settled = true;
        _mirrorModeToConfig();
    }

    function _mirrorModeToConfig() {
        if (Config.theme.lightMode === !root.darkmode)
            return;
        root._syncingMode = true;
        Config.theme.lightMode = !root.darkmode;
        root._syncingMode = false;
    }

    onDarkmodeChanged: if (root._settled) _mirrorModeToConfig()

    Connections {
        target: Config
        function onInitialLoadCompleteChanged() {
            root._checkSettled();
        }
        function onLightModeChanged() {
            if (!root._settled || root._syncingMode)
                return;
            root.setMode(Config.lightMode);
        }
    }

    // Settings app → Theme → colours / opacity: those live in theme.json (Config.theme.sr*), and the GTK css
    // bakes in Config.theme.srBg.opacity, so regenerate it when theme.json changes or OLED mode flips.
    // (This was Colors.qml's job before; short delay so dragging a slider feels live but doesn't spam writes.)
    Connections {
        target: Config.loader
        function onFileChanged() {
            root._regenGtk(500);
        }
    }
    Connections {
        target: Config
        function onOledModeChanged() {
            root._regenGtk(500);
        }
    }

    function _regenGtk(delay) {
        gtkTimer.interval = delay;
        gtkTimer.restart();
        kittyTimer.restart();
    }

    // Kitty: background opacity only (colours come from matugen). Skips the write if the value is unchanged.
    property KittyGenerator kittyGenerator: KittyGenerator {
        id: kittyGenerator
    }
    property Timer kittyTimer: Timer {
        id: kittyTimer
        interval: 600
        repeat: false
        onTriggered: kittyGenerator.generate()
    }

    // Only the Zen/pywal css and the GTK css are generated from QML. Qt, terminals, VS Code…
    // are done by switchwall.sh itself (matugen templates + applycolor.sh).
    property GtkGenerator gtkGenerator: GtkGenerator {
        id: gtkGenerator
    }

    // Debounced: many applies in a row (rapid wallpaper changes) -> one GTK write, after things settled.
    property Timer gtkTimer: Timer {
        id: gtkTimer
        interval: 1500
        repeat: false
        onTriggered: gtkGenerator.generate(Colors)
    }
    property PywalZenGenerator pywalZenGenerator: PywalZenGenerator {
        id: pywalZenGenerator
    }
}
