// modules/services/ControlCenterAppearanceConfig.qml
// Deliberately NOT part of Config.theme — that's the shell-wide theme
// system shared by every popup (StyledRect variant "popup" etc). These two
// values only ever get read by BarPopup's backgroundOpacityOverride (for
// the Control Center's own instance) and by common/Appearance.qml (for the
// tile backgrounds inside it), so changing them here can't affect anything
// else in the shell.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // The Control Center popup's own background fill (behind everything).
    property real backgroundOpacity: StateService.get("ccBackgroundOpacity", 0.85)

    // Background fill shared by the Wi-Fi/Bluetooth/Inhibitor/Sound/
    // Brightness/Volume/Power tiles, and the Wi-Fi/Bluetooth/Volume-mixer
    // detail pages' outer card — they all read the same design token, so
    // one slider keeps them visually consistent with each other.
    property real tileOpacity: StateService.get("ccTileOpacity", 1.0)

    function setBackgroundOpacity(value) {
        root.backgroundOpacity = Math.max(0, Math.min(1, value));
        StateService.set("ccBackgroundOpacity", root.backgroundOpacity);
    }

    function setTileOpacity(value) {
        root.tileOpacity = Math.max(0, Math.min(1, value));
        StateService.set("ccTileOpacity", root.tileOpacity);
    }

    // StateService loads its file asynchronously shortly after startup;
    // the property initializers above may have run before it was ready,
    // so re-read once it's actually loaded.
    Connections {
        target: StateService
        function onStateLoaded() {
            root.backgroundOpacity = StateService.get("ccBackgroundOpacity", 0.85);
            root.tileOpacity = StateService.get("ccTileOpacity", 1.0);
        }
    }
}
