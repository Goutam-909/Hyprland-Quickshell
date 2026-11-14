import QtQuick
import qs.modules.theme

// Sub-section menu entry (drop-in for the old per-panel SectionButton):
// coloured icon tile (by sectionId) + title + chevron.
MacNavRow {
    id: root

    property string sectionId: ""

    readonly property var spec: {
        switch (sectionId) {
        case "bar":
            return [Icons.list, MacStyle.tileBlue];
        case "frame":
            return [Icons.frameCorners, MacStyle.tileIndigo];
        case "notch":
            return [Icons.dotsThree, MacStyle.tileGraphite];
        case "workspaces":
            return [Icons.squaresFour, MacStyle.tileTeal];
        case "overview":
            return [Icons.overview, MacStyle.tilePurple];
        case "dock":
            return [Icons.layout, MacStyle.tileLightBlue];
        case "lockscreen":
            return [Icons.lock, MacStyle.tileGray];
        case "desktop":
            return [Icons.wallpapers, MacStyle.tileLightBlue];
        case "system":
            return [Icons.gear, MacStyle.tileGraphite];
        case "general":
            return [Icons.gear, MacStyle.tileGray];
        case "colors":
            return [Icons.palette, MacStyle.tilePink];
        case "shadow":
        case "shadows":
            return [Icons.drop, MacStyle.tileGraphite];
        case "blur":
            return [Icons.sparkle, MacStyle.tileLightBlue];
        case "idle":
            return [Icons.moon, MacStyle.tileIndigo];
        case "performance":
            return [Icons.performance, MacStyle.tileGreen];
        case "prefixes":
            return [Icons.terminal, MacStyle.tileOrange];
        case "weather":
            return [Icons.sun, MacStyle.tileYellow];
        default:
            return null;
        }
    }

    iconGlyph: spec ? spec[0] : ""
    iconColor: spec ? spec[1] : MacStyle.tileGray
}
