// common/functions/ColorUtils.qml
// Ported verbatim from the source design so BarPopup-hosted components that
// call ColorUtils.transparentize()/applyAlpha()/mix() work unchanged.
pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: root

    /**
     * Mixes two colors by a given percentage.
     * @param color1 - First color
     * @param color2 - Second color
     * @param percentage - Mix ratio (0-1). 1 = all color1, 0 = all color2
     */
    function mix(color1, color2, percentage = 0.5) {
        var c1 = Qt.color(color1)
        var c2 = Qt.color(color2)
        return Qt.rgba(
            percentage * c1.r + (1 - percentage) * c2.r,
            percentage * c1.g + (1 - percentage) * c2.g,
            percentage * c1.b + (1 - percentage) * c2.b,
            percentage * c1.a + (1 - percentage) * c2.a
        )
    }

    /**
     * Makes a color more transparent.
     * @param color - The color to transparentize
     * @param percentage - Amount to transparentize (0-1). 1 = fully transparent, 0 = no change
     */
    function transparentize(color, percentage = 0.5) {
        var c = Qt.color(color)
        return Qt.rgba(c.r, c.g, c.b, c.a * (1 - percentage))
    }

    /**
     * Sets the alpha channel of a color.
     * @param color - The base color
     * @param alpha - Desired alpha (0-1)
     */
    function applyAlpha(color, alpha) {
        var c = Qt.color(color)
        var a = Math.max(0, Math.min(1, alpha))
        return Qt.rgba(c.r, c.g, c.b, a)
    }

    function colorWithHueOf(color1, color2) {
        var c1 = Qt.color(color1)
        var c2 = Qt.color(color2)
        return Qt.hsva(c2.hsvHue, c1.hsvSaturation, c1.hsvValue, c1.a)
    }

    function colorWithSaturationOf(color1, color2) {
        var c1 = Qt.color(color1)
        var c2 = Qt.color(color2)
        return Qt.hsva(c1.hsvHue, c2.hsvSaturation, c1.hsvValue, c1.a)
    }

    function colorWithLightness(color, lightness) {
        var c = Qt.color(color)
        return Qt.hsla(c.hslHue, c.hslSaturation, lightness, c.a)
    }

    function colorWithLightnessOf(color1, color2) {
        var c2 = Qt.color(color2)
        return colorWithLightness(color1, c2.hslLightness)
    }

    function adaptToAccent(color1, color2) {
        var c1 = Qt.color(color1)
        var c2 = Qt.color(color2)
        return Qt.hsla(c2.hslHue, c2.hslSaturation, c1.hslLightness, c1.a)
    }

    function lighten(color, percentage = 0.1) {
        var c = Qt.color(color)
        var newLightness = Math.min(1, c.hslLightness + percentage)
        return Qt.hsla(c.hslHue, c.hslSaturation, newLightness, c.a)
    }

    function darken(color, percentage = 0.1) {
        var c = Qt.color(color)
        var newLightness = Math.max(0, c.hslLightness - percentage)
        return Qt.hsla(c.hslHue, c.hslSaturation, newLightness, c.a)
    }
}
