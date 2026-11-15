
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs
import qs.services
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas

Item {
    id: root

    property Item wallpaperItem: null

    // Fed by MediaWidget.qml, replaces the old AbstractBackgroundWidget hover tracking
    property bool hovering: false

    readonly property bool useAlbumColors: Config.options.background.widgets.media.useAlbumColors
    readonly property bool useDynamicColors: root.useAlbumColors && root.currentPlayer != null
    readonly property bool showPreviousToggle: Config.options.background.widgets.media.showPreviousToggle
    readonly property bool hideAllButtons: Config.options.background.widgets.media.hideAllButtons
    readonly property bool showRestButtons: hideAllButtons ? hovering : true

    readonly property var playerList: MprisController.players
    // Some browser MPRIS bridges (e.g. Brave) register a companion "shadow"
    // player alongside the real one — same app, but with no track metadata
    // at all. Filter those out so switching players never cycles through
    // an empty duplicate of the one that actually has content.
    readonly property var filteredPlayerList: playerList.filter(player =>
    player != null && ((player.trackTitle ?? "") !== "" || (player.trackAlbum ?? "") !== "")
    )

    // Manual override set by the "next player" (360°) button; cleared once it
    // matches (or drops out of) the auto-selected player so we fall back
    // to the same active-player logic Media.qml uses.
    property MprisPlayer manualPlayerOverride: null

    // Mirrors Media.qml's activePlayer logic: respects the configured
    // preferred player, falling back to MprisController.activePlayer.
    readonly property MprisPlayer basePlayer: {
        const preferred = Config.options.bar.media.preferredPlayer.trim().toLowerCase()
        if (preferred.length === 0) return MprisController.activePlayer
            const _ = MprisController.players.count
            for (const p of MprisController.players) {
                if ((p.identity ?? "").toLowerCase().includes(preferred) ||
                    (p.desktopEntry ?? "").toLowerCase().includes(preferred))
                    return p
            }
            return MprisController.activePlayer
    }

    readonly property MprisPlayer currentPlayer: root.manualPlayerOverride ?? root.basePlayer

    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(currentPlayer?.trackTitle) || Translation.tr("No media")
    property string trackTitle:  currentPlayer?.trackTitle  ?? ""
    property string trackArtist: currentPlayer?.trackArtist ?? ""
    property bool   hasTrack:    trackTitle.length > 0
    property var artUrl: root.currentPlayer?.trackArtUrl ?? ""

    // Clear the manual override if that player disappears, or once it's
    // back in sync with the auto-selected player, so cycling never gets
    // permanently "stuck" out of step with Media.qml's selection.
    onFilteredPlayerListChanged: {
        if (root.manualPlayerOverride && !root.filteredPlayerList.includes(root.manualPlayerOverride))
            root.manualPlayerOverride = null;
    }
    onBasePlayerChanged: {
        if (root.manualPlayerOverride === root.basePlayer)
            root.manualPlayerOverride = null;
    }

    property real widgetSize: 240
    property real controlsSize: 55
    property real buttonIconSize: 30

    property color artDominantColor: ColorUtils.mix((colorQuantizer?.colors[0] ?? Appearance.colors.colPrimary), Appearance.colors.colPrimaryContainer, 0.8) || Appearance.m3colors.m3secondaryContainer
    property QtObject blendedColors: AdaptedMaterialScheme {
        color: artDominantColor
    }
    property var dynamicColors: {
        return {
            colPrimary: root.useDynamicColors ? (blendedColors.colPrimary ?? Appearance.colors.colPrimary) : Appearance.colors.colPrimary,
            colPrimaryBackground: root.useDynamicColors ? (blendedColors.colPrimaryContainer ?? Appearance.colors.colPrimaryContainer) : Appearance.colors.colPrimaryContainer,
            colPrimaryBackgroundHover: root.useDynamicColors ? (blendedColors.colPrimaryContainerHover ?? Appearance.colors.colPrimaryContainerHover) : Appearance.colors.colPrimaryContainerHover,
            colPrimaryRipple: root.useDynamicColors ? (blendedColors.colPrimaryContainerActive ?? Appearance.colors.colPrimaryContainerActive) : Appearance.colors.colPrimaryContainerActive,
            colSecondary: root.useDynamicColors ? (blendedColors.colSecondary ?? Appearance.colors.colSecondary) : Appearance.colors.colSecondary,
            colSecondaryBackground: root.useDynamicColors ? (blendedColors.colSecondaryContainer ?? Appearance.colors.colSecondaryContainer) : Appearance.colors.colSecondaryContainer,
            colSecondaryBackgroundHover: root.useDynamicColors ? (blendedColors.colSecondaryContainerHover ?? Appearance.colors.colSecondaryContainerHover) : Appearance.colors.colSecondaryContainerHover,
            colSecondaryRipple: root.useDynamicColors ? (blendedColors.colSecondaryContainerActive ?? Appearance.colors.colSecondaryContainerActive) : Appearance.colors.colSecondaryContainerActive,
            colTertiary: root.useDynamicColors ? (blendedColors.colTertiary ?? Appearance.colors.colTertiary) : Appearance.colors.colTertiary,
            colTertiaryBackground: root.useDynamicColors ? (blendedColors.colTertiaryContainer ?? Appearance.colors.colTertiaryContainer) : Appearance.colors.colTertiaryContainer,
            colTertiaryBackgroundHover: root.useDynamicColors ? (blendedColors.colTertiaryContainerHover ?? Appearance.colors.colTertiaryContainerHover) : Appearance.colors.colTertiaryContainerHover,
            colTertiaryRipple: root.useDynamicColors ? (blendedColors.colTertiaryContainerActive ?? Appearance.colors.colTertiaryContainerActive) : Appearance.colors.colTertiaryContainerActive
        };
    }

    property string displayedArtFilePath: root.artUrl

    property list<real> visualizerPoints: Config.options.background.widgets.media.visualizer.enable ? CavaService.visualizerPoints : []

    function mapShape(shapeName) {
        switch (shapeName) {
            case "Circle":        return MaterialShape.Shape.Circle
            case "Square":        return MaterialShape.Shape.Square
            case "Slanted":       return MaterialShape.Shape.Slanted
            case "Arch":          return MaterialShape.Shape.Arch
            case "Fan":           return MaterialShape.Shape.Fan
            case "Arrow":         return MaterialShape.Shape.Arrow
            case "SemiCircle":    return MaterialShape.Shape.SemiCircle
            case "Oval":          return MaterialShape.Shape.Oval
            case "Pill":          return MaterialShape.Shape.Pill
            case "Triangle":      return MaterialShape.Shape.Triangle
            case "Diamond":       return MaterialShape.Shape.Diamond
            case "ClamShell":     return MaterialShape.Shape.ClamShell
            case "Pentagon":      return MaterialShape.Shape.Pentagon
            case "Gem":           return MaterialShape.Shape.Gem
            case "Sunny":         return MaterialShape.Shape.Sunny
            case "VerySunny":     return MaterialShape.Shape.VerySunny
            case "Cookie4Sided":  return MaterialShape.Shape.Cookie4Sided
            case "Cookie6Sided":  return MaterialShape.Shape.Cookie6Sided
            case "Cookie7Sided":  return MaterialShape.Shape.Cookie7Sided
            case "Cookie9Sided":  return MaterialShape.Shape.Cookie9Sided
            case "Cookie12Sided": return MaterialShape.Shape.Cookie12Sided
            case "Ghostish":      return MaterialShape.Shape.Ghostish
            case "Clover4Leaf":   return MaterialShape.Shape.Clover4Leaf
            case "Clover8Leaf":   return MaterialShape.Shape.Clover8Leaf
            case "Burst":         return MaterialShape.Shape.Burst
            case "SoftBurst":     return MaterialShape.Shape.SoftBurst
            case "Boom":          return MaterialShape.Shape.Boom
            case "SoftBoom":      return MaterialShape.Shape.SoftBoom
            case "Flower":        return MaterialShape.Shape.Flower
            case "Puffy":         return MaterialShape.Shape.Puffy
            case "PuffyDiamond":  return MaterialShape.Shape.PuffyDiamond
            case "PixelCircle":   return MaterialShape.Shape.PixelCircle
            case "PixelTriangle": return MaterialShape.Shape.PixelTriangle
            case "Bun":           return MaterialShape.Shape.Bun
            case "Heart":         return MaterialShape.Shape.Heart
            default:              return MaterialShape.Shape.Cookie4Sided
        }
    }

    function nextPlayer() {
        // Cycle over filteredPlayerList (real players only) rather than the
        // raw playerList, so metadata-less duplicate/shadow entries from
        // browser MPRIS bridges never show up as a separate "player."
        const list = root.filteredPlayerList;
        if (list.length === 0) return;
        const idx = list.indexOf(root.currentPlayer);
        const next = list[(idx + 1) % list.length];
        // If cycling lands back on the auto-selected player, drop the
        // override so we defer to Media.qml's active-player logic again.
        root.manualPlayerOverride = (next === root.basePlayer) ? null : next;
    }

    ColorQuantizer {
        id: colorQuantizer
        source: root.displayedArtFilePath
        depth: 0 // 2^0 = 1 color
        rescaleSize: 1 // Rescale to 1x1 pixel for faster processing
    }

    implicitWidth: root.widgetSize
    implicitHeight: root.widgetSize

    RectangularGlow {
        id: blurredArtGlow
        anchors.centerIn: parent
        width: root.widgetSize
        height: root.widgetSize
        glowRadius: 28
        spread: 0.15
        color: ColorUtils.transparentize(root.artDominantColor, 0.25)
        cornerRadius: Config.options.background.widgets.media.backgroundShape === "circle" ? root.widgetSize / 2 : Appearance.rounding.verylarge
        opacity: Config.options.background.widgets.media.glow.enable ? (0.01 * Config.options.background.widgets.media.glow.brightness) : 0

        Behavior on opacity {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
    }

    FadeLoader {
        id: loopButtonLoader
        anchors {
            right: parent.right
            bottom: parent.bottom
        }
        z: 3
        shown: root.hovering
        sourceComponent: ControlButton {
            colBackground: root.dynamicColors.colPrimaryBackground
            colBackgroundHover: root.dynamicColors.colPrimaryBackgroundHover
            colRipple: root.dynamicColors.colPrimaryRipple
            symbolColor: root.dynamicColors.colSecondary
            symbolText: "360"
            onClicked: {
                root.nextPlayer();
            }
        }
    }

    FadeLoader {
        z: 2
        anchors.centerIn: parent
        shown: root.currentPlayer == null
        sourceComponent: MaterialShapeWrappedMaterialSymbol {
            fill: 1
            padding: 20
            text: root.currentPlayer == null ? "music_off" : ""
            anchors.centerIn: parent
            iconSize: root.widgetSize / 4
            shape: MaterialShape.Shape.Cookie12Sided
            color: blendedColors.colOnSecondaryContainer ?? Appearance.colors.colOnSecondaryContainer
            colSymbol: Appearance.colors.colPrimaryContainer
        }
    }

    MaterialShape {
        id: shadowSourceShape
        anchors.fill: parent
        shape: root.mapShape(Config.options.background.widgets.media.backgroundShape)
        visible: false
    }

    StyledDropShadow {
        id: mediaShadow
        target: shadowSourceShape
        visible: Config.options.background.widgets.enableShadows ?? true
    }

    MaterialShape { // Art background
        id: artBackground
        anchors.fill: parent
        color: Appearance.colors.colPrimaryContainer
        shape: root.mapShape(Config.options.background.widgets.media.backgroundShape)

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: MaterialShape {
                width: artBackground.width
                shape: root.mapShape(Config.options.background.widgets.media.backgroundShape)
                height: artBackground.height
            }
        }

        StyledImage { // Art image
            id: mediaArt
            property int size: parent.height
            anchors.fill: parent

            source: root.displayedArtFilePath
            fillMode: Image.PreserveAspectCrop
            cache: false
            antialiasing: true

            width: size
            height: size
            sourceSize.width: size
            sourceSize.height: size
        }

        FadeLoader {
            shown: Config.options.background.widgets.media.tintArtCover
            anchors.fill: mediaArt
            sourceComponent: Item {
                Desaturate {
                    id: desaturatedIcon
                    visible: false // There's already color overlay
                    anchors.fill: parent
                    source: mediaArt
                    desaturation: 0.8
                }
                ColorOverlay {
                    anchors.fill: desaturatedIcon
                    source: desaturatedIcon
                    color: ColorUtils.transparentize(Appearance.colors.colOnPrimary, 0.9)
                }
            }
        }

        RadialWaveVisualizer {
            id: visualizer
            z: 1
            anchors.fill: parent
            points: root.visualizerPoints
            live: root.currentPlayer?.isPlaying ?? false
            color: root.dynamicColors.colSecondaryBackground
            waveOpacity: Config.options.background.widgets.media.visualizer.opacity
            waveBlur: Config.options.background.widgets.media.visualizer.blur
            smoothing: Config.options.background.widgets.media.visualizer.smoothing
        }
    }

    FadeLoader {
        shown: root.showRestButtons
        anchors {
            left: parent.left
            bottom: parent.bottom
        }
        sourceComponent: ControlButton {
            id: playButton
            anchors {
                left: parent.left
                bottom: parent.bottom
            }
            buttonRadius: root.currentPlayer?.isPlaying ? Appearance.rounding.normal : controlsSize / 2
            colBackground: root.dynamicColors.colSecondaryBackground
            colBackgroundHover: root.dynamicColors.colSecondaryBackgroundHover
            colRipple: root.dynamicColors.colSecondaryRipple
            symbolText: root.currentPlayer?.isPlaying ? "pause" : "play_arrow"
            symbolColor: useAlbumColors ? (blendedColors.colTertiary ?? Appearance.colors.colTertiary) : Appearance.colors.colTertiary
            onClicked: {
                root.currentPlayer.togglePlaying();
            }
        }
    }

    Loader {
        active: root.showRestButtons
        anchors {
            top: parent.top
            right: parent.right
        }
        sourceComponent: Rectangle {
            anchors {
                top: parent.top
                right: parent.right
            }
            implicitWidth: root.showPreviousToggle ? controlsSize * 2 : controlsSize
            implicitHeight: controlsSize
            z: 2
            radius: Appearance.rounding.full
            color: dynamicColors.colTertiaryBackground

            Behavior on implicitWidth {
                animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
            }

            FadeLoader {
                shown: root.showPreviousToggle
                sourceComponent: ControlButton {
                    anchors.left: parent.left
                    colBackground: root.dynamicColors.colTertiaryBackground
                    colBackgroundHover: root.dynamicColors.colTertiaryBackgroundHover
                    colRipple: root.dynamicColors.colTertiaryRipple
                    symbolColor: root.dynamicColors.colSecondary
                    symbolText: "skip_previous"
                    onClicked: {
                        currentPlayer.previous();
                    }
                }
            }

            ControlButton {
                anchors.right: parent.right

                colBackground: root.dynamicColors.colTertiaryBackground
                colBackgroundHover: root.dynamicColors.colTertiaryBackgroundHover
                colRipple: root.dynamicColors.colTertiaryRipple
                symbolColor: root.dynamicColors.colSecondary
                symbolText: "skip_next"
                onClicked: {
                    currentPlayer.next();
                }
            }
        }
    }

    component ControlButton: RippleButton {
        id: button
        property string symbolText
        property color symbolColor

        z: 2
        implicitWidth: controlsSize
        implicitHeight: implicitWidth
        buttonRadius: Appearance.rounding.full

        MaterialSymbol {
            anchors.centerIn: parent
            iconSize: root.buttonIconSize
            text: button.symbolText
            fill: 1
            color: button.symbolColor
        }
    }
}



