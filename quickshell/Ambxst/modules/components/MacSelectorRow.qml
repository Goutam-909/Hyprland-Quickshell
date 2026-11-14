import QtQuick
import QtQuick.Layouts
import qs.modules.theme

// label ......... [ A | B | C ]  (segmented)  or  [ Choice ⌃⌄ ] (pop-up)
// options: [{ label, value, icon (optional) }]    — SelectorRow replacement
MacRow {
    id: root

    property var options: []
    property string value: ""
    signal valueSelected(string newValue)

    function getIndexFromValue(val) {
        for (let i = 0; i < options.length; i++) {
            if (options[i].value === val)
                return i;
        }
        return 0;
    }

    // Few, short options → segmented control. Otherwise → pop-up button.
    readonly property bool useSegmented: {
        if (options.length > 4 || options.length < 2)
            return options.length < 2;
        let chars = 0;
        for (let i = 0; i < options.length; i++)
            chars += (options[i].label || "").length + ((options[i].icon ?? "") !== "" ? 3 : 0);
        return chars <= (label === "" ? 40 : 26);
    }
    readonly property bool fullWidthControl: label === "" && description === ""

    MacSegmented {
        visible: root.useSegmented
        stretch: root.fullWidthControl
        Layout.fillWidth: root.fullWidthControl
        options: root.options
        value: root.value
        onValueSelected: v => root.valueSelected(v)
    }

    MacPopupButton {
        visible: !root.useSegmented
        options: root.options
        value: root.value
        onValueSelected: v => root.valueSelected(v)
    }
}
