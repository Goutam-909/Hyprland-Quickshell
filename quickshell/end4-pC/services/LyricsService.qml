pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    readonly property MprisPlayer activePlayer: MprisController.activePlayer

    // Only Spotify's metadata is trustworthy/clean enough to query lrclib
    // with, and it's the only source we want to send title/artist data to
    // an external server for. Everything else (YouTube via browser, etc.)
    // is skipped entirely - no network request is ever made for it.
    // Checks identity, desktopEntry, AND dbusName so this catches Spotify
    // regardless of install method (native, spotify-launcher, Flatpak,
    // Snap, AppImage, etc.) - they all register the same MPRIS bus name
    // (org.mpris.MediaPlayer2.spotify) even when identity/desktopEntry
    // strings vary slightly between packagers.
    readonly property bool isSpotify: {
        const p = root.activePlayer
        if (!p) return false
            const identity = (p.identity ?? "").toLowerCase()
            const desktopEntry = (p.desktopEntry ?? "").toLowerCase()
            const dbusName = (p.dbusName ?? "").toLowerCase()
            return identity.includes("spotify") ||
            desktopEntry.includes("spotify") ||
            dbusName.includes("spotify")
    }

    property var lyricsLines: []
    property int activeIndex: -1
    property string status: "loading"
    property var slots: ["", "", "", "", "", "", ""]

    readonly property int before: 3
    readonly property int after:  3
    readonly property int total:  7

    function buildSlots(idx) {
        let result = []
        for (let i = 0; i < root.total; i++) {
            let lineIdx = idx - root.before + i
            if (lineIdx >= 0 && lineIdx < root.lyricsLines.length)
                result.push(root.lyricsLines[lineIdx].text || "♪")
                else
                    result.push("")
        }
        return result
    }

    Timer {
        id: syncTimer
        interval: 300
        repeat: true
        running: root.status === "ok" && root.lyricsLines.length > 0
        onTriggered: {
            const pos = root.activePlayer?.position ?? 0
            let idx = -1
            for (let i = 0; i < root.lyricsLines.length; i++) {
                if (root.lyricsLines[i].time <= pos) idx = i
                    else break
            }
            if (idx !== root.activeIndex) {
                root.activeIndex = idx
                root.slots = root.buildSlots(idx)
            }
        }
    }

    Process {
        id: lyricsProc
        running: false
        property int requestId: 0
        // Set right before WE call running=false to kill/replace this process,
        // so onExited can tell "we killed it on purpose" apart from "it
        // actually died/finished on its own".
        property bool intentionalStop: false

        stdout: SplitParser {
            onRead: data => lyricsProc.__handleLine(data)
        }
        stderr: SplitParser {
            onRead: data => console.warn("[LyricsService] lyrics.py stderr:", data)
        }
        onExited: (exitCode, exitStatus) => {
            watchdog.stop()
            if (lyricsProc.intentionalStop) {
                lyricsProc.intentionalStop = false
                return
            }
            // Only a genuine failure of the CURRENT request should surface.
            if (lyricsProc.requestId === root.__currentRequestId && root.status === "loading") {
                console.warn("[LyricsService] lyrics.py exited with no result, code:", exitCode)
                root.status = "not_found"
            }
        }
        function __handleLine(data) {
            if (lyricsProc.requestId !== root.__currentRequestId) return // stale result, ignore

                const trimmed = data.trim()
                if (trimmed === "not_found") { root.status = "not_found"; return }
                if (trimmed === "no_info")   { root.status = "no_info";   return }

                const parts = trimmed.split("§")
                if (parts.length < 3) return
                    if (parts[parts.length - 1].trim() !== "ok") return

                        let lines = []
                        for (let i = 0; i < parts.length - 1; i += 2) {
                            const t = parseFloat(parts[i])
                            const txt = parts[i + 1] || ""
                            if (!isNaN(t)) lines.push({ time: t, text: txt })
                        }

                        if (lines.length === 0) { root.status = "not_found"; return }

                        root.lyricsLines = lines
                        root.activeIndex = -1
                        root.slots = root.buildSlots(-1)
                        root.status = "ok"
        }
    }

    // Bumped on every restart so late/stale process output from a previous
    // track can never overwrite the state of a newer one.
    property int __currentRequestId: 0

    // Safety net: if the script hangs (slow/unreachable network, stuck
    // process, etc.) don't leave the UI spinning forever.
    Timer {
        id: watchdog
        interval: 30000
        repeat: false
        onTriggered: {
            if (root.status === "loading") {
                if (lyricsProc.running) lyricsProc.intentionalStop = true
                    lyricsProc.running = false
                    root.status = "not_found"
            }
        }
    }

    function restartLyrics() {
        watchdog.stop()
        root.__currentRequestId++
        if (lyricsProc.running) lyricsProc.intentionalStop = true
            lyricsProc.running = false
            root.lyricsLines = []
            root.activeIndex = -1
            root.slots = ["", "", "", "", "", "", ""]
            root.status = "loading"

            if (!root.isSpotify) { root.status = "no_info"; return }

            const title    = root.activePlayer?.trackTitle  ?? ""
            const artist   = root.activePlayer?.trackArtist ?? ""
            const duration = root.activePlayer?.length       ?? 0

            if (!title || !artist) { root.status = "no_info"; return }

            lyricsProc.requestId = root.__currentRequestId
            lyricsProc.command = [
                "python3",
                `${Directories.scriptPath}/lyrics/lyrics.py`,
                title, artist, String(Math.floor(duration))
            ]
            lyricsProc.running = true
            watchdog.restart()
    }

    // Debounced so a burst of MPRIS metadata updates (title arrives, then
    // artist arrives separately a few ms later - common at startup or on
    // player switch) triggers one restart instead of a rapid-fire
    // kill/relaunch for each intermediate value.
    Timer {
        id: restartDebounce
        interval: 120
        repeat: false
        onTriggered: root.restartLyrics()
    }

    // Recomputes whenever activePlayer itself changes (new player found or
    // switched) OR when trackTitle/trackArtist changes on the same player.
    readonly property string trackKey: root.activePlayer
    ? `${root.activePlayer.trackTitle}::${root.activePlayer.trackArtist}`
    : ""
    onTrackKeyChanged: restartDebounce.restart()

    Component.onCompleted: root.restartLyrics()
}
