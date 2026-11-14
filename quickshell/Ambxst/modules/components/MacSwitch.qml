import QtQuick
import QtQuick.Controls
import qs.modules.theme

// macOS toggle switch. Drop-in replacement for QtQuick.Controls Switch
// (same `checked`, `onCheckedChanged`, `onToggled`).
Switch {
    id: control

    implicitWidth: 46
    implicitHeight: 27
    padding: 0
    spacing: 0
    hoverEnabled: true
    focusPolicy: Qt.NoFocus   // never steal keyboard focus (keeps Wayland text-input state clean)
    opacity: enabled ? 1 : 0.45

    background: null
    contentItem: Item {}

    indicator: Rectangle {
        implicitWidth: 46
        implicitHeight: 27
        x: control.leftPadding
        y: (control.height - height) / 2
        radius: height / 2
        color: control.checked ? MacStyle.accent : MacStyle.switchOff

        Behavior on color {
            ColorAnimation {
                duration: MacStyle.fast
            }
        }

        // knob shadow
        Rectangle {
            x: knob.x
            y: knob.y + 1
            width: knob.width
            height: knob.height
            radius: height / 2
            color: "#33000000"
        }

        Rectangle {
            id: knob
            y: 2
            width: control.down ? 27 : 23
            height: 23
            radius: 11.5
            x: control.checked ? parent.width - width - 2 : 2
            color: "#FFFFFF"
            border.width: 0.5
            border.color: "#26000000"

            Behavior on x {
                NumberAnimation {
                    duration: MacStyle.fast
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on width {
                NumberAnimation {
                    duration: MacStyle.fast / 1.5
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
