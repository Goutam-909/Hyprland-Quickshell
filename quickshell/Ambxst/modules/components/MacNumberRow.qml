import QtQuick
import QtQuick.Layouts
import qs.modules.theme

// label ......... [ 42 ]▲▼ px      — API-compatible with NumberInputRow
MacRow {
    id: root

    property int value: 0
    property int minValue: 0
    property int maxValue: 100
    property string suffix: ""
    signal valueEdited(int newValue)

    function commit(v) {
        const nv = Math.max(minValue, Math.min(maxValue, v));
        field.text = nv.toString();
        root.valueEdited(nv);
    }

    MacTextField {
        id: field
        Layout.preferredWidth: 76
        horizontalAlignment: TextInput.AlignRight
        validator: IntValidator {
            bottom: root.minValue
            top: root.maxValue
        }

        readonly property int configValue: root.value
        onConfigValueChanged: {
            if (!activeInput && text !== configValue.toString())
                text = configValue.toString();
        }
        Component.onCompleted: text = configValue.toString()

        onEditingFinished: {
            const v = parseInt(text);
            if (!isNaN(v))
                root.commit(v);
        }
    }

    MacStepper {
        onIncrement: root.commit(root.value + 1)
        onDecrement: root.commit(root.value - 1)
    }

    Text {
        visible: root.suffix !== ""
        text: root.suffix
        font.family: MacStyle.fontFamily
        font.pixelSize: MacStyle.fsBody
        color: MacStyle.labelSecondary
    }
}
