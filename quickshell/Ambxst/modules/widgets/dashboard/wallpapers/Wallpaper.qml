
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.modules.globals
import qs.modules.theme
import qs.config

PanelWindow {
    id: wallpaper

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "ambxst:wallpaper"
    exclusionMode: ExclusionMode.Ignore

    color: "transparent"


    property string wallpaperDir: wallpaperConfig.adapter.wallPath
    property string fallbackDir: decodeURIComponent(Qt.resolvedUrl("../../../../assets/wallpapers_example").toString().replace("file://", ""))
    property var wallpaperPaths: []
    property var subfolderFilters: []
    property var allSubdirs: []
    property bool usingFallback: false
    property bool _wallpaperDirInitialized: false
    property bool _firstRunHandled: false
    property string _pendingTarget: ""
    property int thumbnailsVersion: 0

    // ── Wallpaper / theme state is owned by switchwall.sh ───────────────────────
    // switchwall.sh writes ~/.config/uchiha/quickshell/config.json (shared with end4-pC);
    // ThemeLoader watches it. Nothing here runs matugen or keeps its own copy.
    readonly property string currentWallpaper: ThemeLoader.wallpaperPath
    readonly property int currentIndex: wallpaperPaths.indexOf(currentWallpaper)
    readonly property bool initialLoadCompleted: ThemeLoader.configLoaded
    readonly property string currentMatugenScheme: ThemeLoader.paletteType
    readonly property bool currentIsVideo: getFileType(currentWallpaper) === 'video'

    // Compat stubs for UI/consumers that still read these (tint and the source-colour picker are gone)
    readonly property bool tintEnabled: false
    readonly property var sourceColors: []
    readonly property int sourceColorIndex: 0
    readonly property bool legacyMatugen: true

    // Sync state from the primary wallpaper manager to secondary instances
    Binding {
        target: wallpaper
        property: "wallpaperPaths"
        value: GlobalStates.wallpaperManager.wallpaperPaths
        when: GlobalStates.wallpaperManager !== null && GlobalStates.wallpaperManager !== wallpaper
    }

    Binding {
        target: wallpaper
        property: "subfolderFilters"
        value: GlobalStates.wallpaperManager.subfolderFilters
        when: GlobalStates.wallpaperManager !== null && GlobalStates.wallpaperManager !== wallpaper
    }

    // Tell ThemeLoader when a transition is loading/running so the shell-wide colour change waits for it
    Binding {
        target: ThemeLoader
        property: "uiBusy"
        value: wallpaper._transitionPending || transitionAnim.running
        when: GlobalStates.wallpaperManager === wallpaper
    }

    property string colorPresetsDir: Quickshell.env("HOME") + "/.config/ambxst/colors"
    property string officialColorPresetsDir: decodeURIComponent(Qt.resolvedUrl("../../../../assets/colors").toString().replace("file://", ""))
    onColorPresetsDirChanged: console.log("Color Presets Directory:", colorPresetsDir)
    property list<string> colorPresets: []
    onColorPresetsChanged: console.log("Color Presets Updated:", colorPresets)
    property string activeColorPreset: wallpaperConfig.adapter.activeColorPreset || ""

    // A local colour preset overrides colors.json inside THIS shell only (see ThemeLoader).
    // Only the primary instance drives the shared singleton.
    Binding {
        target: ThemeLoader
        property: "activePreset"
        value: wallpaper.activeColorPreset
        when: GlobalStates.wallpaperManager === wallpaper
    }

    function scanColorPresets() {
        scanPresetsProcess.running = true;
    }

    function setColorPreset(name) {
        wallpaperConfig.adapter.activeColorPreset = name;
    }

    function getFileType(path) {
        var extension = path.toLowerCase().split('.').pop();
        if (['jpg', 'jpeg', 'png', 'webp', 'tif', 'tiff', 'bmp'].includes(extension)) {
            return 'image';
        } else if (['gif'].includes(extension)) {
            return 'gif';
        } else if (['mp4', 'webm', 'mov', 'avi', 'mkv'].includes(extension)) {
            return 'video';
        }
        return 'unknown';
    }

    function getThumbnailPath(filePath) {
        // Compute relative path from wallpaperDir
        var basePath = wallpaperDir.endsWith("/") ? wallpaperDir : wallpaperDir + "/";
        var relativePath = filePath.replace(basePath, "");

        // Replace the filename with .jpg extension
        var pathParts = relativePath.split('/');
        var fileName = pathParts.pop();
        var thumbnailName = fileName + ".jpg";
        var relativeDir = pathParts.join('/');

        // Build the proxy path
        var thumbnailPath = Quickshell.cacheDir + "/thumbnails/" + relativeDir + "/" + thumbnailName;
        return thumbnailPath;
    }

    function getDisplaySource(filePath) {
        var fileType = getFileType(filePath);

        // Para el display (WallpapersTab), siempre usar thumbnails si están disponibles
        if (fileType === 'video' || fileType === 'image' || fileType === 'gif') {
            var thumbnailPath = getThumbnailPath(filePath);
            // Verificar si el thumbnail existe (esto es solo para debugging, QML manejará el fallback)
            return thumbnailPath;
        }

        // Fallback al archivo original si no es un tipo soportado
        return filePath;
    }

    function getColorSource(filePath) {
        var fileType = getFileType(filePath);

        // Para generación de colores: solo videos usan thumbnails
        if (fileType === 'video') {
            return getThumbnailPath(filePath);
        }

        // Imágenes y GIFs usan el archivo original para colores
        return filePath;
    }

    function getLockscreenFramePath(filePath) {
        if (!filePath) {
            return "";
        }

        var fileType = getFileType(filePath);

        // Para imágenes estáticas, usar el archivo original
        if (fileType === 'image') {
            return filePath;
        }

        // Para videos y GIFs, usar el frame cacheado
        if (fileType === 'video' || fileType === 'gif') {
            var fileName = filePath.split('/').pop();
            var cachePath = Quickshell.cacheDir + "/lockscreen/" + fileName + ".jpg";
            return cachePath;
        }

        return filePath;
    }

    function generateLockscreenFrame(filePath) {
        if (!filePath) {
            console.warn("generateLockscreenFrame: empty filePath");
            return;
        }

        console.log("Generating lockscreen frame for:", filePath);

        var scriptPath = decodeURIComponent(Qt.resolvedUrl("../../../../scripts/lockwall.py").toString().replace("file://", ""));
        var dataPath = Quickshell.cacheDir;

        lockscreenWallpaperScript.command = ["python3", scriptPath, filePath, dataPath];

        lockscreenWallpaperScript.running = true;
    }

    function getSubfolderFromPath(filePath) {
        var basePath = wallpaperDir.endsWith("/") ? wallpaperDir : wallpaperDir + "/";
        var relativePath = filePath.replace(basePath, "");
        var parts = relativePath.split("/");
        if (parts.length > 1) {
            return parts[0];
        }
        return "";
    }

    function scanSubfolders() {
        if (!wallpaperDir)
            return;
        // Explicitly update command with current wallpaperDir
        var cmd = ["find", wallpaperDir, "-mindepth", "1", "-name", ".*", "-prune", "-o", "-type", "d", "-print"];
        scanSubfoldersProcess.command = cmd;
        scanSubfoldersProcess.running = true;
    }

    // Update directory watcher when wallpaperDir changes
    onWallpaperDirChanged: {
        // Skip initial spurious changes before config is loaded
        if (!_wallpaperDirInitialized)
            return;

        // Only the primary wallpaper manager should handle directory changes
        if (GlobalStates.wallpaperManager !== wallpaper)
            return;

        console.log("Wallpaper directory changed to:", wallpaperDir);
        usingFallback = false;

        // Clear current lists to reflect change immediately
        wallpaperPaths = [];
        subfolderFilters = [];

        directoryWatcher.path = wallpaperDir;

        // Force update scan command
        var cmd = ["find", wallpaperDir, "-name", ".*", "-prune", "-o", "-type", "f", "(", "-name", "*.jpg", "-o", "-name", "*.jpeg", "-o", "-name", "*.png", "-o", "-name", "*.webp", "-o", "-name", "*.tif", "-o", "-name", "*.tiff", "-o", "-name", "*.gif", "-o", "-name", "*.mp4", "-o", "-name", "*.webm", "-o", "-name", "*.mov", "-o", "-name", "*.avi", "-o", "-name", "*.mkv", ")", "-print"];
        scanWallpapers.command = cmd;
        scanWallpapers.running = true;

        scanSubfolders();

        // Regenerate thumbnails for the new directory (delayed)
        if (delayedThumbnailGen.running)
            delayedThumbnailGen.restart();
        else
            delayedThumbnailGen.start();
    }


    // ── Wallpaper switching: everything goes through switchwall.sh ──────────────
    // currentWallpaper updates when switchwall.sh has written config.json, so this also
    // reacts to changes made by end4-pC's shell or from a terminal.
    onCurrentWallpaperChanged: {
        _pendingTarget = "";
        if (currentWallpaper && GlobalStates.wallpaperManager === wallpaper)
            _scheduleFollowUp();
    }

    function setWallpaper(path) {
        if (GlobalStates.wallpaperManager && GlobalStates.wallpaperManager !== wallpaper) {
            GlobalStates.wallpaperManager.setWallpaper(path);
            return;
        }
        if (!path)
            return;
        console.log("setWallpaper called with:", path);
        _pendingTarget = path;
        pendingTargetReset.restart();
        ThemeLoader.applyWallpaper(path);
    }

    // Steps from the last *requested* wallpaper so rapid next/previous presses
    // don't all resolve to the same neighbour while switchwall.sh is still running.
    function _step(delta) {
        var n = wallpaperPaths.length;
        if (n === 0)
            return;
        var base = wallpaperPaths.indexOf(_pendingTarget || currentWallpaper);
        var idx = base < 0 ? (delta > 0 ? 0 : n - 1) : (base + delta + n) % n;
        setWallpaper(wallpaperPaths[idx]);
    }

    function nextWallpaper() {
        if (GlobalStates.wallpaperManager && GlobalStates.wallpaperManager !== wallpaper) {
            GlobalStates.wallpaperManager.nextWallpaper();
            return;
        }
        _step(1);
    }

    function previousWallpaper() {
        if (GlobalStates.wallpaperManager && GlobalStates.wallpaperManager !== wallpaper) {
            GlobalStates.wallpaperManager.previousWallpaper();
            return;
        }
        _step(-1);
    }

    function setWallpaperByIndex(index) {
        if (GlobalStates.wallpaperManager && GlobalStates.wallpaperManager !== wallpaper) {
            GlobalStates.wallpaperManager.setWallpaperByIndex(index);
            return;
        }
        if (index >= 0 && index < wallpaperPaths.length)
            setWallpaper(wallpaperPaths[index]);
    }

    // scheme: scheme-content | scheme-expressive | scheme-fidelity | scheme-fruit-salad |
    //         scheme-monochrome | scheme-neutral | scheme-rainbow | scheme-tonal-spot | auto
    function setMatugenScheme(scheme) {
        if (GlobalStates.wallpaperManager && GlobalStates.wallpaperManager !== wallpaper) {
            GlobalStates.wallpaperManager.setMatugenScheme(scheme);
            return;
        }
        if (wallpaperConfig.adapter.activeColorPreset)
            wallpaperConfig.adapter.activeColorPreset = "";
        ThemeLoader.setScheme(scheme);
    }

    Timer {
        id: pendingTargetReset
        interval: 4000
        onTriggered: wallpaper._pendingTarget = ""
    }

    // First run only: shared config.json has no wallpaper yet -> use the first one we found.
    function _maybeFirstRun() {
        if (_firstRunHandled || GlobalStates.wallpaperManager !== wallpaper)
            return;
        if (!ThemeLoader.configLoaded || wallpaperPaths.length === 0)
            return;
        _firstRunHandled = true;
        if (!ThemeLoader.wallpaperPath) {
            console.log("No wallpaper in shared config.json, applying first one:", wallpaperPaths[0]);
            ThemeLoader.applyWallpaper(wallpaperPaths[0]);
        }
    }

    onWallpaperPathsChanged: _maybeFirstRun()

    Connections {
        target: ThemeLoader
        function onConfigLoadedChanged() {
            wallpaper._maybeFirstRun();
        }
        function onThumbnailPathChanged() {
            // video wallpapers: the clock is placed from the thumbnail switchwall.sh makes
            if (wallpaper.currentIsVideo && GlobalStates.wallpaperManager === wallpaper)
                wallpaper._scheduleFollowUp();
        }
    }

    // ── Deferred follow-up work ─────────────────────────────────────────────────
    // Python jobs (clock placement, lockscreen frame) must not run while switchwall.sh
    // (matugen + python) and the transition are using the CPU/GPU. They run later, one after
    // the other, at low priority.
    function _scheduleFollowUp() {
        followUpClock.restart();
        followUpLock.restart();
    }

    Timer {
        id: followUpClock
        interval: 2500
        onTriggered: ClockPlacement.update(wallpaper.currentIsVideo ? ThemeLoader.thumbnailPath : wallpaper.currentWallpaper)
    }

    Timer {
        id: followUpLock
        interval: 6000
        onTriggered: {
            if (wallpaper.currentWallpaper)
                wallpaper.generateLockscreenFrame(wallpaper.currentWallpaper);
        }
    }

    Component.onCompleted: {
        // Every screen's instance shows the current wallpaper right away
        if (displayPath !== "")
            _show(displayPath);

        // Only the first Wallpaper instance should manage scanning
        // Other instances (for other screens) share the same data via GlobalStates
        if (GlobalStates.wallpaperManager !== null) {
            _wallpaperDirInitialized = true;
            return;
        }

        GlobalStates.wallpaperManager = wallpaper;

        checkWallpapersJson.running = true;

        scanColorPresets();
        presetsWatcher.reload();
        officialPresetsWatcher.reload();
        // Triggers onWallPathChanged which does the actual scan
        wallpaperConfig.reload();

        if (currentWallpaper)
            _scheduleFollowUp();
    }

    // wallpapers.json now only keeps shell-local UI state (browse folder, local preset).
    // Wallpaper path, scheme and colours are NOT stored here any more.
    FileView {
        id: wallpaperConfig
        path: Quickshell.cachePath("wallpapers.json")
        watchChanges: true

        onLoaded: {
            if (!wallpaperConfig.adapter.wallPath) {
                console.log("Loaded config but wallPath is empty, using fallback");
                wallpaperConfig.adapter.wallPath = fallbackDir;
            }
        }

        onFileChanged: reload()
        // One writer only: every screen has its own copy of this FileView.
        onAdapterUpdated: {
            if (GlobalStates.wallpaperManager === wallpaper)
                writeAdapter();
        }

        JsonAdapter {
            id: wallpaperAdapter
            property string wallPath: ""
            property string activeColorPreset: ""

            onWallPathChanged: {
                if (wallPath) {
                    console.log("Config wallPath updated:", wallPath);

                    // Initialize scanning on first valid wallPath load
                    if (!wallpaper._wallpaperDirInitialized && GlobalStates.wallpaperManager === wallpaper) {
                        wallpaper._wallpaperDirInitialized = true;

                        // Set up directory watcher
                        directoryWatcher.path = wallPath;
                        directoryWatcher.reload();

                        // Perform initial wallpaper scan
                        var cmd = ["find", wallPath, "-name", ".*", "-prune", "-o", "-type", "f", "(", "-name", "*.jpg", "-o", "-name", "*.jpeg", "-o", "-name", "*.png", "-o", "-name", "*.webp", "-o", "-name", "*.tif", "-o", "-name", "*.tiff", "-o", "-name", "*.gif", "-o", "-name", "*.mp4", "-o", "-name", "*.webm", "-o", "-name", "*.mov", "-o", "-name", "*.avi", "-o", "-name", "*.mkv", ")", "-print"];
                        scanWallpapers.command = cmd;
                        scanWallpapers.running = true;
                        wallpaper.scanSubfolders();

                        // Start thumbnail generation
                        delayedThumbnailGen.start();
                    }
                }
            }
        }
    }

    Process {
        id: checkWallpapersJson
        running: false
        command: ["test", "-f", Quickshell.cachePath("wallpapers.json")]

        onExited: function (exitCode) {
            if (exitCode !== 0) {
                console.log("wallpapers.json does not exist, creating with fallbackDir");
                wallpaperConfig.adapter.wallPath = fallbackDir;
            } else {
                console.log("wallpapers.json exists");
            }
        }
    }

    // Proceso para generar thumbnails de videos
    Process {
        id: thumbnailGeneratorScript
        running: false
        command: ["python3", decodeURIComponent(Qt.resolvedUrl("../../../../scripts/thumbgen.py").toString().replace("file://", "")), Quickshell.cacheDir + "/wallpapers.json", Quickshell.cacheDir, fallbackDir]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    console.log("Thumbnail Generator:", text);
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    console.warn("Thumbnail Generator Error:", text);
                }
            }
        }

        onExited: function (exitCode) {
            if (exitCode === 0) {
                console.log("✅ Video thumbnails generated successfully");
                thumbnailsVersion++;
            } else {
                console.warn("⚠️ Thumbnail generation failed with code:", exitCode);
            }
        }
    }

    Timer {
        id: delayedThumbnailGen
        interval: 2000 // Delay 2 seconds after change to not block
        repeat: false
        onTriggered: thumbnailGeneratorScript.running = true
    }

    // Proceso para generar frame de lockscreen con el script de Python
    Process {
        id: lockscreenWallpaperScript
        running: false
        command: []

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    console.log("Lockscreen Wallpaper Generator:", text);
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    console.warn("Lockscreen Wallpaper Generator Error:", text);
                }
            }
        }

        onExited: function (exitCode) {
            if (exitCode === 0) {
                console.log("✅ Lockscreen wallpaper ready");
            } else {
                console.warn("⚠️ Lockscreen wallpaper generation failed with code:", exitCode);
            }
        }
    }

    Process {
        id: scanSubfoldersProcess
        running: false
        command: wallpaperDir ? ["find", wallpaperDir, "-mindepth", "1", "-name", ".*", "-prune", "-o", "-type", "d", "-print"] : []

        stdout: StdioCollector {
            onStreamFinished: {
                console.log("scanSubfolders stdout:", text);
                var rawPaths = text.trim().split("\n").filter(function (f) {
                    return f.length > 0;
                });

                allSubdirs = rawPaths;

                var basePath = wallpaperDir.endsWith("/") ? wallpaperDir : wallpaperDir + "/";

                var topLevelFolders = rawPaths.filter(function (path) {
                    var relative = path.replace(basePath, "");
                    return relative.indexOf("/") === -1;
                }).map(function (path) {
                    return path.split("/").pop();
                }).filter(function (name) {
                    return name.length > 0 && !name.startsWith(".");
                });

                topLevelFolders.sort();
                subfolderFilters = topLevelFolders;
                subfolderFiltersChanged();  // Emitir señal manualmente
                console.log("Updated subfolderFilters:", subfolderFilters);
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    console.warn("Error scanning subfolders:", text);
                }
            }
        }

        onRunningChanged: {
            if (running) {
                console.log("Starting scanSubfolders for directory:", wallpaperDir);
            } else {
                console.log("Finished scanSubfolders");
            }
        }
    }

    // Directory watcher using FileView to monitor the wallpaper directory
    FileView {
        id: directoryWatcher
        path: wallpaperDir
        watchChanges: true
        printErrors: false

        onFileChanged: {
            if (wallpaperDir === "")
                return;
            console.log("Wallpaper directory changed, rescanning...");
            scanWallpapers.running = true;
            scanSubfoldersProcess.running = true;
            // Regenerar thumbnails si hay nuevos videos (delayed)
            if (delayedThumbnailGen.running)
                delayedThumbnailGen.restart();
            else
                delayedThumbnailGen.start();
        }

        // Remove onLoadFailed to prevent premature fallback activation
    }

    // Recursive directory watchers for subfolders
    Instantiator {
        model: allSubdirs

        delegate: FileView {
            path: modelData
            watchChanges: true
            printErrors: false
            onFileChanged: {
                console.log("Subdirectory content changed (" + path + "), rescanning...");
                scanWallpapers.running = true;
                scanSubfoldersProcess.running = true;

                // Regenerar thumbnails (delayed)
                if (delayedThumbnailGen.running)
                    delayedThumbnailGen.restart();
                else
                    delayedThumbnailGen.start();
            }
        }
    }

    // Directory watcher for user color presets
    FileView {
        id: presetsWatcher
        path: colorPresetsDir
        watchChanges: true
        printErrors: false

        onFileChanged: {
            console.log("User color presets directory changed, rescanning...");
            scanPresetsProcess.running = true;
        }
    }

    // Directory watcher for official color presets
    FileView {
        id: officialPresetsWatcher
        path: officialColorPresetsDir
        watchChanges: true
        printErrors: false

        onFileChanged: {
            console.log("Official color presets directory changed, rescanning...");
            scanPresetsProcess.running = true;
        }
    }

    Process {
        id: scanWallpapers
        running: false
        command: wallpaperDir ? ["find", wallpaperDir, "-name", ".*", "-prune", "-o", "-type", "f", "(", "-name", "*.jpg", "-o", "-name", "*.jpeg", "-o", "-name", "*.png", "-o", "-name", "*.webp", "-o", "-name", "*.tif", "-o", "-name", "*.tiff", "-o", "-name", "*.gif", "-o", "-name", "*.mp4", "-o", "-name", "*.webm", "-o", "-name", "*.mov", "-o", "-name", "*.avi", "-o", "-name", "*.mkv", ")", "-print"] : []

        onRunningChanged: {
            if (running && wallpaperDir === "") {
                console.log("Blocking scanWallpapers because wallpaperDir is empty");
                running = false;
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                var files = text.trim().split("\n").filter(function (f) {
                    return f.length > 0;
                });
                if (files.length === 0) {
                    console.log("No wallpapers found in main directory, using fallback");
                    usingFallback = true;
                    scanFallback.running = true;
                } else {
                    usingFallback = false;
                    // Only update if the list has actually changed
                    var newFiles = files.sort();
                    if (JSON.stringify(newFiles) !== JSON.stringify(wallpaperPaths)) {
                        console.log("Wallpaper directory updated. Found", newFiles.length, "images");
                        wallpaperPaths = newFiles;
                        if (delayedThumbnailGen.running)
                            delayedThumbnailGen.restart();
                        else
                            delayedThumbnailGen.start();
                    }
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    console.warn("Error scanning wallpaper directory:", text);
                    // Only fallback if we don't already have wallpapers loaded AND we have a valid directory that failed
                    if (wallpaperPaths.length === 0 && wallpaperDir !== "") {
                        console.log("Directory scan failed for " + wallpaperDir + ", using fallback");
                        usingFallback = true;
                        scanFallback.running = true;
                    }
                }
            }
        }
    }

    Process {
        id: scanFallback
        running: false
        command: ["find", fallbackDir, "-name", ".*", "-prune", "-o", "-type", "f", "(", "-name", "*.jpg", "-o", "-name", "*.jpeg", "-o", "-name", "*.png", "-o", "-name", "*.webp", "-o", "-name", "*.tif", "-o", "-name", "*.tiff", "-o", "-name", "*.gif", "-o", "-name", "*.mp4", "-o", "-name", "*.webm", "-o", "-name", "*.mov", "-o", "-name", "*.avi", "-o", "-name", "*.mkv", ")", "-print"]

        stdout: StdioCollector {
            onStreamFinished: {
                var files = text.trim().split("\n").filter(function (f) {
                    return f.length > 0;
                });
                console.log("Using fallback wallpapers. Found", files.length, "images");

                // Only use fallback if we don't already have main wallpapers loaded
                if (usingFallback)
                    wallpaperPaths = files.sort();
            }
        }
    }

    Process {
        id: scanPresetsProcess
        running: false
        // Scan both directories. find will complain to stderr if one is missing but still output what it finds.
        command: ["find", officialColorPresetsDir, colorPresetsDir, "-mindepth", "1", "-maxdepth", "1", "-type", "d"]

        stdout: StdioCollector {
            onStreamFinished: {
                console.log("Scan Presets Output:", text);
                var rawLines = text.trim().split("\n");
                var uniqueNames = [];
                for (var i = 0; i < rawLines.length; i++) {
                    var line = rawLines[i].trim();
                    if (line.length === 0)
                        continue;
                    var name = line.split('/').pop();
                    // Deduplicate
                    if (uniqueNames.indexOf(name) === -1) {
                        uniqueNames.push(name);
                    }
                }
                uniqueNames.sort();
                console.log("Found color presets:", uniqueNames);
                colorPresets = uniqueNames;
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                // Suppress common "No such file or directory" if one dir is missing
                // console.warn("Scan Presets Error:", text);
            }
        }
    }

    // ── Rendering (same design as end4-pC's Background.qml) ─────────────────────
    // Two images + one GPU shader. The path comes straight from the shared config.json via
    // ThemeLoader, so any change to it (this shell, end4's shell, a terminal) swaps the
    // wallpaper. Videos are drawn by mpvpaper (switchwall.sh): this window stays empty.
    //
    // The two images are double-buffered: the new wallpaper loads into the idle one, the circle
    // grows, then the roles swap. The old wallpaper is never decoded a second time.
    readonly property string displayPath: currentIsVideo ? "" : currentWallpaper
    property string shownPath: ""
    property Item front: imageA          // what is on screen when idle
    property Item back: imageB           // where the next wallpaper loads
    property real transitionProgress: 0.0
    property bool _transitionPending: false   // waiting for `back` to finish loading
    readonly property bool shaderOk: transitionEffect.status !== ShaderEffect.Error

    onDisplayPathChanged: _show(displayPath)

    function _url(path) {
        return path ? "file://" + path : "";
    }

    function _swap() {
        var f = front;
        front = back;
        back = f;
        back.source = "";
        transitionProgress = 0.0; // idle = progress 0 = only `front` visible
    }

    function _show(path) {
        // finish / drop whatever was in flight
        if (transitionAnim.running) {
            transitionAnim.stop();
            _swap();
        } else if (_transitionPending) {
            _transitionPending = false;
            back.source = "";
        }
        loadGuard.stop();

        if (path === "") {
            front.source = "";
            shownPath = "";
            return;
        }
        if (path === shownPath)
            return;

        if (shownPath === "" || Config.animDuration <= 0 || !shaderOk) {
            front.source = _url(path);
            shownPath = path;
            return;
        }

        shownPath = path;
        _transitionPending = true;
        back.source = _url(path);
        loadGuard.restart();
        if (back.status === Image.Ready)
            _beginReveal();
    }

    function _beginReveal() {
        if (!_transitionPending)
            return;
        _transitionPending = false;
        loadGuard.stop();
        transitionProgress = 0.0;
        transitionAnim.restart();
    }

    function _imageStatusChanged(img) {
        if (img !== back || !_transitionPending)
            return;
        if (img.status === Image.Ready) {
            _beginReveal();
        } else if (img.status === Image.Error) {
            // couldn't load: keep what is on screen
            _transitionPending = false;
            loadGuard.stop();
            back.source = "";
        }
    }

    // never stay stuck waiting for an image
    Timer {
        id: loadGuard
        interval: 4000
        onTriggered: {
            if (wallpaper._transitionPending) {
                wallpaper._transitionPending = false;
                wallpaper.back.source = "";
                wallpaper.front.source = wallpaper._url(wallpaper.shownPath);
            }
        }
    }

    NumberAnimation {
        id: transitionAnim
        target: wallpaper
        property: "transitionProgress"
        from: 0.0
        to: 1.0
        duration: 1000
        easing.type: Easing.InOutCubic
        onFinished: wallpaper._swap()
    }

    component WallpaperImage: Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        cache: true
        smooth: true
        asynchronous: true
        // Cap decode size at the screen's pixel width (huge wallpapers would otherwise stall the
        // texture upload). Height follows the aspect ratio.
        // (uses the screen size, which is known at creation, so the image never reloads when the window gets its size)
        sourceSize.width: wallpaper.screen ? Math.ceil(wallpaper.screen.width * wallpaper.screen.devicePixelRatio) : 0
        // As a layer the item renders to a texture with the crop applied; that texture is what the
        // shader samples. Always on (like end4): toggling it with the source made the shader sample
        // the raw uncropped texture during the transition, then jump to the cropped one at the swap.
        layer.enabled: true
        // Hidden normally: the ShaderEffect draws them. Fallback if the shader failed: draw `front` directly.
        onStatusChanged: wallpaper._imageStatusChanged(this)
    }

    Item {
        anchors.fill: parent

        WallpaperImage {
            id: imageA
            visible: !wallpaper.shaderOk && wallpaper.front === imageA
        }

        WallpaperImage {
            id: imageB
            visible: !wallpaper.shaderOk && wallpaper.front === imageB
        }

        ShaderEffect {
            id: transitionEffect
            anchors.fill: parent
            visible: wallpaper.shaderOk && wallpaper.shownPath !== ""

            property var fromImage: wallpaper.front
            property var toImage: wallpaper.back
            property real progress: wallpaper.transitionProgress
            property real aspect: height > 0 ? width / height : 1.0
            property vector2d origin: Qt.vector2d(0.5, 0.5)
            property real softness: 0.12

            fragmentShader: Qt.resolvedUrl("shaders/wallpaper_circle.frag.qsb")
        }
    }
}
