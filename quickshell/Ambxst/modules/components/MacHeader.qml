import QtQuick
import QtQuick.Layouts
import qs.modules.theme

// Section title above a MacGroup (bold, like "Theme" / "Windows" in System Settings).
Text {
    Layout.fillWidth: true
    Layout.leftMargin: 4
    Layout.topMargin: 6
    font.family: MacStyle.fontFamily
    font.pixelSize: MacStyle.fsBody
    font.weight: Font.DemiBold
    color: MacStyle.label
    elide: Text.ElideRight
}
