
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.models
import qs.services
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Widgets

Item {
    id: root

    property Item wallpaperItem: null

    // Fed by MediaWidget.qml
    property bool hovering: false

    readonly property real computedWidth: cardPadding * 2 + albumContainerSize + cardSpacing + 350
    readonly property real computedHeight: 240

    implicitWidth: root.computedWidth
    implicitHeight: root.computedHeight

    property MprisPlayer player: MprisController.activePlayer

    readonly property bool useDynamicColors: (Config.options.background.widgets.media.expressive.dynamicAlbumColors ?? false) && root.artSource !== ""

    ColorQuantizer {
        id: colorQuantizer
        source: root.artSource
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

    // Your AdaptedMaterialScheme has no colPrimaryContainer/colTertiaryContainer,
    // so colBg uses artDominantColor directly (already blended toward a
    // container-like tone) and the secondary buttons derive from the panel
    // color instead of a nonexistent tertiary container.
    readonly property color colBg: useDynamicColors ? root.artDominantColor : WidgetColorScheme.cardBgColor
    readonly property color colAlbumBg: useDynamicColors ? blendedColors.colSecondaryContainer : WidgetColorScheme.innerShapeColor
    readonly property color colControlsBg: useDynamicColors ? blendedColors.colSecondaryContainer : WidgetColorScheme.pillFillColor
    readonly property color colText: useDynamicColors ? blendedColors.colOnSecondaryContainer : WidgetColorScheme.accentColor
    readonly property color colTimeMain: useDynamicColors ? blendedColors.colOnSecondaryContainer : WidgetColorScheme.accentColor
    readonly property color colTimeSub: useDynamicColors ? ColorUtils.transparentize(blendedColors.colOnSecondaryContainer, 0.4) : ColorUtils.transparentize(WidgetColorScheme.accentColor, 0.4)
    readonly property color colProgressHighlight: useDynamicColors ? blendedColors.colPrimary : WidgetColorScheme.accentColor
    readonly property color colProgressTrack: useDynamicColors ? ColorUtils.transparentize(blendedColors.colOnSecondaryContainer, 0.6) : ColorUtils.transparentize(WidgetColorScheme.textColorOnPillFill, 0.6)
    readonly property color colBtnSecondary: useDynamicColors ? Qt.lighter(blendedColors.colSecondaryContainer, 1.15) : WidgetColorScheme.pillBgColor
    readonly property color colBtnSecondaryHover: useDynamicColors ? ColorUtils.mix(colBtnSecondary, blendedColors.colPrimary, 0.15) : ColorUtils.mix(WidgetColorScheme.pillBgColor, WidgetColorScheme.accentColor, 0.15)
    readonly property color colBtnSecondaryActive: useDynamicColors ? ColorUtils.mix(colBtnSecondary, blendedColors.colPrimary, 0.25) : ColorUtils.mix(WidgetColorScheme.pillBgColor, WidgetColorScheme.accentColor, 0.25)
    readonly property color colBtnPlayBg: useDynamicColors ? blendedColors.colPrimary : WidgetColorScheme.accentColor
    readonly property color colBtnPlayRipple: useDynamicColors ? ColorUtils.mix(blendedColors.colPrimary, blendedColors.colOnPrimary, 0.2) : ColorUtils.mix(WidgetColorScheme.accentColor, WidgetColorScheme.onAccentColor, 0.2)
    readonly property color colBtnPlayIcon: useDynamicColors ? blendedColors.colOnPrimary : WidgetColorScheme.onAccentColor
    readonly property color colBtnIcon: useDynamicColors ? blendedColors.colOnSecondaryContainer : WidgetColorScheme.textColorOnPillTrack
    readonly property color colAlbumBorder: useDynamicColors ? ColorUtils.transparentize(blendedColors.colOnSecondaryContainer, 0.5) : WidgetColorScheme.outlineColor

    readonly property bool rotateAlbumArt: Config.options.background.widgets.media.expressive.rotateAlbumArt ?? true
    readonly property bool showTimeInfo: Config.options.background.widgets.media.expressive.showTimeInfo ?? true
    readonly property bool showArtist: Config.options.background.widgets.media.expressive.showArtist ?? true
    readonly property bool showProgressSlider: Config.options.background.widgets.media.expressive.showProgressSlider ?? true

    onRotateAlbumArtChanged: {
        if (!root.rotateAlbumArt) {
            let current = albumArtItem._rotationAngle;
            let target = Math.round(current / 360) * 360;
            if (target <= current) target += 360;
            resetRotationAnim.from = current;
            resetRotationAnim.to = target;
            resetRotationAnim.start();
        } else {
            resetRotationAnim.stop();
        }
    }

    NumberAnimation {
        id: resetRotationAnim
        target: albumArtItem
        property: "_rotationAngle"
        duration: 600
        easing.type: Easing.OutCubic
        onStopped: albumArtItem._rotationAngle = 0
    }

    readonly property int globalRadius: Appearance.rounding.large
    readonly property int controlsRadius: Appearance.rounding.large
    readonly property int btnRadius: Appearance.rounding.large

    readonly property int cardPadding: 12
    readonly property int cardSpacing: 10
    readonly property int albumContainerSize: 148
    readonly property int albumBorderWidth: 8
    readonly property int centerDotSize: 32
    readonly property int controlsPadding: 16
    readonly property int controlsSpacing: 8
    readonly property int timerSpacing: 6
    readonly property int timerPrimarySize: Appearance.font.pixelSize.huge
    readonly property int timerSecondarySize: Appearance.font.pixelSize.small
    readonly property int btnPlayWidth: 44

    readonly property string trackTitle: player?.trackTitle || Translation.tr("No media")
    readonly property string trackArtist: player?.trackArtist || Translation.tr("Unknown Artist")
    readonly property string artUrl: root.player?.trackArtUrl ?? ""
    readonly property bool isLocalArt: artUrl.startsWith("file://")

    property string artDownloadLocation: Directories.coverArt
    property string artFileName: Qt.md5(artUrl)
    property string artFilePath: `${artDownloadLocation}/${artFileName}`
    property bool artDownloaded: false

    readonly property string artSource: {
        if (!artUrl) return "";
        if (isLocalArt) return artUrl;
        return artDownloaded ? Qt.resolvedUrl(artFilePath) : "";
    }

    onArtFilePathChanged: {
        if (!artUrl || artUrl.length === 0) {
            artDownloaded = false;
            return;
        }
        if (isLocalArt) {
            artDownloaded = true;
            return;
        }
        artDownloader.targetFile = artUrl;
        artDownloader.artFilePath = artFilePath;
        artDownloader.artTempPath = artFilePath + ".tmp";
        artDownloaded = false;
        artDownloader.running = true;
    }

    Process {
        id: artDownloader
        property string targetFile: root.artUrl
        property string artFilePath: root.artFilePath
        property string artTempPath: root.artFilePath + ".tmp"
        command: ["bash", "-c", `[ -f ${artFilePath} ] || (curl -4 -sSL '${targetFile}' -o '${artTempPath}' && mv '${artTempPath}' '${artFilePath}')`]
        onExited: {
            artDownloaded = true;
        }
    }

    Timer {
        running: root.player?.isPlaying ?? false
        interval: 500
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    StyledRectangularShadow {
        id: bgShadow
        target: mainBg
        visible: Config.options.background.widgets.enableShadows ?? true
    }

    Rectangle {
        id: mainBg
        anchors.fill: parent
        anchors.margins: 8
        color: root.colBg
        radius: root.globalRadius
        border.color: WidgetColorScheme.outlineColor
        border.width: 1
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.cardPadding
            spacing: root.cardSpacing

            StyledText {
                Layout.fillWidth: true
                text: root.trackTitle.toUpperCase()
                color: root.colText
                // No bundled LED/dot-matrix font in your repo - monospace
                // gets closest to that "expressive" digital readout feel.
                font.family: Appearance.font.family.monospace
                font.pixelSize: 22
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.bottomMargin: -6
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: root.cardSpacing

                Rectangle {
                    id: albumPill
                    Layout.fillHeight: true
                    Layout.preferredWidth: height
                    Layout.alignment: Qt.AlignVCenter
                    color: root.colAlbumBg
                    radius: root.globalRadius

                    Item {
                        id: albumArtItem
                        anchors.centerIn: parent
                        width: parent.height - 20
                        height: parent.height - 20
                        clip: true

                        property real _rotationAngle: 0
                        rotation: _rotationAngle

                        Timer {
                            id: rotationTimer
                            running: (root.player?.isPlaying ?? false) && root.rotateAlbumArt
                            interval: 16
                            repeat: true
                            onTriggered: albumArtItem._rotationAngle = (albumArtItem._rotationAngle + 0.6) % 360
                        }

                        Image {
                            id: albumArtImage
                            anchors.fill: parent
                            anchors.margins: 1
                            source: root.artSource
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                            antialiasing: true
                            sourceSize.width: width
                            sourceSize.height: height

                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: albumArtImage.width
                                    height: albumArtImage.height
                                    radius: width / 2
                                }
                            }
                        }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            visible: albumArtImage.status !== Image.Ready
                            iconSize: 48
                            text: "music_note"
                            color: WidgetColorScheme.subtextColorOnBg
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            radius: width / 2
                            border.color: root.colAlbumBorder
                            border.width: root.albumBorderWidth
                            z: 2
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: root.centerDotSize
                            height: root.centerDotSize
                            radius: width / 2
                            color: WidgetColorScheme.highlightCircleColor
                            z: 3
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignVCenter
                    color: root.colControlsBg
                    radius: root.controlsRadius
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.topMargin: root.controlsPadding
                        anchors.leftMargin: root.controlsPadding
                        anchors.rightMargin: root.controlsPadding
                        anchors.bottomMargin: root.controlsPadding
                        spacing: root.controlsSpacing

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: root.timerSpacing
                            Layout.alignment: Qt.AlignTop

                            Text {
                                visible: root.showTimeInfo
                                text: StringUtils.friendlyTimeForSeconds(root.player?.position ?? 0)
                                color: root.colTimeMain
                                font.pixelSize: root.timerPrimarySize
                                font.weight: Font.ExtraBold
                                Layout.alignment: Qt.AlignTop
                            }

                            Text {
                                visible: root.showTimeInfo
                                text: StringUtils.friendlyTimeForSeconds(root.player?.length ?? 0)
                                color: root.colTimeSub
                                font.pixelSize: root.timerSecondarySize
                                font.weight: Font.Regular
                                Layout.alignment: Qt.AlignTop
                                Layout.topMargin: 4
                            }

                            StyledText {
                                visible: root.showArtist
                                text: root.trackArtist
                                color: root.colTimeSub
                                font.pixelSize: root.timerSecondarySize
                                font.weight: Font.Regular
                                Layout.maximumWidth: 150
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignLeft
                                Layout.alignment: Qt.AlignTop
                                Layout.topMargin: 4
                            }

                            Item {
                                Layout.fillWidth: true
                            }
                        }

                        Item {
                            visible: root.showProgressSlider
                            Layout.fillWidth: true
                            implicitHeight: Math.max(sliderLoader.implicitHeight, progressLoader.implicitHeight)

                            Loader {
                                id: sliderLoader
                                anchors.fill: parent
                                active: root.player?.canSeek ?? false
                                sourceComponent: StyledSlider {
                                    configuration: StyledSlider.Configuration.Wavy
                                    highlightColor: root.colProgressHighlight
                                    trackColor: root.colProgressTrack
                                    handleColor: root.colProgressHighlight
                                    value: (root.player?.length ?? 0) > 0 ? (root.player?.position ?? 0) / root.player.length : 0
                                    onMoved: root.player.position = value * root.player.length
                                }
                            }

                            Loader {
                                id: progressLoader
                                anchors {
                                    verticalCenter: parent.verticalCenter
                                    left: parent.left
                                    right: parent.right
                                }
                                active: !(root.player?.canSeek ?? false)
                                sourceComponent: StyledProgressBar {
                                    wavy: root.player?.isPlaying ?? false
                                    highlightColor: root.colProgressHighlight
                                    trackColor: root.colProgressTrack
                                    value: (root.player?.length ?? 0) > 0 ? (root.player?.position ?? 0) / root.player.length : 0
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            spacing: root.controlsSpacing

                            RippleButton {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                Layout.preferredHeight: root.btnPlayWidth
                                Layout.alignment: Qt.AlignVCenter
                                colBackground: root.colBtnSecondary
                                colBackgroundHover: root.colBtnSecondaryHover
                                colRipple: root.colBtnSecondaryActive
                                buttonRadius: root.btnRadius
                                contentItem: MaterialSymbol {
                                    text: "skip_previous"
                                    color: root.colBtnIcon
                                    fill: 1
                                    iconSize: Appearance.font.pixelSize.huge
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                onClicked: root.player?.previous()
                            }

                            RippleButton {
                                implicitWidth: root.btnPlayWidth
                                implicitHeight: root.btnPlayWidth
                                colBackground: root.colBtnPlayBg
                                colRipple: root.colBtnPlayRipple
                                buttonRadius: root.player?.isPlaying ? Appearance.rounding.small : Appearance.rounding.full

                                Behavior on buttonRadius {
                                    NumberAnimation {
                                        duration: 250
                                        easing.type: Easing.OutQuint
                                    }
                                }

                                contentItem: MaterialSymbol {
                                    text: root.player?.isPlaying ? "pause" : "play_arrow"
                                    color: root.colBtnPlayIcon
                                    fill: 1
                                    iconSize: Appearance.font.pixelSize.huge
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                onClicked: root.player?.togglePlaying()
                            }

                            RippleButton {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                Layout.preferredHeight: root.btnPlayWidth
                                Layout.alignment: Qt.AlignVCenter
                                colBackground: root.colBtnSecondary
                                colBackgroundHover: root.colBtnSecondaryHover
                                colRipple: root.colBtnSecondaryActive
                                buttonRadius: root.btnRadius
                                contentItem: MaterialSymbol {
                                    text: "skip_next"
                                    color: root.colBtnIcon
                                    fill: 1
                                    iconSize: Appearance.font.pixelSize.huge
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                onClicked: root.player?.next()
                            }
                        }
                    }
                }
            }
        }
    }
}



