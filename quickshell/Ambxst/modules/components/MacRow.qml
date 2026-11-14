import QtQuick
import QtQuick.Layouts
import qs.modules.theme

// One row of a MacGroup: [icon tile] label / description ........ [trailing] [>]
// Anything declared inside a MacRow is placed in the trailing slot (right side).
Item {
    id: root

    property string label: ""
    property string description: ""

    property string iconGlyph: ""
    property url iconSource: ""
    property color iconColor: MacStyle.tileGray

    property bool hoverable: false
    property bool chevron: false
    property bool showSeparator: true
    property bool wrapDescription: true

    default property alias trailing: trailingRow.data
    readonly property bool hasIcon: iconGlyph !== "" || iconSource.toString() !== ""
    readonly property bool hovered: hoverArea.containsMouse
    readonly property bool pressed: hoverArea.pressed

    signal clicked

    Layout.fillWidth: true
    implicitHeight: Math.max(MacStyle.rowHeight, content.implicitHeight + 18)
    opacity: enabled ? 1 : 0.5

    Rectangle {
        anchors.fill: parent
        color: root.pressed ? MacStyle.cardPress : (root.hovered ? MacStyle.cardHover : "transparent")
        visible: root.hoverable
        Behavior on color {
            ColorAnimation {
                duration: MacStyle.fast / 2
            }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        enabled: root.hoverable
        hoverEnabled: root.hoverable
        cursorShape: root.hoverable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }

    RowLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: MacStyle.rowPadding
        anchors.rightMargin: MacStyle.rowPadding
        spacing: 12

        MacIconTile {
            visible: root.hasIcon
            glyph: root.iconGlyph
            source: root.iconSource
            tint: root.iconColor
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1
            visible: root.label !== "" || root.description !== ""

            Text {
                Layout.fillWidth: true
                visible: root.label !== ""
                text: root.label
                font.family: MacStyle.fontFamily
                font.pixelSize: MacStyle.fsBody
                color: MacStyle.label
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: root.description !== ""
                text: root.description
                font.family: MacStyle.fontFamily
                font.pixelSize: MacStyle.fsSmall
                color: MacStyle.labelSecondary
                wrapMode: root.wrapDescription ? Text.WordWrap : Text.NoWrap
                elide: root.wrapDescription ? Text.ElideNone : Text.ElideRight
            }
        }

        // Spacer so trailing content hugs the right even without a label
        Item {
            Layout.fillWidth: root.label === "" && root.description === ""
            visible: Layout.fillWidth
        }

        RowLayout {
            id: trailingRow
            spacing: 8
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            visible: root.chevron
            text: Icons.caretRight
            font.family: Icons.font
            font.pixelSize: 15
            color: MacStyle.labelTertiary
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // bottom hairline (the last one is clipped by MacGroup)
    Rectangle {
        visible: root.showSeparator
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.leftMargin: root.hasIcon ? MacStyle.rowPadding + MacStyle.tileSize + 12 : MacStyle.rowPadding
        height: 1
        color: MacStyle.separator
    }
}
