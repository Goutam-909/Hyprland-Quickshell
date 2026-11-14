import QtQuick
import QtQuick.Controls
import qs.modules.theme

// Push button. `primary` = accent-filled default button, `destructive` = red text.
Button {
    id: control

    property string iconGlyph: ""
    property bool primary: false
    property bool destructive: false
    property bool prominentOnHover: false
    property bool loading: false

    flat: true
    hoverEnabled: true
    focusPolicy: Qt.NoFocus   // never steal keyboard focus (keeps Wayland text-input state clean)
    implicitHeight: 30
    implicitWidth: Math.max(60, contentRow.implicitWidth + 28)
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0
    opacity: enabled ? 1 : 0.45

    background: Rectangle {
        radius: MacStyle.controlRadius
        color: {
            if (control.primary)
                return control.down ? MacStyle.accentPressed : MacStyle.accent;
            return control.down ? MacStyle.controlPress : (control.hovered ? MacStyle.controlHover : MacStyle.control);
        }
        border.width: control.primary ? 0 : 1
        border.color: MacStyle.controlBorder

        Behavior on color {
            ColorAnimation {
                duration: MacStyle.fast / 2
            }
        }
    }

    contentItem: Item {
        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: 5

            Text {
                id: glyphItem
                visible: control.iconGlyph !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: control.iconGlyph
                font.family: Icons.font
                font.pixelSize: 16
                color: textItem.color

                RotationAnimation on rotation {
                    running: control.loading
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                }
            }

            Text {
                id: textItem
                visible: control.text !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: control.text
                font.family: MacStyle.fontFamily
                font.pixelSize: MacStyle.fsBody
                color: control.primary ? MacStyle.accentText : (control.destructive ? MacStyle.destructive : MacStyle.label)
            }
        }
    }
}
