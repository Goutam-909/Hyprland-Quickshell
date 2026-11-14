// Services/Audio.qml
// Adapter singleton - forwards to qs.modules.services.Audio.
//
// IMPORTANT: never write `Services.Audio.sink.audio.x` in components.
// When an audio device disappears (Bluetooth disconnect, unplug), `sink` or
// `sink.audio` is briefly null. Use the null-safe values / setters below.
pragma Singleton
import QtQuick
import qs.modules.services as Backend

QtObject {
    id: root

    // true only when the sink node AND its audio object exist
    readonly property bool ready:    (Backend.Audio.sink?.ready ?? false) && (Backend.Audio.sink?.audio ?? null) !== null
    // same for the microphone, independent of the sink
    readonly property bool micReady: (Backend.Audio.source?.ready ?? false) && (Backend.Audio.source?.audio ?? null) !== null

    // Raw nodes (may be null) - fine for labels / pickers, NOT for `.audio.x`
    readonly property var sink:   Backend.Audio.sink
    readonly property var source: Backend.Audio.source  // mic input node

    // Null-safe values
    readonly property real sinkVolume:   Backend.Audio.sink?.audio?.volume ?? 0
    readonly property bool sinkMuted:    Backend.Audio.sink?.audio?.muted ?? false
    readonly property real sourceVolume: Backend.Audio.source?.audio?.volume ?? 0
    readonly property bool sourceMuted:  Backend.Audio.source?.audio?.muted ?? false

    // Null-safe setters (silently do nothing while the device is gone)
    function setSinkVolume(v)   { if (!isNaN(v)) Backend.Audio.setVolume(v) }
    function setSinkMuted(m)    { if (Backend.Audio.sink?.audio) Backend.Audio.sink.audio.muted = m }
    function setSourceVolume(v) { if (!isNaN(v)) Backend.Audio.setMicVolume(v) }

    function toggleMute() {
        Backend.Audio.toggleMute()
    }

    function toggleMicMute() {
        Backend.Audio.toggleMicMute()
    }
}
