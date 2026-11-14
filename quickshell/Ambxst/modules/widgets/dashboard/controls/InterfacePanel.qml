pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components

// Settings → Interface: choose how the Settings app itself looks.
Item {
    id: root

    property int maxContentWidth: 480
    readonly property int contentWidth: Math.min(width, maxContentWidth)
    readonly property real sideMargin: (width - contentWidth) / 2

    readonly property string presetName: {
        const s = MacPrefs.sidebarIconStyle;
        const p = MacPrefs.pageIconStyle;
        if (s === "color" && p === "tinted")
            return "mixed";
        if (s === p)
            return s;
        return "custom";
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: col
            width: root.contentWidth
            x: root.sideMargin
            spacing: 10

            PanelTitlebar {
                Layout.fillWidth: true
                title: "Interface"
            }

            // ── quick presets ───────────────────────────────────────────
            MacHeader {
                text: "Icon Style"
            }
            MacGroup {
                MacSelectorRow {
                    label: "Preset"
                    description: "Mixed = colourful sidebar, calm icons inside pages"
                    options: [
                        {
                            label: "Mixed",
                            value: "mixed"
                        },
                        {
                            label: "Colour",
                            value: "color"
                        },
                        {
                            label: "Tinted",
                            value: "tinted"
                        },
                        {
                            label: "Clear",
                            value: "clear"
                        }
                    ]
                    value: root.presetName === "custom" ? "" : root.presetName
                    onValueSelected: v => {
                        if (v === "mixed") {
                            MacPrefs.sidebarIconStyle = "color";
                            MacPrefs.pageIconStyle = "tinted";
                        } else {
                            MacPrefs.sidebarIconStyle = v;
                            MacPrefs.pageIconStyle = v;
                        }
                    }
                }
            }

            // ── sidebar ─────────────────────────────────────────────────
            MacHeader {
                text: "Sidebar Icons"
            }
            MacGroup {
                MacRawRow {
                    showSeparator: false
                    verticalPadding: 14
                    MacIconStylePicker {
                        value: MacPrefs.sidebarIconStyle
                        onStyleSelected: name => MacPrefs.sidebarIconStyle = name
                    }
                }
            }

            // ── pages ───────────────────────────────────────────────────
            MacHeader {
                text: "Page Icons"
            }
            MacGroup {
                MacRawRow {
                    showSeparator: false
                    verticalPadding: 14
                    MacIconStylePicker {
                        value: MacPrefs.pageIconStyle
                        onStyleSelected: name => MacPrefs.pageIconStyle = name
                    }
                }
            }
            MacFooter {
                text: "Page icons are the tiles inside pages: sub-menus, Wi-Fi / Bluetooth headers, device lists."
            }

            // ── window ──────────────────────────────────────────────────
            MacHeader {
                text: "Window"
            }
            MacGroup {
                MacToggleRow {
                    label: "Use theme colours"
                    description: "Follow your wallpaper colours. Off = fixed macOS palette."
                    checked: MacPrefs.useThemeColors
                    onToggled: v => MacPrefs.useThemeColors = v
                }
                MacToggleRow {
                    label: "Borders"
                    description: "Thin outlines around the window, cards and controls."
                    checked: MacPrefs.borders
                    onToggled: v => MacPrefs.borders = v
                }
                MacToggleRow {
                    label: "Window buttons"
                    description: "Show the red, yellow and green buttons."
                    checked: MacPrefs.trafficLights
                    onToggled: v => MacPrefs.trafficLights = v
                }
                MacToggleRow {
                    label: "Prefer macOS-style font"
                    description: "Use SF Pro or Inter if installed, instead of your UI font."
                    checked: MacPrefs.preferMacFonts
                    onToggled: v => MacPrefs.preferMacFonts = v
                }
            }
        }
    }
}
