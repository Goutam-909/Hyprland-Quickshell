import QtQuick
import QtQuick.Layouts
import qs.modules.theme

// Small caption under a MacGroup.
Text {
    Layout.fillWidth: true
    Layout.leftMargin: 8
    Layout.rightMargin: 8
    Layout.topMargin: -4
    wrapMode: Text.WordWrap
    font.family: MacStyle.fontFamily
    font.pixelSize: MacStyle.fsSmall
    color: MacStyle.labelSecondary
}
