import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import qs.modules.theme
import qs.modules.bar.workspaces
import qs.modules.services
import qs.modules.components
import qs.config
import qs.modules.globals

Item {
    id: compactPlayer

    required property var player
    required property bool notchHovered

    onPlayerChanged: {
        if (!player) {
            positionSlider.value = 0;
        }
        playbackActive = (player?.playbackState === MprisPlaybackState.Playing) ?? false
    }

    property bool isPlaying: player?.playbackState === MprisPlaybackState.Playing

    // playbackActive is an explicit bool that opacity bindings depend on.
    // isPlaying uses optional chaining (player?.playbackState) which QML's
    // binding engine doesn't always re-evaluate when playbackState changes
    // on the player object — so we update this manually via Connections.
    property bool playbackActive: false

    Connections {
        target: compactPlayer.player
        enabled: compactPlayer.player !== null
        function onPlaybackStateChanged() {
            compactPlayer.playbackActive =
            (compactPlayer.player?.playbackState === MprisPlaybackState.Playing) ?? false
        }
    }
    property real position: player?.position ?? 0.0
    property real length: player?.length ?? 1.0
    property bool hasArtwork: (player?.trackArtUrl ?? "") !== ""
    property string wallpaperPath: {
        if (!GlobalStates.wallpaperManager) return "";
        let path = GlobalStates.wallpaperManager.currentWallpaper;
        let frame = GlobalStates.wallpaperManager.getLockscreenFramePath(path);
        return frame ? "file://" + frame : "";
    }

    readonly property string focusedTitle: {
        const activeWsId = Hyprland.focusedMonitor?.activeWorkspace?.id;
        if (!activeWsId) return "";
        const windows = HyprlandData.workspaceWindowsMap[activeWsId] || [];
        if (windows.length === 0) return "";
        const best = windows.reduce((best, win) => {
            const bestFocus = best?.focusHistoryID ?? Infinity;
            const winFocus = win?.focusHistoryID ?? Infinity;
            return winFocus < bestFocus ? win : best;
        }, null);
        return best ? best.title : "";
    }

    property string hostname: ""

    Process {
        id: hostnameReader
        running: true
        command: ["hostname"]

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const host = text.trim();
                if (host) {
                    compactPlayer.hostname = host;
                }
            }
        }
    }

    readonly property string userHostText: {
        const user = Quickshell.env("USER") || "user";
        const host = hostname || "host";
        return user + "@" + host;
    }

    readonly property string noMediaText: {
        const displayType = Config.notch.noMediaDisplay ?? "userHost";
        if (displayType === "userHost") return userHostText;
        if (displayType === "compositor") return "Hyprland";
        return Config.notch.customText ?? "Ambxst";
    }

    readonly property string displayedTitle: {
        if (player) {
            return (player.trackArtist ? player.trackArtist + " - " : "") + (player.trackTitle || "Unknown");
        }
        return focusedTitle || noMediaText;
    }

    function getPlayerIcon(player) {
        if (!player)
            return Icons.player;
        const dbusName = (player.dbusName || "").toLowerCase();
        const desktopEntry = (player.desktopEntry || "").toLowerCase();
        const identity = (player.identity || "").toLowerCase();
        if (dbusName.includes("spotify") || desktopEntry.includes("spotify") || identity.includes("spotify"))
            return Icons.spotify;
        if (dbusName.includes("chromium") || dbusName.includes("chrome") || desktopEntry.includes("chromium") || desktopEntry.includes("chrome"))
            return Icons.chromium;
        if (dbusName.includes("firefox") || desktopEntry.includes("firefox"))
            return Icons.firefox;
        if (dbusName.includes("telegram") || desktopEntry.includes("telegram") || identity.includes("telegram"))
            return Icons.telegram;
        return Icons.player;
    }

    function syncPositionSlider() {
        if (!positionSlider.isDragging) {
            positionSlider.value = compactPlayer.length > 0 ? Math.min(1.0, compactPlayer.position / compactPlayer.length) : 0;
        }
        compactPlayer.player?.positionChanged();
    }

    // The position slider is only visible while the notch is hovered, so only
    // tick (and ask the player over D-Bus for its position) then. Otherwise this
    // woke the shell every second for nothing whenever audio was playing.
    Timer {
        running: compactPlayer.isPlaying && compactPlayer.visible && compactPlayer.notchHovered
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: compactPlayer.syncPositionSlider()
    }

    Connections {
        target: compactPlayer.player
        enabled: compactPlayer.player !== null
        function onPositionChanged() {
            if (!positionSlider.isDragging && compactPlayer.player) {
                positionSlider.value = compactPlayer.length > 0 ? Math.min(1.0, compactPlayer.position / compactPlayer.length) : 0;
            }
        }
    }

    StyledRect {
        variant: "common"
        anchors.fill: parent
        radius: Styling.radius(-4)

        // ── CRT oscilloscope waveform ─────────────────────────────────────────
        // A single continuous bezier line running left→right across the notch.
        // Each Cava bar value maps to a Y displacement from the center midline.
        // Low energy = nearly flat line. High energy = wild oscillation.
        // Drawn in two passes: thick soft glow beneath, thin crisp line on top.
        Canvas {
            id: compactCavaCanvas
            anchors.fill: parent
            z: 5

            visible: opacity > 0
            opacity: (compactPlayer.playbackActive && Cava.active && !compactPlayer.notchHovered) ? 1.0 : 0.0

            Behavior on opacity {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutQuart
                }
            }

            property var  smoothed:   []
            property real beatEnergy: 0.0
            property real beatPulse:  0.0

            // Exponential smoothing — fast attack, slow release
            readonly property real alphaRise: 0.55
            readonly property real alphaFall: 0.14
            readonly property real beatThreshold: 1.50

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var sm = compactCavaCanvas.smoothed
                var n  = sm ? sm.length : 0
                if (n < 2) return

                    var w      = width
                    var h      = height
                    var mid    = h / 2
                    var pulse  = compactCavaCanvas.beatPulse
                    var maxAmp = mid * 0.82   // leave a sliver so it never touches the pill edge

                    var pr = Colors.primary.r
                    var pg = Colors.primary.g
                    var pb = Colors.primary.b

                    // ── Build oscilloscope waveform points ───────────────────────
                    // Each point's Y = weighted mix of:
                    //   • the bar's own energy (how loud this frequency band is)
                    //   • the second derivative (bar[i-1] - 2*bar[i] + bar[i+1])
                    //     which is negative at peaks and positive at valleys →
                    //     gives natural, stable zero-crossings without any
                    //     stateful sign variable that can jump between frames.
                    // This produces a waveform whose shape changes smoothly with
                    // the music — dense mid content = many wiggles, bass-only =
                    // slow wide sweep — and never crumbles or flips erratically.
                    var pts = []
                    for (var i = 0; i < n; ++i) {
                        var px    = (i / (n - 1)) * w

                        var cur   = sm[i]
                        var prev2 = sm[Math.max(0, i - 1)]
                        var next2 = sm[Math.min(n - 1, i + 1)]

                        // Second derivative: negative at spectral peaks, positive at dips
                        var d2    = (prev2 - 2 * cur + next2) / 100   // range ≈ -2..+2

                        // Overall energy of this bar (absolute displacement scale)
                        var norm  = cur / 100
                        var energy = Math.pow(norm, 0.50)

                        // Blend: mostly d2-driven (gives crossings), scaled by energy
                        // so quiet bars stay near center regardless of their curvature
                        var amp = d2 * energy * maxAmp * 3.5 * (1.0 + pulse * 0.30)

                        // Hard clamp — prevents wave from ever going outside the canvas
                        amp = Math.max(-maxAmp * 0.88, Math.min(maxAmp * 0.88, amp))

                        // Soft taper at edges
                        var taper = Math.sin((i / (n - 1)) * Math.PI)
                        pts.push({ x: px, y: mid + amp * taper })
                    }

                    // ── Catmull-Rom spline for a smooth, organic oscilloscope curve ──
                    function drawSpline(pts) {
                        ctx.beginPath()
                        ctx.moveTo(pts[0].x, pts[0].y)
                        for (var k = 0; k < pts.length - 1; ++k) {
                            var p0 = pts[Math.max(0, k-1)]
                            var p1 = pts[k]
                            var p2 = pts[k+1]
                            var p3 = pts[Math.min(pts.length-1, k+2)]
                            // Convert Catmull-Rom to cubic bezier control points
                            var cp1x = p1.x + (p2.x - p0.x) / 6
                            var cp1y = p1.y + (p2.y - p0.y) / 6
                            var cp2x = p2.x - (p3.x - p1.x) / 6
                            var cp2y = p2.y - (p3.y - p1.y) / 6
                            ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, p2.x, p2.y)
                        }
                    }

                    var totalE = 0
                    for (var q = 0; q < n; ++q) totalE += sm[q]
                        var avgE  = totalE / n / 100
                        var lineA = Math.min(1.0, 0.65 + avgE * 0.35 + pulse * 0.20)

                        if (lineA < 0.05) return

                            ctx.lineCap  = "round"
                            ctx.lineJoin = "round"

                            // ── Neon CRT glow — tight layered passes ──────────────────────
                            // The trick for clean neon: keep the outer bloom very low alpha
                            // and very narrow, so it reads as a soft halo not a fat shadow.
                            // The brightness lives in the core, not the bloom.

                            // Pass 1 — subtle outer aura, barely visible, just gives depth
                            drawSpline(pts)
                            ctx.strokeStyle = Qt.rgba(pr, pg, pb, 0.10)
                            ctx.lineWidth   = 8.0
                            ctx.stroke()

                            // Pass 2 — tight inner halo
                            drawSpline(pts)
                            ctx.strokeStyle = Qt.rgba(pr, pg, pb, lineA * 0.45)
                            ctx.lineWidth   = 3.0
                            ctx.stroke()

                            // Pass 3 — bright core line
                            drawSpline(pts)
                            ctx.strokeStyle = Qt.rgba(pr, pg, pb, lineA * 0.90)
                            ctx.lineWidth   = 1.5
                            ctx.stroke()

                            // Pass 4 — white-hot center at high energy (makes it feel electric)
                            var hot = avgE + pulse * 0.4
                            if (hot > 0.2) {
                                var coreR = Math.min(1.0, pr + hot * (1.0 - pr) * 0.8)
                                var coreG = Math.min(1.0, pg + hot * (1.0 - pg) * 0.8)
                                var coreB = Math.min(1.0, pb + hot * (1.0 - pb) * 0.8)
                                drawSpline(pts)
                                ctx.strokeStyle = Qt.rgba(coreR, coreG, coreB, Math.min(1.0, hot * 1.2))
                                ctx.lineWidth   = 0.75
                                ctx.stroke()
                            }

            }

            Connections {
                target: Cava
                function onValuesChanged() {
                    if (!compactCavaCanvas.visible) return

                        var raw  = Cava.values
                        var n    = (raw && raw.length) ? raw.length : 0
                        if (n === 0) return

                            var prev  = compactCavaCanvas.smoothed
                            var aR    = compactCavaCanvas.alphaRise
                            var aF    = compactCavaCanvas.alphaFall
                            var next  = new Array(n)
                            var total = 0.0

                            for (var i = 0; i < n; ++i) {
                                var rv   = Math.max(0, Math.min(100, raw[i]))
                                var pv   = (prev && prev.length > i) ? prev[i] : 0.0
                                var a    = (rv >= pv) ? aR : aF
                                next[i]  = pv + a * (rv - pv)
                                total   += next[i]
                            }
                            compactCavaCanvas.smoothed = next

                            // Beat detection
                            var instant = total / n
                            var rolling = compactCavaCanvas.beatEnergy
                            compactCavaCanvas.beatEnergy = rolling * 0.90 + instant * 0.10

                            if (rolling > 3.0 && instant > rolling * compactCavaCanvas.beatThreshold) {
                                var mag = Math.min(1.0, (instant / rolling - compactCavaCanvas.beatThreshold) * 1.6)
                                compactCavaCanvas.beatPulse = mag
                            } else {
                                compactCavaCanvas.beatPulse = compactCavaCanvas.beatPulse * 0.50
                            }

                            compactCavaCanvas.requestPaint()
                }
            }
        }

        // ── Fallback text — shown when no player is active ─────────────────
        Text {
            id: noMediaLabel
            anchors.centerIn: parent
            width: parent.width - 32
            text: compactPlayer.displayedTitle
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(0)
            font.bold: true
            color: Colors.overBackground
            elide: Text.ElideRight
            visible: opacity > 0
            // Reactive: shows when paused, no player or visualizer off (Cava.active false), hides when playing or hovered — no polling
            opacity: (!compactPlayer.notchHovered && (!compactPlayer.player || !compactPlayer.playbackActive || !Cava.active)) ? 1.0 : 0.0
            horizontalAlignment: Text.AlignHCenter
            z: 5

            Behavior on opacity {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutQuart
                }
            }
        }

        ClippingRectangle {
            anchors.fill: parent
            radius: Styling.radius(-4)
            color: "transparent"

            Image {
                mipmap: true
                id: backgroundArt
                anchors.fill: parent
                source: (compactPlayer.player?.trackArtUrl ?? "") !== "" ? compactPlayer.player.trackArtUrl : compactPlayer.wallpaperPath
                sourceSize: Qt.size(64, 64)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }

            MultiEffect {
                anchors.fill: backgroundArt
                source: backgroundArt
                // Only enable blur when there's content to blur (saves GPU)
                blurEnabled: hasArtwork || wallpaperPath !== ""
                blurMax: 32
                blur: 0.75
                autoPaddingEnabled: false
                opacity: (hasArtwork || wallpaperPath !== "") ? 1.0 : 0.0
                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }
            }

            StyledRect {
                anchors.fill: parent
                variant: "internalbg"
                opacity: (hasArtwork || wallpaperPath !== "") ? 0.5 : 0.0
                radius: Styling.radius(-4)
                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: (compactPlayer.player !== null || compactPlayer.notchHovered) ? 4 : 0
            anchors.rightMargin: (compactPlayer.player !== null || compactPlayer.notchHovered) ? 4 : 0
            spacing: (compactPlayer.player !== null && compactPlayer.notchHovered) ? 4 : 0
            layer.enabled: true
            layer.effect: BgShadow {}
            opacity: (compactPlayer.notchHovered && compactPlayer.player) ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutQuart
                }
            }
            Behavior on spacing {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutQuart
                }
            }

            Item {
                id: artworkContainer
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                visible: compactPlayer.notchHovered
                ClippingRectangle {
                    anchors.fill: parent
                    radius: compactPlayer.isPlaying ? Styling.radius(-8) : Styling.radius(-4)
                    color: "transparent"
                    Image {
                        mipmap: true
                        id: artworkImage
                        anchors.fill: parent
                        source: (compactPlayer.player?.trackArtUrl ?? "") !== "" ? compactPlayer.player.trackArtUrl : compactPlayer.wallpaperPath
                        sourceSize: Qt.size(48, 48)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: false
                    }
                    MultiEffect {
                        anchors.fill: parent
                        source: artworkImage
                        // Only enable blur when there's content to blur (saves GPU)
                        blurEnabled: (hasArtwork || wallpaperPath !== "") && compactPlayer.notchHovered
                        blurMax: 32
                        blur: 0.75
                        opacity: (hasArtwork || wallpaperPath !== "") ? 1.0 : 0.0 // Simplificado
                        Behavior on opacity {
                            enabled: Config.animDuration > 0
                            NumberAnimation {
                                duration: Config.animDuration
                                easing.type: Easing.OutQuart
                            }
                        }
                    }

                    StyledRect {
                        anchors.fill: parent
                        variant: "internalbg"
                        opacity: ((hasArtwork || wallpaperPath !== "") && compactPlayer.notchHovered) ? 0.5 : 0.0
                        radius: parent.radius ?? 0
                        Behavior on opacity {
                            enabled: Config.animDuration > 0
                            NumberAnimation {
                                duration: Config.animDuration
                                easing.type: Easing.OutQuart
                            }
                        }
                    }

                    Text {
                        id: playPauseBtn
                        anchors.centerIn: parent
                        text: compactPlayer.isPlaying ? Icons.pause : Icons.play
                        textFormat: Text.RichText
                        color: playPauseHover.hovered ? ((hasArtwork || wallpaperPath !== "") ? Styling.srItem("overprimary") : Styling.srItem("overprimary")) : ((hasArtwork || wallpaperPath !== "") ? Colors.overBackground : Colors.overBackground)
                        font.pixelSize: 16
                        font.family: Icons.font
                        opacity: (compactPlayer.player?.canPause ?? false) && compactPlayer.notchHovered ? 1.0 : 0.0
                        scale: 1.0
                        layer.enabled: true
                        layer.effect: BgShadow {}
                        visible: opacity > 0
                        Behavior on opacity {
                            enabled: Config.animDuration > 0
                            NumberAnimation {
                                duration: Config.animDuration
                                easing.type: Easing.OutQuart
                            }
                        }
                        Behavior on color {
                            enabled: Config.animDuration > 0
                            ColorAnimation {
                                duration: Config.animDuration
                                easing.type: Easing.OutQuart
                            }
                        }
                        Behavior on scale {
                            enabled: Config.animDuration > 0
                            NumberAnimation {
                                duration: Config.animDuration
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.5
                            }
                        }
                        HoverHandler {
                            id: playPauseHover
                            enabled: compactPlayer.player !== null && compactPlayer.notchHovered
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: compactPlayer.player ? Qt.PointingHandCursor : Qt.ArrowCursor
                            enabled: compactPlayer.player !== null && compactPlayer.notchHovered
                            onClicked: {
                                playPauseBtn.scale = 1.1;
                                compactPlayer.player?.togglePlaying();
                                playPauseScaleTimer.restart();
                            }
                        }
                        Timer {
                            id: playPauseScaleTimer
                            interval: 100
                            onTriggered: playPauseBtn.scale = 1.0
                        }
                    }
                }
            }

            Text {
                id: previousBtn
                text: Icons.previous
                textFormat: Text.RichText
                color: previousHover.hovered ? ((hasArtwork || wallpaperPath !== "") ? Styling.srItem("overprimary") : Styling.srItem("overprimary")) : Colors.overBackground
                font.pixelSize: 16
                font.family: Icons.font
                opacity: compactPlayer.player?.canGoPrevious ?? false ? 1.0 : 0.3
                visible: compactPlayer.player !== null && compactPlayer.notchHovered && (compactPlayer.player?.canGoPrevious ?? false)
                clip: true
                scale: 1.0
                readonly property real naturalWidth: implicitWidth
                Layout.preferredWidth: (compactPlayer.player !== null && compactPlayer.notchHovered) ? naturalWidth : 0
                Behavior on Layout.preferredWidth {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }
                Behavior on color {
                    enabled: Config.animDuration > 0
                    ColorAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }
                Behavior on scale {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.5
                    }
                }
                HoverHandler {
                    id: previousHover
                    enabled: compactPlayer.player?.canGoPrevious ?? false
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: compactPlayer.player?.canGoPrevious ?? false ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: compactPlayer.player?.canGoPrevious ?? false
                    onClicked: {
                        previousBtn.scale = 1.5;
                        compactPlayer.player?.previous();
                        previousScaleTimer.restart();
                    }
                }
                Timer {
                    id: previousScaleTimer
                    interval: 100
                    onTriggered: previousBtn.scale = 1.0
                }
            }

            PositionSlider {
                id: positionSlider
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                Layout.leftMargin: compactPlayer.notchHovered ? 0 : 8
                Layout.rightMargin: compactPlayer.notchHovered ? 0 : 8
                player: compactPlayer.player
                visible: compactPlayer.notchHovered
                hasArtwork: compactPlayer.hasArtwork || compactPlayer.wallpaperPath !== ""
            }

            Text {
                id: nextBtn
                text: Icons.next
                textFormat: Text.RichText
                color: nextHover.hovered ? ((hasArtwork || wallpaperPath !== "") ? Styling.srItem("overprimary") : Styling.srItem("overprimary")) : Colors.overBackground
                font.pixelSize: 16
                font.family: Icons.font
                opacity: compactPlayer.player?.canGoNext ?? false ? 1.0 : 0.3
                clip: true
                scale: 1.0
                visible: compactPlayer.notchHovered
                readonly property real naturalWidth: implicitWidth
                Layout.preferredWidth: (compactPlayer.player !== null && compactPlayer.notchHovered) ? naturalWidth : 0
                Behavior on Layout.preferredWidth {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }
                Behavior on color {
                    enabled: Config.animDuration > 0
                    ColorAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }
                Behavior on scale {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.5
                    }
                }
                HoverHandler {
                    id: nextHover
                    enabled: compactPlayer.player?.canGoNext ?? false
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: compactPlayer.player?.canGoNext ?? false ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: compactPlayer.player?.canGoNext ?? false
                    onClicked: {
                        nextBtn.scale = 1.1;
                        compactPlayer.player?.next();
                        nextScaleTimer.restart();
                    }
                }
                Timer {
                    id: nextScaleTimer
                    interval: 100
                    onTriggered: nextBtn.scale = 1.0
                }
            }

            Text {
                id: modeBtn
                text: {
                    if (MprisController.hasShuffle)
                        return Icons.shuffle;
                    switch (MprisController.loopState) {
                        case MprisLoopState.Track:
                            return Icons.repeatOnce;
                        case MprisLoopState.Playlist:
                            return Icons.repeat;
                        default:
                            return Icons.shuffle;
                    }
                }
                textFormat: Text.RichText
                color: modeBtn.modeHover.hovered ? ((hasArtwork || wallpaperPath !== "") ? Styling.srItem("overprimary") : Styling.srItem("overprimary")) : Colors.overBackground
                property alias modeHover: modeHover
                font.pixelSize: 16
                font.family: Icons.font
                opacity: {
                    if (!(MprisController.shuffleSupported || MprisController.loopSupported))
                        return 0.3;
                    if (!MprisController.hasShuffle && MprisController.loopState === MprisLoopState.None)
                        return 0.3;
                    return 1.0;
                }
                clip: true
                scale: 1.0
                visible: compactPlayer.notchHovered
                readonly property real naturalWidth: implicitWidth
                Layout.preferredWidth: (compactPlayer.player !== null && compactPlayer.notchHovered) ? naturalWidth : 0
                Behavior on Layout.preferredWidth {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }
                Behavior on color {
                    enabled: Config.animDuration > 0
                    ColorAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }
                Behavior on scale {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.5
                    }
                }
                HoverHandler {
                    id: modeHover
                    enabled: MprisController.shuffleSupported || MprisController.loopSupported
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: MprisController.shuffleSupported || MprisController.loopSupported
                    onClicked: {
                        modeBtn.scale = 1.1;
                        if (MprisController.hasShuffle) {
                            MprisController.setShuffle(false);
                            MprisController.setLoopState(MprisLoopState.Playlist);
                        } else if (MprisController.loopState === MprisLoopState.Playlist) {
                            MprisController.setLoopState(MprisLoopState.Track);
                        } else if (MprisController.loopState === MprisLoopState.Track) {
                            MprisController.setLoopState(MprisLoopState.None);
                        } else {
                            MprisController.setShuffle(true);
                        }
                        modeScaleTimer.restart();
                    }
                }
                Timer {
                    id: modeScaleTimer
                    interval: 100
                    onTriggered: modeBtn.scale = 1.0
                }
            }

            Text {
                id: playerIcon
                text: compactPlayer.getPlayerIcon(compactPlayer.player)
                textFormat: Text.RichText
                color: playerIconHover.hovered ? ((hasArtwork || wallpaperPath !== "") ? Styling.srItem("overprimary") : Styling.srItem("overprimary")) : Colors.overBackground
                font.pixelSize: 20
                font.family: Icons.font
                verticalAlignment: Text.AlignVCenter
                visible: compactPlayer.notchHovered
                Layout.preferredWidth: (compactPlayer.player !== null && compactPlayer.notchHovered) ? implicitWidth : 0
                Layout.rightMargin: (compactPlayer.player !== null && compactPlayer.notchHovered) ? 4 : 0
                Behavior on Layout.preferredWidth {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }
                Behavior on Layout.rightMargin {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }
                Behavior on color {
                    enabled: Config.animDuration > 0
                    ColorAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }
                HoverHandler {
                    id: playerIconHover
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            MprisController.cyclePlayer(1);
                        } else if (mouse.button === Qt.RightButton) {
                            playerPopup.toggle();
                        }
                    }
                }
            }
        }
    }

    BarPopup {
        id: playerPopup
        anchorItem: playerIcon
        bar: ({
            position: Config.bar?.position ?? "top"
        })

        contentWidth: 250
        contentHeight: playersColumn.implicitHeight + playerPopup.popupPadding * 2

        ColumnLayout {
            id: playersColumn
            anchors.fill: parent
            spacing: 4

            Repeater {
                model: MprisController.filteredPlayers
                delegate: StyledRect {
                    id: playerItem
                    required property var modelData
                    required property int index

                    readonly property bool isSelected: compactPlayer.player === modelData
                    readonly property bool isFirst: index === 0
                    readonly property bool isLast: index === MprisController.filteredPlayers.length - 1

                    readonly property real defaultRadius: Styling.radius(4)
                    readonly property real selectedRadius: defaultRadius / 2

                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    variant: isSelected ? "primary" : (hoverHandler.hovered ? "focus" : "common")
                    enableShadow: false

                    topLeftRadius: isSelected ? (isFirst ? defaultRadius : selectedRadius) : defaultRadius
                    topRightRadius: isSelected ? (isFirst ? defaultRadius : selectedRadius) : defaultRadius
                    bottomLeftRadius: isSelected ? (isLast ? defaultRadius : selectedRadius) : defaultRadius
                    bottomRightRadius: isSelected ? (isLast ? defaultRadius : selectedRadius) : defaultRadius

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        Text {
                            text: compactPlayer.getPlayerIcon(playerItem.modelData)
                            font.family: Icons.font
                            font.pixelSize: 16
                            color: playerItem.item
                        }

                        Text {
                            text: playerItem.modelData.trackTitle || playerItem.modelData.identity || "Unknown Player"
                            font.family: Styling.defaultFont
                            font.pixelSize: Styling.fontSize(0)
                            color: playerItem.item
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    HoverHandler {
                        id: hoverHandler
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            MprisController.setActivePlayer(playerItem.modelData);
                        }
                    }
                }
            }
        }
    }
}
