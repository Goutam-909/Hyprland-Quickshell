import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common as C
import qs.modules.common.widgets

// The small "closed" state of the notch - just enough to glance at.
// Click anywhere on the pill (handled by NotchContent's MouseArea) to expand.
Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8

        MaterialSymbol {
            text: "schedule"
            iconSize: 14
            color: C.Appearance.colors.colOnLayer1
        }

        StyledText {
            text: Qt.formatTime(clock.date, "hh:mm")
            font.pixelSize: 12
            color: C.Appearance.colors.colOnLayer1
        }

        // Small dot when there's an unread notification history
        Rectangle {
            visible: Notifications.list.length > 0
            width: 6; height: 6; radius: 3
            color: C.Appearance.m3colors.m3primary
        }

        // Tiny media glyph when something is playing
        MaterialSymbol {
            visible: MprisController.activePlayer !== null // TODO: verify against your MprisController API
            text: "music_note"
            iconSize: 14
            color: C.Appearance.colors.colOnLayer1
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
