import QtQuick
import QtQuick.Layouts
import qs.modules.theme

// Four preview cards (Colour / Tinted / Clear / Plain), like macOS'
// "Icon & widget style" chooser. Emits styleSelected(name).
Item {
    id: root

    property string value: "color"
    signal styleSelected(string name)

    readonly property var choices: [
        {
            id: "color",
            label: "Colour"
        },
        {
            id: "tinted",
            label: "Tinted"
        },
        {
            id: "clear",
            label: "Clear"
        },
        {
            id: "plain",
            label: "Plain"
        }
    ]

    Layout.fillWidth: true
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 10

        Repeater {
            model: root.choices

            delegate: ColumnLayout {
                id: choice
                required property var modelData
                readonly property bool selected: root.value === modelData.id

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                spacing: 7

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 76
                    radius: 12
                    color: MacStyle.window
                    border.width: choice.selected ? 3 : 1
                    border.color: choice.selected ? MacStyle.accent : MacStyle.cardBorder

                    Behavior on border.color {
                        ColorAnimation {
                            duration: MacStyle.fast
                        }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Repeater {
                            model: [Icons.wifiHigh, Icons.bluetooth, Icons.speakerHigh]
                            delegate: MacIconTile {
                                required property string modelData
                                required property int index
                                size: 30
                                glyph: modelData
                                styleOverride: choice.modelData.id
                                tint: [MacStyle.tileBlue, MacStyle.tileBlue, MacStyle.tilePink][index]
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.styleSelected(choice.modelData.id)
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: choice.modelData.label
                    font.family: MacStyle.fontFamily
                    font.pixelSize: MacStyle.fsSmall
                    font.weight: choice.selected ? Font.DemiBold : Font.Normal
                    color: choice.selected ? MacStyle.label : MacStyle.labelSecondary
                }
            }
        }
    }
}
