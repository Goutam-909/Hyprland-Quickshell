import QtQuick
import qs.modules.theme

// A row that triggers an action / opens something external (ActionButton replacement).
MacRow {
    id: root

    property string text: ""
    property string icon: ""          // optional Phosphor glyph (shown as a tile)
    property bool external: true

    label: text
    iconGlyph: icon
    hoverable: true

    Text {
        text: root.external ? Icons.arrowSquareOut : Icons.caretRight
        font.family: Icons.font
        font.pixelSize: 17
        color: MacStyle.labelTertiary
    }
}
