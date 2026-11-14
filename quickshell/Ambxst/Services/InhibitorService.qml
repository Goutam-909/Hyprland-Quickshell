// Services/InhibitorService.qml
// Adapter singleton — the source design's "Inhibitor" tile (bedtime icon,
// "Screen awake" / "Inactive") is a plain idle-inhibitor toggle, which is
// exactly what your CaffeineService already is. Forwards to it.
pragma Singleton
import QtQuick
import qs.modules.services as Backend

QtObject {
    id: root
    readonly property bool active: Backend.CaffeineService.inhibit
    function toggle() {
        Backend.CaffeineService.toggleInhibit()
    }
}
