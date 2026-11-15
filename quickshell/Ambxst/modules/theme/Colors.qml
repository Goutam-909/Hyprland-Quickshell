pragma Singleton
import QtQuick
import Quickshell
import qs.config

// Colour tokens used across the shell.
//
// This file no longer reads, watches or generates anything. Values are pushed
// in by ThemeLoader.qml, which translates the shared matugen output
// (~/.config/uchiha/colors/colors.json, written by switchwall.sh) into the
// names below. Defaults here are only used until the first load.
//
// Do NOT add FileView / Process / generator logic back in here: every change
// of a property below re-evaluates thousands of bindings, so keep this file
// a dumb container.
Singleton {
    id: colors

    // Raw background coming from the theme (ThemeLoader sets this)
    property color baseBackground: "#1a1111"
    property color background: Config.oledMode ? "#000000" : baseBackground

    // Derived on purpose (same as before): tinted from background/overBackground
    property color surface: Qt.tint(background, Qt.rgba(overBackground.r, overBackground.g, overBackground.b, 0.1))
    property color surfaceBright: Qt.tint(background, Qt.rgba(overBackground.r, overBackground.g, overBackground.b, 0.2))

    property color blue: "#cebdfe"
    property color blueContainer: "#4c3e76"
    property color blueSource: "#0000ff"
    property color blueValue: "#0000ff"
    property color cyan: "#84d5c4"
    property color cyanContainer: "#005045"
    property color cyanSource: "#00ffff"
    property color cyanValue: "#00ffff"
    property color error: "#ffb4ab"
    property color errorContainer: "#93000a"
    property color green: "#b7d085"
    property color greenContainer: "#3a4d10"
    property color greenSource: "#00ff00"
    property color greenValue: "#00ff00"
    property color inverseOnSurface: "#382e2d"
    property color inversePrimary: "#904a46"
    property color inverseSurface: "#f1dedd"
    property color lightBlue: "#cebdfe"
    property color lightCyan: "#84d5c4"
    property color lightGreen: "#b7d085"
    property color lightMagenta: "#fcb0d5"
    property color lightRed: "#ffb4ab"
    property color lightYellow: "#dec56e"
    property color magenta: "#fcb0d5"
    property color magentaContainer: "#6c3353"
    property color magentaSource: "#ff00ff"
    property color magentaValue: "#ff00ff"
    property color outline: "#a08c8b"
    property color outlineVariant: "#534342"
    property color overBackground: "#f1dedd"
    property color overBlue: "#35275e"
    property color overBlueContainer: "#e8ddff"
    property color overCyan: "#00382f"
    property color overCyanContainer: "#9ff2e0"
    property color overError: "#690005"
    property color overErrorContainer: "#ffdad6"
    property color overGreen: "#253600"
    property color overGreenContainer: "#d3ec9e"
    property color overMagenta: "#521d3c"
    property color overMagentaContainer: "#ffd8e8"
    property color overPrimary: "#571d1c"
    property color overPrimaryContainer: "#ffdad7"
    property color overPrimaryFixed: "#3b0809"
    property color overPrimaryFixedVariant: "#733331"
    property color overRed: "#561e19"
    property color overRedContainer: "#ffdad6"
    property color overSecondary: "#442928"
    property color overSecondaryContainer: "#ffdad7"
    property color overSecondaryFixed: "#2c1514"
    property color overSecondaryFixedVariant: "#5d3f3d"
    property color overSurface: "#f1dedd"
    property color overSurfaceVariant: "#d8c2c0"
    property color overTertiary: "#402d04"
    property color overTertiaryContainer: "#ffdea7"
    property color overTertiaryFixed: "#271900"
    property color overTertiaryFixedVariant: "#594319"
    property color overWhite: "#00363d"
    property color overWhiteContainer: "#9eeffd"
    property color overYellow: "#3b2f00"
    property color overYellowContainer: "#fce186"
    property color primary: "#ffb3ae"
    property color primaryContainer: "#733331"
    property color primaryFixed: "#ffdad7"
    property color primaryFixedDim: "#ffb3ae"
    property color red: "#ffb4ab"
    property color redContainer: "#73332e"
    property color redSource: "#ff0000"
    property color redValue: "#ff0000"
    property color scrim: "#000000"
    property color secondary: "#e7bdb9"
    property color secondaryContainer: "#5d3f3d"
    property color secondaryFixed: "#ffdad7"
    property color secondaryFixedDim: "#e7bdb9"
    property color shadow: "#000000"
    property color sourceColor: "#7f2424"
    property color surfaceContainer: "#271d1d"
    property color surfaceContainerHigh: "#322827"
    property color surfaceContainerHighest: "#3d3231"
    property color surfaceContainerLow: "#231919"
    property color surfaceContainerLowest: "#140c0c"
    property color surfaceDim: "#1a1111"
    property color surfaceTint: "#ffb3ae"
    property color surfaceVariant: "#534342"
    property color tertiary: "#e2c28c"
    property color tertiaryContainer: "#594319"
    property color tertiaryFixed: "#ffdea7"
    property color tertiaryFixedDim: "#e2c28c"
    property color white: "#82d3e0"
    property color whiteContainer: "#004f58"
    property color whiteSource: "#ffffff"
    property color whiteValue: "#ffffff"
    property color yellow: "#dec56e"
    property color yellowContainer: "#554500"
    property color yellowSource: "#ffff00"
    property color yellowValue: "#ffff00"

    property color criticalText: "#FF6B08"
    property color criticalRed: "#FF0028"

    // Semantic aliases
    property color warning: yellow
    property color success: green

    // List of available color names for color pickers (excludes internal/source colors)
    readonly property var availableColorNames: ["background", "surface", "surfaceBright", "surfaceContainer", "surfaceContainerHigh", "surfaceContainerHighest", "surfaceContainerLow", "surfaceContainerLowest", "surfaceDim", "surfaceTint", "surfaceVariant", "primary", "primaryContainer", "primaryFixed", "primaryFixedDim", "secondary", "secondaryContainer", "secondaryFixed", "secondaryFixedDim", "tertiary", "tertiaryContainer", "tertiaryFixed", "tertiaryFixedDim", "error", "errorContainer", "overBackground", "overSurface", "overSurfaceVariant", "overPrimary", "overPrimaryContainer", "overPrimaryFixed", "overPrimaryFixedVariant", "overSecondary", "overSecondaryContainer", "overSecondaryFixed", "overSecondaryFixedVariant", "overTertiary", "overTertiaryContainer", "overTertiaryFixed", "overTertiaryFixedVariant", "overError", "overErrorContainer", "outline", "outlineVariant", "inversePrimary", "inverseSurface", "inverseOnSurface", "shadow", "scrim", "blue", "blueContainer", "overBlue", "overBlueContainer", "lightBlue", "cyan", "cyanContainer", "overCyan", "overCyanContainer", "lightCyan", "green", "greenContainer", "overGreen", "overGreenContainer", "lightGreen", "magenta", "magentaContainer", "overMagenta", "overMagentaContainer", "lightMagenta", "red", "redContainer", "overRed", "overRedContainer", "lightRed", "yellow", "yellowContainer", "overYellow", "overYellowContainer", "lightYellow", "white", "whiteContainer", "overWhite", "overWhiteContainer"]
}
