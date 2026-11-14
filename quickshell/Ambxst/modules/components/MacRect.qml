import QtQuick
import qs.modules.theme

// Drop-in stand-in for StyledRect (same variant names) painted with the macOS
// palette. The restyled legacy panels alias StyledRect to this.
Rectangle {
    id: root

    property string variant: "common"
    property bool enableShadow: false
    property bool enableBorder: true
    property bool animateRadius: true
    property real backgroundOpacity: -1
    property string gradientOrientation: "vertical"

    readonly property color itemColor: MacStyle.variantItem(variant)
    property color item: itemColor
    readonly property var variantConfig: ({})

    radius: MacStyle.radius(0)
    color: MacStyle.variantColor(variant)
    border.width: enableBorder && MacStyle.variantBorder(variant).a > 0 ? 1 : 0
    border.color: MacStyle.variantBorder(variant)

    Behavior on color {
        ColorAnimation {
            duration: MacStyle.fast / 2
        }
    }
}
