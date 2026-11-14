import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.theme

// label ......... [ prefix ]   (monospace, max 4 chars)
MacRow {
    id: root

    property string prefixValue: ""
    signal prefixEdited(string newValue)

    MacTextField {
        Layout.preferredWidth: 96
        mono: true
        maximumLength: 4
        horizontalAlignment: TextInput.AlignHCenter
        text: root.prefixValue
        onEditingFinished: {
            if (text !== root.prefixValue && text.trim() !== "")
                root.prefixEdited(text.trim());
        }
    }
}
