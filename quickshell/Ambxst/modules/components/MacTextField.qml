import QtQuick
import qs.config
import qs.modules.theme

// macOS rounded text field with the soft blue focus ring.
Item {
    id: root

    property alias text: input.text
    property alias input: input
    property alias validator: input.validator
    property alias readOnly: input.readOnly
    property alias maximumLength: input.maximumLength
    property alias activeInput: input.activeFocus
    property string placeholderText: ""
    property bool password: false
    property bool mono: false
    property int horizontalAlignment: TextInput.AlignLeft
    property string fontFamilyOverride: ""

    signal accepted
    signal editingFinished
    signal textEdited

    function focusInput() {
        input.forceActiveFocus();
    }

    implicitWidth: 180
    implicitHeight: 30
    opacity: enabled ? 1 : 0.5

    Rectangle {
        anchors.fill: parent
        anchors.margins: -3
        radius: MacStyle.controlRadius + 3
        color: "transparent"
        border.width: 3
        border.color: MacStyle.focusRing
        opacity: input.activeFocus ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: MacStyle.fast
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: MacStyle.controlRadius
        color: MacStyle.field
        border.width: 1
        border.color: input.activeFocus ? MacStyle.accent : MacStyle.fieldBorder
    }

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: root.horizontalAlignment
        clip: true
        selectByMouse: true
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        font.family: root.fontFamilyOverride !== "" ? root.fontFamilyOverride : (root.mono ? Config.theme.monoFont : MacStyle.fontFamily)
        font.pixelSize: MacStyle.fsBody
        color: MacStyle.label
        selectionColor: MacStyle.accent
        selectedTextColor: "#FFFFFF"

        onAccepted: root.accepted()
        onEditingFinished: root.editingFinished()
        onTextEdited: root.textEdited()

        Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: root.horizontalAlignment
            visible: input.text === "" && !input.preeditText
            text: root.placeholderText
            font: input.font
            color: MacStyle.placeholder
            elide: Text.ElideRight
        }
    }
}
