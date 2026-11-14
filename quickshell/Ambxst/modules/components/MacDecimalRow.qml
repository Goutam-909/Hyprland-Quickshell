import QtQuick
import QtQuick.Layouts
import qs.modules.theme

// Decimal variant of MacNumberRow (DecimalInputRow replacement).
MacRow {
    id: root

    property real value: 0.0
    property real minValue: 0.0
    property real maxValue: 1.0
    property real step: 0.1
    property string suffix: ""
    signal valueEdited(real newValue)

    function commit(v) {
        const nv = Math.max(minValue, Math.min(maxValue, Math.round(v * 100) / 100));
        field.text = nv.toFixed(1);
        root.valueEdited(nv);
    }

    MacTextField {
        id: field
        Layout.preferredWidth: 76
        horizontalAlignment: TextInput.AlignRight
        validator: DoubleValidator {
            bottom: root.minValue
            top: root.maxValue
            decimals: 2
        }

        readonly property real configValue: root.value
        onConfigValueChanged: {
            if (!activeInput) {
                if (Math.abs(parseFloat(text) - configValue) > 0.001 || text === "")
                    text = configValue.toFixed(1);
            }
        }
        Component.onCompleted: text = configValue.toFixed(1)

        onEditingFinished: {
            const v = parseFloat(text);
            if (!isNaN(v))
                root.commit(v);
        }
    }

    MacStepper {
        onIncrement: root.commit(root.value + root.step)
        onDecrement: root.commit(root.value - root.step)
    }

    Text {
        visible: root.suffix !== ""
        text: root.suffix
        font.family: MacStyle.fontFamily
        font.pixelSize: MacStyle.fsBody
        color: MacStyle.labelSecondary
    }
}
