import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.theme

// Pop-up (dropdown) button — shows the current option, opens a menu on click.
// options: [{ label, value, icon (optional) }]
Item {
    id: root

    property var options: []
    property string value: ""
    property string placeholder: "Select…"
    signal valueSelected(string newValue)

    readonly property int currentIndex: {
        for (let i = 0; i < options.length; i++) {
            if (options[i].value === value)
                return i;
        }
        return -1;
    }
    readonly property string currentLabel: currentIndex >= 0 ? options[currentIndex].label : placeholder

    implicitHeight: 30
    implicitWidth: Math.max(110, metrics.width + 56)
    opacity: enabled ? 1 : 0.5

    TextMetrics {
        id: metrics
        font.family: MacStyle.fontFamily
        font.pixelSize: MacStyle.fsBody
        text: root.currentLabel
    }

    Rectangle {
        anchors.fill: parent
        radius: MacStyle.controlRadius
        color: area.pressed ? MacStyle.controlPress : (area.containsMouse ? MacStyle.controlHover : MacStyle.control)
        border.width: 1
        border.color: MacStyle.controlBorder
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.right: chevrons.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        text: root.currentLabel
        elide: Text.ElideRight
        font.family: MacStyle.fontFamily
        font.pixelSize: MacStyle.fsBody
        color: root.currentIndex >= 0 ? MacStyle.label : MacStyle.placeholder
    }

    Column {
        id: chevrons
        anchors.right: parent.right
        anchors.rightMargin: 7
        anchors.verticalCenter: parent.verticalCenter
        spacing: -3
        Text {
            text: Icons.caretUp
            font.family: Icons.font
            font.pixelSize: 10
            color: MacStyle.labelSecondary
        }
        Text {
            text: Icons.caretDown
            font.family: Icons.font
            font.pixelSize: 10
            color: MacStyle.labelSecondary
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.opened ? popup.close() : popup.open()
    }

    Popup {
        id: popup
        y: root.height + 4
        x: Math.min(0, root.width - width)
        width: Math.max(root.width, 210)
        padding: 5
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        enter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: MacStyle.fast
            }
        }
        exit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: MacStyle.fast / 2
            }
        }

        background: Rectangle {
            radius: 10
            color: MacStyle.popup
            border.width: 1
            border.color: MacStyle.controlBorder
        }

        contentItem: Column {
            spacing: 1

            Repeater {
                model: root.options

                delegate: Rectangle {
                    id: item
                    required property var modelData
                    required property int index
                    readonly property bool selected: index === root.currentIndex

                    width: popup.availableWidth
                    height: 32
                    radius: 7
                    color: itemArea.containsMouse ? Qt.rgba(MacStyle.accent.r, MacStyle.accent.g, MacStyle.accent.b, 0.22) : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        visible: item.selected
                        text: Icons.accept
                        font.family: Icons.font
                        font.pixelSize: 13
                        color: itemArea.containsMouse ? MacStyle.accent : MacStyle.label
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 30
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: item.modelData.label
                        elide: Text.ElideRight
                        font.family: MacStyle.fontFamily
                        font.pixelSize: MacStyle.fsBody
                        color: itemArea.containsMouse ? MacStyle.accent : MacStyle.label
                    }

                    MouseArea {
                        id: itemArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            popup.close();
                            root.valueSelected(item.modelData.value);
                        }
                    }
                }
            }
        }
    }
}
