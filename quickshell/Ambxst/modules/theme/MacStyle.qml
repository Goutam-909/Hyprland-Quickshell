pragma Singleton
import QtQuick
import qs.config

// ─────────────────────────────────────────────────────────────────────────────
//  MacStyle — design tokens for the macOS-style Settings app.
//  Light/dark follows Config.lightMode (and Config.oledMode for pure black).
//  Tweak anything here and every Mac* control + the whole Settings app follows.
// ─────────────────────────────────────────────────────────────────────────────
QtObject {
    id: s

    // ── Switches you may want to flip ───────────────────────────────────────
    // Use SF Pro / Inter / a clean sans if installed instead of Config.theme.font
    // (macOS' look depends a lot on its typeface). Set false to keep your font.
    property bool preferMacFonts: true
    // Font used for the Mac look. Leave "" to auto-pick (SF Pro → Inter → ...).
    property string fontOverride: ""
    // Show the red/yellow/green window buttons inside the sidebar.
    property bool trafficLights: true

    // Take every colour from your Colors theme (matugen / wallpaper). Set false
    // for the fixed macOS palette. The mapping lives in MacThemeBridge.qml.
    property bool useThemeColors: true

    // Icon tile look (like macOS "Icon & widget style"), chosen in Settings → Interface:
    //   "color"  – multicolour macOS tiles
    //   "tinted" – soft tile in your accent colour, accent glyph
    //   "clear"  – neutral tile, plain glyph
    //   "plain"  – no tile, just the glyph
    property string sidebarIconStyle: "color"
    property string pageIconStyle: "tinted"

    // Outlines around window / sidebar / cards / controls (off = flat look).
    property bool borders: false

    // ── Mode ────────────────────────────────────────────────────────────────
    readonly property bool dark: !Config.lightMode
    readonly property bool oled: Config.oledMode && dark

    // Set by SettingsTab: label of the section currently shown in the toolbar
    // (PanelTitlebar hides its own title when it would just repeat this).
    property string pageTitle: ""

    // ── Accent (macOS "Blue"). SettingsTab can bind this to Colors.primary
    //    if you want the Mac layout with your wallpaper-derived accent. ───────
    property color accent: dark ? "#0A84FF" : "#0A64E1"
    readonly property color accentPressed: Qt.darker(accent, 1.15)
    property color accentText: "#FFFFFF"
    property color destructive: dark ? "#FF453A" : "#FF3B30"
    property color warning: dark ? "#FFD60A" : "#FF9F0A"
    property color success: dark ? "#32D74B" : "#30D158"

    // ── Surfaces ────────────────────────────────────────────────────────────
    property color window: dark ? (oled ? "#000000" : "#1E1E20") : "#FFFFFF"
    property color windowBorder: borders ? (dark ? "#48484A" : "#D6D6D6") : "transparent"
    property color sidebar: dark ? (oled ? "#0E0E0F" : "#2A2A2C") : "#F4F4F3"
    property color sidebarBorder: borders ? (dark ? "#38383A" : "#E7E7E6") : "transparent"
    property color card: dark ? (oled ? "#161617" : "#2A2A2C") : "#F7F7F7"
    property color cardBorder: borders ? (dark ? "#383839" : "#E8E8E8") : "transparent"
    property color cardHover: dark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.035)
    property color cardPress: dark ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(0, 0, 0, 0.07)
    property color sidebarHover: dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.055)
    property color separator: dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.085)

    // ── Text ────────────────────────────────────────────────────────────────
    property color label: dark ? Qt.rgba(1, 1, 1, 0.88) : Qt.rgba(0, 0, 0, 0.86)
    property color labelSecondary: dark ? Qt.rgba(1, 1, 1, 0.55) : Qt.rgba(0, 0, 0, 0.52)
    property color labelTertiary: dark ? Qt.rgba(1, 1, 1, 0.30) : Qt.rgba(0, 0, 0, 0.30)
    property color placeholder: dark ? Qt.rgba(1, 1, 1, 0.32) : Qt.rgba(0, 0, 0, 0.32)

    // ── Controls ────────────────────────────────────────────────────────────
    property color control: dark ? Qt.rgba(1, 1, 1, 0.11) : "#FFFFFF"
    property color controlHover: dark ? Qt.rgba(1, 1, 1, 0.16) : "#F2F2F2"
    property color controlPress: dark ? Qt.rgba(1, 1, 1, 0.22) : "#E6E6E6"
    property color controlBorder: borders ? (dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.13)) : "transparent"
    property color field: dark ? Qt.rgba(0, 0, 0, 0.28) : "#FFFFFF"
    property color fieldBorder: borders ? (dark ? Qt.rgba(1, 1, 1, 0.13) : Qt.rgba(0, 0, 0, 0.12)) : "transparent"
    property color searchField: dark ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(0, 0, 0, 0.065)
    property color segmentTrack: dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.065)
    property color switchOff: dark ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(0, 0, 0, 0.12)
    property color sliderTrack: dark ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(0, 0, 0, 0.13)
    property color popup: dark ? "#2E2E30" : "#FFFFFF"
    property color tileGlyph: "#FFFFFF"
    readonly property color focusRing: Qt.rgba(accent.r, accent.g, accent.b, 0.45)

    // ── Icon tile colors (the coloured squares in macOS' sidebar) ────────────
    property color tileBlue: "#0A84FF"
    property color tileLightBlue: "#32ADE6"
    property color tileTeal: "#30B0C7"
    property color tileGreen: "#30D158"
    property color tileYellow: "#FFB800"
    property color tileOrange: "#FF9500"
    property color tileRed: "#FF3B30"
    property color tilePink: "#FF2D55"
    property color tilePurple: "#AF52DE"
    property color tileIndigo: "#5E5CE6"
    property color tileGray: "#8E8E93"
    property color tileGraphite: "#636366"
    property color tileBlack: "#2C2C2E"

    // ── Metrics ─────────────────────────────────────────────────────────────
    readonly property int windowRadius: 16
    readonly property int sidebarWidth: 276
    readonly property int sidebarInset: 12
    readonly property int sidebarRadius: 18
    readonly property int cardRadius: 14
    readonly property int controlRadius: 8
    readonly property int rowHeight: 48
    readonly property int rowPadding: 16
    readonly property int tileSize: 32
    readonly property real tileRadius: 8
    readonly property int toolbarHeight: 64
    readonly property int pagePadding: 28

    // ── Type ────────────────────────────────────────────────────────────────
    readonly property int fsBody: 15
    readonly property int fsSmall: 13
    readonly property int fsTitle: 18
    readonly property int fsLarge: 28

    readonly property string fontFamily: {
        if (fontOverride !== "")
            return fontOverride;
        if (!preferMacFonts)
            return Config.theme.font;
        const have = Qt.fontFamilies();
        const wanted = ["SF Pro Text", "SF Pro Display", "SF Pro", "San Francisco", "Inter", "Inter Variable", "Helvetica Neue", "Cantarell", "Noto Sans", "Open Sans", "DejaVu Sans"];
        for (let i = 0; i < wanted.length; i++) {
            if (have.indexOf(wanted[i]) >= 0)
                return wanted[i];
        }
        return Config.theme.font;
    }

    // ── Motion (respects your animDuration; 0 disables) ─────────────────────
    readonly property int fast: Config.animDuration > 0 ? 140 : 0
    readonly property int medium: Config.animDuration > 0 ? 220 : 0

    // ── Helpers ─────────────────────────────────────────────────────────────
    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    // ── Compatibility helpers (used by the restyled legacy panels) ──────────
    function radius(o) {
        return Math.max(3, Math.min(12, 8 + o * 0.5));
    }
    function fontSize(o) {
        return Math.max(11, fsBody + o);
    }
    function monoFontSize(o) {
        return Math.max(11, Config.theme.monoFontSize + o);
    }
    // Colour of a StyledRect variant
    function variantColor(v) {
        switch (v) {
        case "primary":
            return accent;
        case "primaryfocus":
            return accentPressed;
        case "error":
            return alpha(destructive, 0.16);
        case "errorfocus":
            return alpha(destructive, 0.26);
        case "common":
        case "secondary":
        case "tertiary":
            return control;
        case "focus":
        case "secondaryfocus":
        case "tertiaryfocus":
            return controlHover;
        case "bg":
            return window;
        case "popup":
            return popup;
        case "transparent":
            return "transparent";
        default:
            return card;   // pane, internalbg, barbg …
        }
    }
    // Foreground (text/icon) colour that goes on top of a variant
    function variantItem(v) {
        switch (v) {
        case "primary":
        case "primaryfocus":
            return accentText;
        case "error":
        case "errorfocus":
            return destructive;
        default:
            return label;
        }
    }
    function variantBorder(v) {
        switch (v) {
        case "common":
        case "focus":
        case "secondary":
        case "tertiary":
            return controlBorder;
        case "pane":
        case "internalbg":
            return cardBorder;
        default:
            return "transparent";
        }
    }
}
