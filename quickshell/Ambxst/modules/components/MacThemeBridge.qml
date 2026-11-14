import QtQuick
import qs.modules.theme
import qs.config

// Feeds your Colors theme into MacStyle so the macOS layout wears your colours.
// Instantiated once by SettingsTab. Turn off with MacStyle.useThemeColors = false.
Item {
    id: bridge
    visible: false

    readonly property bool on: MacStyle.useThemeColors
    function a(c, v) {
        return Qt.rgba(c.r, c.g, c.b, v);
    }

    // Colour of one of your ORIGINAL StyledRect variants (Config.theme.srPane, srPopup, ...)
    function vc(variant) {
        const cfg = Styling.getStyledRectConfig(variant) || {};
        const stop = (cfg.gradient && cfg.gradient.length > 0) ? cfg.gradient[0][0] : cfg.color;
        const base = Config.resolveColor(stop);
        const op = cfg.opacity === undefined ? 1 : cfg.opacity;
        return Qt.rgba(base.r, base.g, base.b, base.a * op);
    }

    component Map: Binding {
        target: MacStyle
        when: bridge.on
        restoreMode: Binding.RestoreBindingOrValue
    }

    // user choices from Settings → Interface
    Binding {
        target: MacStyle
        property: "sidebarIconStyle"
        value: MacPrefs.sidebarIconStyle
    }
    Binding {
        target: MacStyle
        property: "pageIconStyle"
        value: MacPrefs.pageIconStyle
    }
    Binding {
        target: MacStyle
        property: "trafficLights"
        value: MacPrefs.trafficLights
    }
    Binding {
        target: MacStyle
        property: "useThemeColors"
        value: MacPrefs.useThemeColors
    }
    Binding {
        target: MacStyle
        property: "preferMacFonts"
        value: MacPrefs.preferMacFonts
    }

    Binding {
        target: MacStyle
        property: "borders"
        value: MacPrefs.borders
    }

    // surfaces
    Map {
        property: "window"
        value: Colors.background
    }
    Map {
        property: "windowBorder"
        value: MacStyle.borders ? bridge.a(Colors.outlineVariant, 0.9) : "transparent"
    }
    Map {
        property: "sidebar"
        value: Colors.surfaceContainerLow
    }
    Map {
        property: "sidebarBorder"
        value: MacStyle.borders ? bridge.a(Colors.outlineVariant, 0.6) : "transparent"
    }
    Map {
        property: "card"
        value: bridge.vc("pane")
    }
    Map {
        property: "cardBorder"
        value: MacStyle.borders ? bridge.a(Colors.outlineVariant, 0.55) : "transparent"
    }
    Map {
        property: "popup"
        value: bridge.vc("popup")
    }
    Map {
        property: "cardHover"
        value: bridge.a(Colors.overBackground, 0.05)
    }
    Map {
        property: "cardPress"
        value: bridge.a(Colors.overBackground, 0.09)
    }
    Map {
        property: "sidebarHover"
        value: bridge.a(Colors.overBackground, 0.07)
    }
    Map {
        property: "separator"
        value: bridge.a(Colors.outlineVariant, 0.55)
    }

    // text
    Map {
        property: "label"
        value: Colors.overBackground
    }
    Map {
        property: "labelSecondary"
        value: Colors.overSurfaceVariant
    }
    Map {
        property: "labelTertiary"
        value: bridge.a(Colors.outline, 0.85)
    }
    Map {
        property: "placeholder"
        value: bridge.a(Colors.overSurfaceVariant, 0.55)
    }

    // controls
    Map {
        property: "control"
        value: Colors.surfaceContainerHigh
    }
    Map {
        property: "controlHover"
        value: Colors.surfaceContainerHighest
    }
    Map {
        property: "controlPress"
        value: Colors.surfaceBright
    }
    Map {
        property: "controlBorder"
        value: MacStyle.borders ? bridge.a(Colors.outlineVariant, 0.75) : "transparent"
    }
    Map {
        property: "field"
        value: Colors.surfaceContainerLowest
    }
    Map {
        property: "fieldBorder"
        value: MacStyle.borders ? bridge.a(Colors.outlineVariant, 0.9) : "transparent"
    }
    Map {
        property: "searchField"
        value: Colors.surfaceContainerHigh
    }
    Map {
        property: "segmentTrack"
        value: Colors.surfaceContainerHighest
    }
    Map {
        property: "switchOff"
        value: Colors.outlineVariant
    }
    Map {
        property: "sliderTrack"
        value: Colors.outlineVariant
    }

    // accent + status
    Map {
        property: "accent"
        value: Colors.primary
    }
    Map {
        property: "accentText"
        value: Colors.overPrimary
    }
    Map {
        property: "destructive"
        value: Colors.error
    }
    Map {
        property: "warning"
        value: Colors.lightYellow
    }
    Map {
        property: "success"
        value: Colors.green
    }
    // Icon tiles intentionally keep the fixed macOS colours (white glyphs).
}
