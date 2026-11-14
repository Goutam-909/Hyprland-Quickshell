import QtQuick
import qs.modules.theme

// label ............ (switch)      — API-compatible with the old ToggleRow
MacRow {
    id: root

    property bool checked: false
    signal toggled(bool value)

    onCheckedChanged: {
        if (sw.checked !== checked)
            sw.checked = checked;
    }

    MacSwitch {
        id: sw
        checked: root.checked
        onToggled: root.toggled(checked)
    }
}
