import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.modules.theme

// Pill tab (CompositorTabButton replacement): selected = accent, others = control.
Item {
    id: root

    property string label: ""
    property string icon: ""
    property string image: ""
    property bool isSelected: false
    signal clicked

    implicitWidth: Math.max(110, row.implicitWidth + 32)
    implicitHeight: 34

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.isSelected ? Qt.rgba(MacStyle.accent.r, MacStyle.accent.g, MacStyle.accent.b, 0.22) : (hover.hovered ? MacStyle.controlHover : MacStyle.control)
        border.width: root.isSelected ? 0 : 1
        border.color: MacStyle.controlBorder
        Behavior on color {
            ColorAnimation {
                duration: MacStyle.fast
            }
        }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Loader {
            active: root.image !== ""
            visible: active
            Layout.preferredWidth: 17
            Layout.preferredHeight: 17
            sourceComponent: Image {
                source: root.image
                sourceSize: Qt.size(34, 34)
                fillMode: Image.PreserveAspectFit
                smooth: true
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: root.isSelected ? MacStyle.accent : MacStyle.label
                }
            }
        }

        Text {
            visible: root.icon !== "" && root.image === ""
            text: root.icon
            font.family: Icons.font
            font.pixelSize: 16
            color: root.isSelected ? MacStyle.accent : MacStyle.label
        }

        Text {
            text: root.label
            font.family: MacStyle.fontFamily
            font.pixelSize: MacStyle.fsBody
            font.weight: root.isSelected ? Font.DemiBold : Font.Normal
            color: root.isSelected ? MacStyle.accent : MacStyle.label
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        onTapped: root.clicked()
    }
}
