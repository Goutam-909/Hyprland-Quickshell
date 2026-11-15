
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.models

Item {
    id: root

    property Item wallpaperItem: null

    // Fed by MediaWidget.qml
    property bool hovering: false

    readonly property real contentScale: (Config.options.background.widgets.media.cd.widgetSize ?? 100) / 100.0
    implicitWidth: 240 * contentScale
    implicitHeight: 240 * contentScale

    readonly property MprisPlayer player: MprisController.activePlayer
    readonly property bool isPlaying: root.player?.isPlaying ?? false
    readonly property string rawArtUrl: root.player?.trackArtUrl ?? ""

    readonly property string songTitle: root.player?.trackTitle || Translation.tr("Wonderwall")
    readonly property string artistName: root.player?.trackArtist || Translation.tr("Oasis")

    readonly property real position: root.player ? (root.player.position ?? 0) : 163
    readonly property real length: root.player ? (root.player.length ?? 0) : 258

    // ── Dynamic album colors ──
    readonly property bool useDynamicColors: (Config.options.background.widgets.media.cd.dynamicAlbumColors ?? false) && root.effectiveArtSource !== ""

    ColorQuantizer {
        id: colorQuantizer
        source: root.resolvedArtPath
        depth: 0
        rescaleSize: 1
    }

    readonly property color artDominantColor: {
        if (!root.useDynamicColors) return Appearance.colors.colPrimary;
        let raw = colorQuantizer?.colors[0] ?? Appearance.colors.colPrimary;
        let mixed = ColorUtils.mix(raw, Appearance.colors.colPrimaryContainer, 0.8);
        return mixed || Appearance.m3colors.m3secondaryContainer;
    }

    property QtObject blendedColors: AdaptedMaterialScheme {
        color: root.artDominantColor
    }

    // Your AdaptedMaterialScheme has no *Container/onContainer variants, so
    // the card background uses artDominantColor directly (already blended
    // toward colPrimaryContainer) and text color is derived from its
    // lightness instead of a matching "on" color.
    readonly property color cardBgColor: useDynamicColors ? root.artDominantColor : WidgetColorScheme.cardBgColor
    readonly property bool cardBgIsDark: root.cardBgColor.hslLightness < 0.5
    readonly property color textColorOnBg: useDynamicColors ? ColorUtils.colorWithLightness(Appearance.colors.colOnSurface, cardBgIsDark ? 0.9 : 0.1) : WidgetColorScheme.textColorOnBg
    readonly property color subtextColorOnBg: useDynamicColors ? ColorUtils.transparentize(textColorOnBg, 0.6) : WidgetColorScheme.subtextColorOnBg
    readonly property color accentColor: useDynamicColors ? blendedColors.colPrimary : WidgetColorScheme.accentColor

    function formatTime(seconds) {
        if (isNaN(seconds) || seconds < 0) return "0:00";
        let m = Math.floor(seconds / 60);
        let s = Math.floor(seconds % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    Timer {
        running: root.isPlaying
        interval: 1000
        repeat: true
        onTriggered: {
            if (root.player) root.player.positionChanged();
        }
    }

    // Direct resolution of artSource (local vs http/https)
    readonly property bool isLocalArt: root.rawArtUrl.startsWith("file://") || root.rawArtUrl.startsWith("/")
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: Qt.md5(root.rawArtUrl)
    property string artFilePath: `${artDownloadLocation}/${artFileName}`
    property bool downloaded: false

    readonly property string effectiveArtSource: {
        if (!root.rawArtUrl || root.rawArtUrl === "") return "";
        if (root.isLocalArt) return FileUtils.trimFileProtocol(root.rawArtUrl);
        return root.downloaded ? root.artFilePath : "";
    }

    readonly property string resolvedArtPath: root.effectiveArtSource !== "" ? Qt.resolvedUrl(root.effectiveArtSource) : ""

    onRawArtUrlChanged: {
        if (rawArtUrl && rawArtUrl !== "" && !isLocalArt) {
            coverArtDownloader.targetFile = rawArtUrl;
            coverArtDownloader.artFilePath = artFilePath;
            coverArtDownloader.artTempPath = artFilePath + ".tmp";
            downloaded = false;
            coverArtDownloader.running = true;
        }
    }

    Process {
        id: coverArtDownloader
        property string targetFile: root.rawArtUrl
        property string artFilePath: root.artFilePath
        property string artTempPath: root.artFilePath + ".tmp"
        command: ["bash", "-c", `[ -f ${artFilePath} ] || (curl -4 -sSL '${targetFile}' -o '${artTempPath}' && mv '${artTempPath}' '${artFilePath}')`]
        onExited: (exitCode, exitStatus) => {
            root.downloaded = true;
        }
    }

    StyledRectangularShadow {
        id: bgShadow
        target: bgRect
        visible: Config.options.background.widgets.enableShadows ?? true
    }

    // Main Card background
    Rectangle {
        id: bgRect
        anchors.fill: parent
        color: root.cardBgColor
        radius: Appearance.rounding.windowRounding
        clip: true

        layer.enabled: Config.options.background.widgets.media.cd.enableInnerShadow ?? true
        layer.effect: InnerShadow {
            color: Qt.rgba(0, 0, 0, 0.15)
            radius: 8.0
            samples: 16
            horizontalOffset: 0
            verticalOffset: 1
            spread: 0.0
        }

        Item {
            anchors.fill: parent

            // 1. Album Art Circle Container (Anchored to top, height: 100)
            Item {
                id: topCircleContainer
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: 176
                height: 100
                clip: true

                // Drop shadow for album art
                DropShadow {
                    anchors.fill: circleMaskArea
                    source: circleMaskArea
                    radius: 20
                    samples: 24
                    color: Qt.rgba(0, 0, 0, 0.18)
                    verticalOffset: 4
                    horizontalOffset: 0
                }

                Item {
                    id: circleMaskArea
                    width: 176
                    height: 176
                    anchors.top: parent.top
                    anchors.topMargin: -86 // Exposes bottom 100px arc inside topCircleContainer
                    anchors.horizontalCenter: parent.horizontalCenter

                    // Fallback: plain tinted circle + note icon when there's no art,
                    // instead of a hardcoded asset path that may not exist in your repo.
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Appearance.colors.colPrimaryContainer
                        visible: root.resolvedArtPath === ""

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "music_note"
                            iconSize: 48
                            fill: 1
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                    }

                    Image {
                        id: coverArtImage
                        anchors.fill: parent
                        source: root.resolvedArtPath
                        fillMode: Image.PreserveAspectCrop
                        visible: false
                    }

                    Rectangle {
                        id: maskCircle
                        anchors.fill: parent
                        radius: width / 2
                        color: "black"
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: coverArtImage
                        maskSource: maskCircle
                        visible: root.resolvedArtPath !== ""
                    }
                }
            }

            // 2. Bottom Content Layout (Anchored strictly to topCircleContainer.bottom)
            ColumnLayout {
                anchors.top: topCircleContainer.bottom
                anchors.topMargin: 4
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 3

                // Author Name (Reduced opacity subtext)
                StyledText {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    text: root.artistName
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.family: Appearance.font.family.title
                    color: root.subtextColorOnBg
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                // Song Name
                StyledText {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    text: root.songTitle
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.family: Appearance.font.family.title
                    font.weight: Font.DemiBold
                    color: root.textColorOnBg
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Item { Layout.preferredHeight: 1 }

                // Line Progress Slider
                Item {
                    id: progressTrack
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 60
                    implicitHeight: 3

                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(root.subtextColorOnBg.r, root.subtextColorOnBg.g, root.subtextColorOnBg.b, 0.2)
                        radius: 1.5
                    }

                    Rectangle {
                        height: parent.height
                        width: parent.width * (root.length > 0 ? Math.min(1.0, Math.max(0.0, root.position / root.length)) : 0.63)
                        color: root.accentColor
                        radius: 1.5
                    }
                }

                Item { Layout.preferredHeight: 1 }

                // Time Display: 2:43 / 4:18 (Current time bold, Total time reduced opacity)
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4

                    StyledText {
                        text: root.formatTime(root.position)
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Bold
                        color: root.textColorOnBg
                    }

                    StyledText {
                        text: "/"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: root.subtextColorOnBg
                    }

                    StyledText {
                        text: root.formatTime(root.length)
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: root.subtextColorOnBg
                    }
                }
            }
        }
    }
}



