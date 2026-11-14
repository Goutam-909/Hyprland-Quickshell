// Services/Brightness.qml
// Adapter singleton — forwards to qs.modules.services.Brightness.
// Your BrightnessMonitor objects (screen/brightness/ready/setBrightness())
// already match the shape the ported Brightness slider expects, so this is
// a direct passthrough.
pragma Singleton
import QtQuick
import qs.modules.services as Backend

QtObject {
    id: root
    readonly property var monitors: Backend.Brightness.monitors

    // Re-expose the backend's brightnessChanged signal so consumers of this
    // adapter (e.g. controlpanel/Brightness.qml's Connections block) have
    // an actual signal to bind to instead of a phantom handler.
    signal brightnessChanged(real value, var screen)

    property var _brightnessConnections: Connections {
        target: Backend.Brightness
        function onBrightnessChanged(value, screen) {
            root.brightnessChanged(value, screen)
        }
    }
}
