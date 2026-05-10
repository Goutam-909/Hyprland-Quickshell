import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.modules.theme
import qs.modules.services
import qs.modules.components
import qs.config
import qs.modules.globals

Item {
    id: root

    // -----------------------------------------------------------------------
    // Sizing — wider to accommodate side-by-side layout
    // -----------------------------------------------------------------------
    implicitWidth: 460
    implicitHeight: mainRow.implicitHeight + 24

    Behavior on implicitWidth {
        enabled: Config.animDuration > 0
        NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
    }
    Behavior on implicitHeight {
        enabled: Config.animDuration > 0
        NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
    }

    // -----------------------------------------------------------------------
    // State / helpers
    // -----------------------------------------------------------------------
    readonly property var activePlayer: MprisController.activePlayer

    property bool isPlaying: activePlayer?.playbackState === MprisPlaybackState.Playing ?? false
    property real position: activePlayer?.position ?? 0.0
    property real length: activePlayer?.length ?? 1.0
    property bool hasArtwork: (activePlayer?.trackArtUrl ?? "") !== ""

    property string wallpaperPath: {
        if (!GlobalStates.wallpaperManager) return "";
        let path = GlobalStates.wallpaperManager.currentWallpaper;
        let frame = GlobalStates.wallpaperManager.getLockscreenFramePath(path);
        return frame ? "file://" + frame : "";
    }

    // Position timer
    Timer {
        running: root.isPlaying && root.visible
        interval: 1000
        repeat: true
        onTriggered: {
            if (!positionSlider.isDragging) {
                positionSlider.value = root.length > 0
                ? Math.min(1.0, root.position / root.length)
                : 0;
            }
            root.activePlayer?.positionChanged();
        }
    }

    Connections {
        target: root.activePlayer
        function onPositionChanged() {
            if (!positionSlider.isDragging && root.activePlayer) {
                positionSlider.value = root.length > 0
                ? Math.min(1.0, root.position / root.length)
                : 0;
            }
        }
    }

    // Format seconds → mm:ss
    function formatTime(seconds) {
        if (!seconds || seconds <= 0) return "0:00";
        const s = Math.floor(seconds);
        const m = Math.floor(s / 60);
        const sec = s % 60;
        return m + ":" + (sec < 10 ? "0" : "") + sec;
    }

    function getPlayerIcon(player) {
        if (!player) return Icons.player;
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

    // -----------------------------------------------------------------------
    // Background artwork (blurred, full card)
    // -----------------------------------------------------------------------
    ClippingRectangle {
        anchors.fill: parent
        radius: Styling.radius(4)
        color: "transparent"

        Image {
            id: bgArt
            mipmap: true
            anchors.fill: parent
            source: hasArtwork ? root.activePlayer.trackArtUrl : root.wallpaperPath
            sourceSize: Qt.size(128, 128)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
        }

        MultiEffect {
            anchors.fill: bgArt
            source: bgArt
            blurEnabled: hasArtwork || root.wallpaperPath !== ""
            blurMax: 32
            blur: 0.8
            autoPaddingEnabled: false
            opacity: (hasArtwork || root.wallpaperPath !== "") ? 1.0 : 0.0
            Behavior on opacity {
                enabled: Config.animDuration > 0
                NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutQuart }
            }
        }

        StyledRect {
            anchors.fill: parent
            variant: "internalbg"
            opacity: (hasArtwork || root.wallpaperPath !== "") ? 0.55 : 0.0
            radius: Styling.radius(4)
            Behavior on opacity {
                enabled: Config.animDuration > 0
                NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutQuart }
            }
        }

        // ── Cava wave visualizer ─────────────────────────────────────────────
        Canvas {
            id: cavaCanvas
            anchors.fill: parent
            anchors.topMargin: parent.height * 0.35

            property list<var> smoothPoints: []
            property int smoothing: 1

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var points = Cava.values
                var n = points.length
                if (n < 2) return

                    smoothPoints = []
                    for (var i = 0; i < n; ++i) {
                        var sum = 0, count = 0
                        for (var j = -smoothing; j <= smoothing; ++j) {
                            var idx = Math.max(0, Math.min(n - 1, i + j))
                            sum += (root.isPlaying ? points[idx] : 0)
                            count++
                        }
                        smoothPoints.push(sum / count)
                    }

                    var h = height, w = width
                    ctx.beginPath()
                    ctx.moveTo(0, h)
                    for (var i = 0; i < n; ++i) {
                        var x = i * w / (n - 1)
                        var y = h - (smoothPoints[i] / 100) * h
                        ctx.lineTo(x, y)
                    }
                    ctx.lineTo(w, h)
                    ctx.closePath()

                    ctx.fillStyle = Qt.rgba(
                        Colors.primary.r,
                        Colors.primary.g,
                        Colors.primary.b,
                        0.18
                    )
                    ctx.fill()
            }

            Connections {
                target: Cava
                function onValuesChanged() {
                    if (root.visible) cavaCanvas.requestPaint()
                }
            }

            Connections {
                target: root
                function onIsPlayingChanged() { cavaCanvas.requestPaint() }
            }

            layer.enabled: true
            layer.effect: MultiEffect {
                source: cavaCanvas
                blurEnabled: true
                blurMax: 4
                blur: 0.4
                autoPaddingEnabled: false
            }
        }
    }

    // -----------------------------------------------------------------------
    // Main content — horizontal split: album art LEFT | info+controls RIGHT
    // -----------------------------------------------------------------------
    RowLayout {
        id: mainRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 12
        spacing: 14

        // ── LEFT: Album art, full height ────────────────────────────────────
        ClippingRectangle {
            id: artworkBox
            Layout.preferredWidth: 160
            Layout.fillHeight: true
            // Minimum height so card doesn't collapse with no content
            Layout.minimumHeight: 160
            radius: root.isPlaying ? Styling.radius(-6) : Styling.radius(-2)
            color: "transparent"
            layer.enabled: true
            layer.effect: BgShadow {}

            Behavior on radius {
                enabled: Config.animDuration > 0
                NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
            }

            Image {
                id: artImg
                mipmap: true
                anchors.fill: parent
                source: hasArtwork ? root.activePlayer.trackArtUrl : root.wallpaperPath
                sourceSize: Qt.size(256, 256)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: artImg
                blurEnabled: false
                opacity: (hasArtwork || root.wallpaperPath !== "") ? 1.0 : 0.0
                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutQuart }
                }
            }

            // Placeholder icon when no art
            Text {
                anchors.centerIn: parent
                text: Icons.player
                textFormat: Text.RichText
                font.family: Icons.font
                font.pixelSize: 40
                color: Colors.overBackground
                opacity: (hasArtwork || root.wallpaperPath !== "") ? 0.0 : 0.4
                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutQuart }
                }
            }

            // Spinning vinyl indicator overlay when playing
            Rectangle {
                anchors.centerIn: parent
                width: 14; height: 14
                radius: 7
                color: Colors.primary
                opacity: root.isPlaying ? 0.9 : 0.0
                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutQuart }
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 5; height: 5
                    radius: 2.5
                    color: Colors.background
                }
            }
        }

        // ── RIGHT: Track info + progress + controls ──────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            // Track title + artist + album + source
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    id: trackTitle
                    Layout.fillWidth: true
                    text: root.activePlayer?.trackTitle || "No media playing"
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(2)
                    font.bold: true
                    color: Colors.overBackground
                    elide: Text.ElideRight
                    layer.enabled: true
                    layer.effect: BgShadow {}
                }

                Text {
                    id: artistText
                    Layout.fillWidth: true
                    text: root.activePlayer?.trackArtist || ""
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(0)
                    color: Colors.outline
                    elide: Text.ElideRight
                    visible: text !== ""
                    layer.enabled: true
                    layer.effect: BgShadow {}
                }

                Text {
                    id: albumText
                    Layout.fillWidth: true
                    text: root.activePlayer?.trackAlbum || ""
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-1)
                    color: Colors.outline
                    elide: Text.ElideRight
                    visible: text !== ""
                    opacity: 0.7
                    layer.enabled: true
                    layer.effect: BgShadow {}
                }

                // Player source row
                RowLayout {
                    spacing: 4
                    visible: root.activePlayer !== null

                    Text {
                        text: root.getPlayerIcon(root.activePlayer)
                        textFormat: Text.RichText
                        font.family: Icons.font
                        font.pixelSize: 14
                        color: Colors.outline
                    }
                    Text {
                        text: root.activePlayer?.identity || ""
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-1)
                        color: Colors.outline
                        elide: Text.ElideRight
                    }
                }
            }

            // Spacer — pushes progress + controls to the bottom
            Item { Layout.fillHeight: true }

            // ── Progress slider + timestamps ────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: root.activePlayer !== null

                PositionSlider {
                    id: positionSlider
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    player: root.activePlayer
                    hasArtwork: root.hasArtwork || root.wallpaperPath !== ""
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: root.formatTime(root.position)
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-2)
                        color: Colors.outline
                        layer.enabled: true
                        layer.effect: BgShadow {}
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.formatTime(root.length)
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-2)
                        color: Colors.outline
                        layer.enabled: true
                        layer.effect: BgShadow {}
                    }
                }
            }

            // ── Playback controls ───────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Shuffle / Repeat mode toggle
                Text {
                    id: modeBtn
                    text: {
                        if (MprisController.hasShuffle)           return Icons.shuffle;
                        switch (MprisController.loopState) {
                            case MprisLoopState.Track:            return Icons.repeatOnce;
                            case MprisLoopState.Playlist:         return Icons.repeat;
                            default:                              return Icons.shuffle;
                        }
                    }
                    textFormat: Text.RichText
                    font.family: Icons.font
                    font.pixelSize: 18
                    color: modeBtnHover.hovered ? Styling.srItem("overprimary") : Colors.outline
                    opacity: (MprisController.shuffleSupported || MprisController.loopSupported) ? 1.0 : 0.3
                    scale: 1.0
                    layer.enabled: true
                    layer.effect: BgShadow {}

                    Behavior on color {
                        enabled: Config.animDuration > 0
                        ColorAnimation { duration: Config.animDuration; easing.type: Easing.OutQuart }
                    }
                    Behavior on scale {
                        enabled: Config.animDuration > 0
                        NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
                    }

                    HoverHandler { id: modeBtnHover; enabled: MprisController.shuffleSupported || MprisController.loopSupported }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: MprisController.shuffleSupported || MprisController.loopSupported
                        onClicked: {
                            modeBtn.scale = 1.2;
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
                            modeBtnScaleTimer.restart();
                        }
                    }
                    Timer { id: modeBtnScaleTimer; interval: 100; onTriggered: modeBtn.scale = 1.0 }
                }

                Item { Layout.fillWidth: true }

                // Previous
                Text {
                    id: prevBtn
                    text: Icons.previous
                    textFormat: Text.RichText
                    font.family: Icons.font
                    font.pixelSize: 22
                    color: prevHover.hovered ? Styling.srItem("overprimary") : Colors.overBackground
                    opacity: (root.activePlayer?.canGoPrevious ?? false) ? 1.0 : 0.3
                    scale: 1.0
                    layer.enabled: true
                    layer.effect: BgShadow {}

                    Behavior on color {
                        enabled: Config.animDuration > 0
                        ColorAnimation { duration: Config.animDuration; easing.type: Easing.OutQuart }
                    }
                    Behavior on scale {
                        enabled: Config.animDuration > 0
                        NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
                    }

                    HoverHandler { id: prevHover; enabled: root.activePlayer?.canGoPrevious ?? false }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.activePlayer?.canGoPrevious ?? false
                        onClicked: {
                            prevBtn.scale = 1.4;
                            root.activePlayer?.previous();
                            prevScaleTimer.restart();
                        }
                    }
                    Timer { id: prevScaleTimer; interval: 100; onTriggered: prevBtn.scale = 1.0 }
                }

                // Play / Pause (large, centred)
                Item {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48

                    StyledRect {
                        anchors.fill: parent
                        radius: Styling.radius(0)
                        variant: "primary"
                        enableShadow: true
                        opacity: (root.activePlayer?.canPause ?? false) ? 1.0 : 0.4
                    }

                    Text {
                        id: playPauseBtn
                        anchors.centerIn: parent
                        text: root.isPlaying ? Icons.pause : Icons.play
                        textFormat: Text.RichText
                        font.family: Icons.font
                        font.pixelSize: 22
                        color: Styling.srItem("overprimary")
                        scale: 1.0
                        layer.enabled: true
                        layer.effect: BgShadow {}

                        Behavior on scale {
                            enabled: Config.animDuration > 0
                            NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: root.activePlayer ? Qt.PointingHandCursor : Qt.ArrowCursor
                            enabled: root.activePlayer?.canPause ?? false
                            onClicked: {
                                playPauseBtn.scale = 1.2;
                                root.activePlayer?.togglePlaying();
                                ppScaleTimer.restart();
                            }
                        }
                        Timer { id: ppScaleTimer; interval: 100; onTriggered: playPauseBtn.scale = 1.0 }
                    }
                }

                // Next
                Text {
                    id: nextBtn
                    text: Icons.next
                    textFormat: Text.RichText
                    font.family: Icons.font
                    font.pixelSize: 22
                    color: nextHover.hovered ? Styling.srItem("overprimary") : Colors.overBackground
                    opacity: (root.activePlayer?.canGoNext ?? false) ? 1.0 : 0.3
                    scale: 1.0
                    layer.enabled: true
                    layer.effect: BgShadow {}

                    Behavior on color {
                        enabled: Config.animDuration > 0
                        ColorAnimation { duration: Config.animDuration; easing.type: Easing.OutQuart }
                    }
                    Behavior on scale {
                        enabled: Config.animDuration > 0
                        NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
                    }

                    HoverHandler { id: nextHover; enabled: root.activePlayer?.canGoNext ?? false }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.activePlayer?.canGoNext ?? false
                        onClicked: {
                            nextBtn.scale = 1.4;
                            root.activePlayer?.next();
                            nextScaleTimer.restart();
                        }
                    }
                    Timer { id: nextScaleTimer; interval: 100; onTriggered: nextBtn.scale = 1.0 }
                }

                Item { Layout.fillWidth: true }

                // Cycle player icon
                Text {
                    id: playerIconBtn
                    text: root.getPlayerIcon(root.activePlayer)
                    textFormat: Text.RichText
                    font.family: Icons.font
                    font.pixelSize: 18
                    color: playerIconHover.hovered ? Styling.srItem("overprimary") : Colors.outline
                    visible: root.activePlayer !== null
                    scale: 1.0
                    layer.enabled: true
                    layer.effect: BgShadow {}

                    Behavior on color {
                        enabled: Config.animDuration > 0
                        ColorAnimation { duration: Config.animDuration; easing.type: Easing.OutQuart }
                    }
                    Behavior on scale {
                        enabled: Config.animDuration > 0
                        NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
                    }

                    HoverHandler { id: playerIconHover }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton) {
                                playerIconBtn.scale = 1.2;
                                MprisController.cyclePlayer(1);
                                piScaleTimer.restart();
                            }
                        }
                    }
                    Timer { id: piScaleTimer; interval: 100; onTriggered: playerIconBtn.scale = 1.0 }
                }
            }

            // ── No-player placeholder ───────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                visible: root.activePlayer === null

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Icons.player
                        textFormat: Text.RichText
                        font.family: Icons.font
                        font.pixelSize: 24
                        color: Colors.outline
                        opacity: 0.5
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No media playing"
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(0)
                        color: Colors.outline
                        opacity: 0.6
                    }
                }
            }
        }
    }

    // Focus when pushed onto StackView
    onVisibleChanged: {
        if (visible) {
            Qt.callLater(() => { forceActiveFocus(); });
        }
        cavaCanvas.requestPaint()
    }

    Component.onCompleted: {
        if (visible) {
            Qt.callLater(() => { forceActiveFocus(); });
        }
    }
}
