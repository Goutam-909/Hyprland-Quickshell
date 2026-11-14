import QtQuick
import QtQuick.Layouts
import qs.modules.theme

// label ......... [ text field ]     — TextInputRow replacement
MacRow {
    id: root

    property string value: ""
    property string placeholder: ""
    property int fieldWidth: 260
    signal valueEdited(string newValue)

    MacTextField {
        id: field
        Layout.preferredWidth: root.fieldWidth
        placeholderText: root.placeholder

        readonly property string configValue: root.value
        onConfigValueChanged: {
            if (!activeInput && text !== configValue)
                text = configValue;
        }
        Component.onCompleted: text = configValue

        onEditingFinished: root.valueEdited(text)
    }
}
