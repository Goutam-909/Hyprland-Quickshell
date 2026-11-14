import QtQuick
import qs.modules.components
import qs.modules.theme
import qs.modules.services
import Quickshell.Services.Mpris

ToggleButton {
    id: mediaButton
    buttonIcon: Icons.player
    tooltipText: "Media Player"

    property bool isPlaying: MprisController.activePlayer?.playbackState === MprisPlaybackState.Playing ?? false

    onToggle: function () {
        if (Visibilities.currentActiveModule === "mediaplayer") {
            Visibilities.setActiveModule("");
        } else {
            Visibilities.setActiveModule("mediaplayer");
        }
    }
}
