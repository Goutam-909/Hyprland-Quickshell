import QtQuick
import qs.modules.common as C

// Standard "appear" behavior for anything popping up inside the notch.
// Deliberately kept on the donor's snappy OutBack/OutQuart curves rather than
// this shell's Material Expressive bezier curves, per your call to keep the
// notch's distinct feel.
Item {
    id: root

    property bool isVisible: false

    scale: isVisible ? 1.0 : 0.8
    opacity: isVisible ? 1.0 : 0.0
    visible: opacity > 0

    Behavior on scale {
        enabled: C.Config.options.notch.animDuration > 0
        NumberAnimation {
            duration: C.Config.options.notch.animDuration
            easing.type: Easing.OutBack
            easing.overshoot: 1.2
        }
    }

    Behavior on opacity {
        enabled: C.Config.options.notch.animDuration > 0
        NumberAnimation {
            duration: C.Config.options.notch.animDuration
            easing.type: Easing.OutQuart
        }
    }
}
