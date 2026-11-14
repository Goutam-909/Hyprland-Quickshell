pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Saved choices from Settings → Interface (kept in Quickshell's state dir).
// MacThemeBridge copies these into MacStyle.
Singleton {
    id: root

    property alias sidebarIconStyle: adapter.sidebarIconStyle
    property alias pageIconStyle: adapter.pageIconStyle
    property alias trafficLights: adapter.trafficLights
    property alias useThemeColors: adapter.useThemeColors
    property alias preferMacFonts: adapter.preferMacFonts
    property alias borders: adapter.borders

    FileView {
        id: file
        path: Quickshell.statePath("mac-settings.json")
        atomicWrites: true
        blockLoading: true
        watchChanges: false
        printErrors: false

        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        adapter: JsonAdapter {
            id: adapter
            property string sidebarIconStyle: "color"
            property string pageIconStyle: "tinted"
            property bool trafficLights: true
            property bool useThemeColors: true
            property bool preferMacFonts: true
            property bool borders: false
        }
    }
}
