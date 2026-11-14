// Services/MprisController.qml
// Adapter singleton — forwards to qs.modules.services.MprisController.
// The source design reads a composed `activeTrack` object; your service
// exposes title/artist/artUrl directly on the player, so this just wraps
// them into the shape the ported music card expects.
pragma Singleton
import QtQuick
import qs.modules.services as Backend

QtObject {
    id: root

    readonly property var activePlayer: Backend.MprisController.activePlayer
    readonly property bool isPlaying:   Backend.MprisController.isPlaying

    readonly property var activeTrack: activePlayer ? {
        title:  activePlayer.trackTitle  || "",
        artist: activePlayer.trackArtist || "",
        artUrl: activePlayer.trackArtUrl || ""
    } : null

    function previous()      { Backend.MprisController.previous() }
    function next()           { Backend.MprisController.next() }
    function togglePlaying() { Backend.MprisController.togglePlaying() }
}
