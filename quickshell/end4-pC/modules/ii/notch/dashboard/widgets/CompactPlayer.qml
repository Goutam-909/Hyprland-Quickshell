import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common as C
import qs.modules.common.widgets

// Condensed from the donor's FullPlayer.qml (~600 lines with full artwork
// blur backdrop + seek scrubber). This keeps title/artist, play/pause, and
// prev/next - extend with a StyledSlider bound to position/length if you
// want the scrubber back.
RowLayout {
    id: root
    visible: MprisController.activePlayer !== null // TODO: verify against services/MprisController.qml
    Layout.fillWidth: true
    spacing: 10

    CustomIcon {
        visible: MprisController.activePlayer?.trackArtUrl // TODO
        source: MprisController.activePlayer?.trackArtUrl ?? "" // TODO
        width: 40
        height: 40
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 1
        StyledText {
            Layout.fillWidth: true
            elide: Text.ElideRight
            font.weight: Font.Bold
            font.pixelSize: 12
            text: MprisController.activePlayer?.trackTitle ?? "" // TODO
        }
        StyledText {
            Layout.fillWidth: true
            elide: Text.ElideRight
            font.pixelSize: 11
            color: C.Appearance.colors.colSubtext
            text: MprisController.activePlayer?.trackArtist ?? "" // TODO
        }
    }

    RippleButtonWithIcon {
        materialIcon: "skip_previous"
        implicitWidth: 26; implicitHeight: 26
        onClicked: MprisController.activePlayer?.previous() // TODO
    }
    RippleButtonWithIcon {
        materialIcon: MprisController.activePlayer?.isPlaying ? "pause" : "play_arrow" // TODO
        implicitWidth: 30; implicitHeight: 30
        onClicked: MprisController.activePlayer?.togglePlaying() // TODO
    }
    RippleButtonWithIcon {
        materialIcon: "skip_next"
        implicitWidth: 26; implicitHeight: 26
        onClicked: MprisController.activePlayer?.next() // TODO
    }
}
