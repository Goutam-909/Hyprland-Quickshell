
import Quickshell
import QtQuick
import qs
import qs.modules.common
import qs.modules.ii.background.widgets

// Style-switching wrapper. Keeps the same configEntryName/public contract the
// original MediaWidget.qml had, so Background.qml needs no changes.
// Actual visuals live in <Style>MediaContent.qml, loaded based on
// Config.options.background.widgets.media.style.
AbstractBackgroundWidget {
    id: root

    signal requestReset()

    configEntryName: "media"

    readonly property string style: Config.options.background.widgets.media.style || "default"

    // Hover handled once here, shared by every style, instead of duplicating
    // it in each content component.
    property bool hovering: false
    hoverEnabled: true
    onEntered: root.hovering = true
    onExited: root.hovering = false

    implicitWidth: styleLoader.item ? styleLoader.item.implicitWidth : 0
    implicitHeight: styleLoader.item ? styleLoader.item.implicitHeight : 0

    Loader {
        id: styleLoader
        sourceComponent: {
            switch (root.style) {
            case "android": return androidComp
            case "cd": return cdComp
            case "circular": return circularComp
            case "compact": return compactComp
            case "expressive": return expressiveComp
            case "nothingRing": return nothingRingComp
            default: return defaultComp
            }
        }
        onLoaded: {
            item.hovering = Qt.binding(() => root.hovering);
        }
    }

    Component { id: defaultComp; DefaultMediaContent { wallpaperItem: root.wallpaperItem } }
    Component { id: androidComp; AndroidMediaContent { wallpaperItem: root.wallpaperItem } }
    Component { id: cdComp; CdMediaContent { wallpaperItem: root.wallpaperItem } }
    Component { id: circularComp; CircularMediaContent { wallpaperItem: root.wallpaperItem } }
    Component { id: compactComp; CompactMediaContent { wallpaperItem: root.wallpaperItem } }
    Component { id: expressiveComp; ExpressiveMediaContent { wallpaperItem: root.wallpaperItem } }
    Component { id: nothingRingComp; NothingRingMediaContent { wallpaperItem: root.wallpaperItem } }
}



