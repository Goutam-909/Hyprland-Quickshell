import QtQuick
import QtQuick.Effects
import qs.modules.theme

// The rounded square behind a glyph (or SVG). Look is controlled by
// MacStyle.sidebarIconStyle / pageIconStyle: "tinted" | "clear" | "plain" | "color".
Item {
    id: root

    property string glyph: ""
    property url source: ""
    property color tint: MacStyle.tileGray     // used by the "color" style
    property real size: MacStyle.tileSize
    property bool flat: false
    property color glyphColor: "transparent"   // optional override
    property bool overAccent: false              // sitting on an accent-filled row

    property bool sidebar: false               // sidebar tiles use their own style
    property string styleOverride: ""          // for previews
    readonly property string style: styleOverride !== "" ? styleOverride : (sidebar ? MacStyle.sidebarIconStyle : MacStyle.pageIconStyle)
    readonly property bool coloured: style === "color"

    readonly property color fillColor: {
        if (overAccent && !coloured)
            return MacStyle.alpha(MacStyle.accentText, 0.18);
        switch (style) {
        case "tinted":
            return MacStyle.alpha(MacStyle.accent, 0.17);
        case "clear":
            return MacStyle.control;
        case "plain":
            return "transparent";
        default:
            return tint;
        }
    }
    readonly property color effectiveGlyph: {
        if (glyphColor.a > 0)
            return glyphColor;
        if (overAccent && !coloured)
            return MacStyle.accentText;
        switch (style) {
        case "tinted":
            return MacStyle.accent;
        case "clear":
            return MacStyle.label;
        case "plain":
            return MacStyle.labelSecondary;
        default:
            return MacStyle.tileGlyph;
        }
    }

    implicitWidth: size
    implicitHeight: size

    Rectangle {
        anchors.fill: parent
        radius: root.size * 0.25
        visible: root.style !== "plain" || root.overAccent
        border.width: MacStyle.borders ? (root.coloured ? 0.5 : (root.style === "clear" && !root.overAccent ? 1 : 0)) : 0
        border.color: root.coloured ? Qt.rgba(0, 0, 0, 0.18) : MacStyle.controlBorder
        gradient: root.coloured ? colourGradient : null
        color: root.fillColor

        Gradient {
            id: colourGradient
            GradientStop {
                position: 0.0
                color: root.flat ? root.tint : Qt.lighter(root.tint, 1.14)
            }
            GradientStop {
                position: 1.0
                color: root.tint
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: root.glyph !== ""
        text: root.glyph
        font.family: Icons.font
        font.pixelSize: root.size * (root.style === "plain" && !root.overAccent ? 0.78 : 0.62)
        color: root.effectiveGlyph
    }

    Loader {
        id: imgLoader
        anchors.centerIn: parent
        width: root.size * 0.66
        height: width
        active: root.glyph === "" && root.source.toString() !== ""
        visible: active

        sourceComponent: Image {
            source: root.source
            sourceSize: Qt.size(imgLoader.width * 2, imgLoader.height * 2)
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            layer.enabled: true
            layer.effect: MultiEffect {
                brightness: 1.0
                colorization: 1.0
                colorizationColor: root.effectiveGlyph
            }
        }
    }
}
