import QtQuick
import QtQuick.Layouts
import qs.modules.theme

// Padded row that hosts arbitrary content (a RowLayout, a custom widget…) inside
// a MacGroup, with the same bottom hairline as MacRow.
Item {
    id: root

    default property alias content: holder.data
    property bool showSeparator: true
    property int verticalPadding: 8

    Layout.fillWidth: true
    implicitHeight: Math.max(MacStyle.rowHeight, holder.implicitHeight + verticalPadding * 2)
    opacity: enabled ? 1 : 0.5

    ColumnLayout {
        id: holder
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: MacStyle.rowPadding
        anchors.rightMargin: MacStyle.rowPadding
        spacing: 0
    }

    Rectangle {
        visible: root.showSeparator
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: MacStyle.rowPadding
        height: 1
        color: MacStyle.separator
    }
}
