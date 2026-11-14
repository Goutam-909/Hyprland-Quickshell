import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.modules.theme

// Rounded "inset grouped" card — the macOS settings list container.
// Put MacRow / MacToggleRow / MacNavRow / MacRawRow ... inside.
// Each row paints its own bottom hairline; the inner area is 1px shorter than
// the content, so the very last hairline is clipped away. That keeps working
// when rows appear/disappear (visible: ...) without any bookkeeping.
ClippingRectangle {
    id: root

    default property alias content: column.data
    readonly property int innerHeight: column.implicitHeight

    Layout.fillWidth: true
    visible: column.implicitHeight > 0

    color: MacStyle.card
    radius: MacStyle.cardRadius
    border.width: 1
    border.color: MacStyle.cardBorder
    implicitHeight: Math.max(0, column.implicitHeight - 1) + border.width * 2

    Item {
        x: root.border.width
        y: root.border.width
        width: root.width - root.border.width * 2
        height: Math.max(0, column.implicitHeight - 1)
        clip: true

        ColumnLayout {
            id: column
            width: parent.width
            spacing: 0
        }
    }
}
