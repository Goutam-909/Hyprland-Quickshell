import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config
import Quickshell.Io

Item {
    id: detailView

    signal backRequested()

    readonly property bool _inLibrary:
        Anime.currentAnime ? Anime.isInLibrary(Anime.currentAnime.id) : false

    // ── MPV launcher ──────────────────────────────────────────────────────────
    Process {
        id: mpvProcess
    }

    function _playWithMpv(url, referer, title) {
        if (!url || url.length === 0) {
            console.warn("[DetailView] _playWithMpv: empty URL, aborting")
            return
        }
        mpvProcess.running = false

        var args = [
            "mpv",
            "--fs",
            "--force-window=yes",
            "--title=" + (title || "Anime"),
            "--no-terminal"
        ]
        if (referer && referer.length > 0)
            args.push("--referrer=" + referer)
        args.push(url)

        mpvProcess.command = args
        mpvProcess.running = true
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Header ────────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 52
            color: "transparent"
            z: 2

            Separator {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 2
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 4; rightMargin: 10 }
                spacing: 2

                // Back button
                Button {
                    flat: true
                    width: 40; height: 40

                    background: StyledRect {
                        radius: Styling.radius(8)
                        variant: "focus"
                        opacity: parent.hovered ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 130 } }
                    }

                    contentItem: Text {
                        text: Icons.arrowLeft
                        font.family: Icons.font
                        font.pixelSize: 18
                        color: Colors.overSurface
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: detailView.backRequested()
                }

                Text {
                    Layout.fillWidth: true
                    text: Anime.currentAnime
                        ? (Anime.currentAnime.englishName || Anime.currentAnime.name || "")
                        : ""
                    font.family: Config.theme.font
                    font.pixelSize: 13; font.weight: Font.Medium
                    color: Colors.overBackground
                    elide: Text.ElideRight
                }

                // Library toggle button
                Button {
                    visible: Anime.currentAnime !== null
                    flat: true
                    height: 30
                    leftPadding: 12; rightPadding: 12

                    background: StyledRect {
                        radius: Styling.radius(8)
                        variant: detailView._inLibrary ? "primary" : "common"
                    }

                    contentItem: RowLayout {
                        spacing: 5
                        Text {
                            text: detailView._inLibrary ? Icons.accept : Icons.plus
                            font.family: Icons.font
                            font.pixelSize: 13
                            color: detailView._inLibrary
                                ? Styling.srItem("overprimary") : Colors.overSurface
                            Behavior on color { ColorAnimation { duration: 180 } }
                        }
                        Text {
                            text: "Library"
                            font.family: Config.theme.font
                            font.pixelSize: 11; font.letterSpacing: 0.3
                            color: detailView._inLibrary
                                ? Styling.srItem("overprimary") : Colors.overSurface
                            Behavior on color { ColorAnimation { duration: 180 } }
                        }
                    }

                    onClicked: {
                        if (detailView._inLibrary)
                            Anime.removeFromLibrary(Anime.currentAnime.id)
                        else
                            Anime.addToLibrary(Anime.currentAnime)
                    }
                }
            }
        }

        // ── Episode count / last-watched sub-header ───────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 32
            color: "transparent"
            visible: Anime.currentAnime !== null

            Separator {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 2
                opacity: 0.4
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 16; rightMargin: 16 }

                Text {
                    text: Anime.currentAnime
                        ? (Anime.currentAnime.episodes
                            ? Anime.currentAnime.episodes.length : 0) + " episodes"
                        : ""
                    font.family: Config.theme.font
                    font.pixelSize: 11; font.letterSpacing: 0.8
                    color: Colors.overSurface; opacity: 0.75
                }

                Item { Layout.fillWidth: true }

                // Last-watched badge
                Rectangle {
                    readonly property var _entry: Anime.currentAnime
                        ? Anime.getLibraryEntry(Anime.currentAnime.id) : null
                    visible: _entry !== null && _entry !== undefined
                        && _entry.lastWatchedEpNum !== "" && _entry.lastWatchedEpNum !== undefined
                    height: 20
                    width: lastWatchedText.implicitWidth + 18; radius: 10
                    color: Qt.rgba(0.5, 0.5, 1.0, 0.12)
                    border.color: Styling.srItem("primary"); border.width: 1

                    Text {
                        id: lastWatchedText; anchors.centerIn: parent
                        text: {
                            var e = Anime.currentAnime
                                ? Anime.getLibraryEntry(Anime.currentAnime.id) : null
                            return e ? "Last: Ep. " + e.lastWatchedEpNum : ""
                        }
                        font.family: Config.theme.font
                        font.pixelSize: 9; font.letterSpacing: 0.8
                        color: Styling.srItem("primary")
                    }
                }
            }
        }

        // ── Episode list ──────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Fetching episodes overlay
            Rectangle {
                anchors.fill: parent; color: "transparent"
                visible: Anime.isFetchingDetail; z: 5

                Column {
                    anchors.centerIn: parent; spacing: 12

                    Rectangle {
                        width: 26; height: 26; radius: 13
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "transparent"
                        border.color: Styling.srItem("primary"); border.width: 2
                        RotationAnimator on rotation {
                            from: 0; to: 360; duration: 800
                            loops: Animation.Infinite; running: parent.visible
                            easing.type: Easing.Linear
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "fetching episodes"
                        color: Colors.overSurface
                        font.family: Config.theme.font
                        font.pixelSize: 11; font.letterSpacing: 1.5; opacity: 0.65
                    }
                }
            }

            // Fetching stream overlay
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.55)
                visible: Anime.isFetchingLinks; z: 6

                Column {
                    anchors.centerIn: parent; spacing: 12

                    Rectangle {
                        width: 26; height: 26; radius: 13
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "transparent"
                        border.color: Styling.srItem("primary"); border.width: 2
                        RotationAnimator on rotation {
                            from: 0; to: 360; duration: 800
                            loops: Animation.Infinite; running: parent.visible
                            easing.type: Easing.Linear
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "fetching stream"
                        color: Colors.overBackground
                        font.family: Config.theme.font
                        font.pixelSize: 11; font.letterSpacing: 1.5; opacity: 0.8
                    }
                }
            }

            // Links error toast
            StyledRect {
                id: linksErrorToast
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                    bottomMargin: 12
                }
                height: 34; radius: Styling.radius(8)
                width: linksErrText.implicitWidth + 28
                visible: Anime.linksError.length > 0 && !Anime.isFetchingLinks
                z: 7
                variant: "common"

                Rectangle {
                    anchors.fill: parent; radius: Styling.radius(8)
                    color: Qt.rgba(0.9, 0.2, 0.2, 0.25)
                }

                Text {
                    id: linksErrText; anchors.centerIn: parent
                    text: Anime.linksError
                    font.family: Config.theme.font
                    font.pixelSize: 11; color: Colors.overBackground; elide: Text.ElideRight
                }
            }

            // Episode list
            ListView {
                id: epList
                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: Anime.currentAnime ? Anime.currentAnime.episodes : []

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 3
                        color: Styling.srItem("primary")
                        opacity: 0.45; radius: 2
                    }
                }

                delegate: Rectangle {
                    width: epList.width; height: 52
                    color: "transparent"

                    readonly property var _libEntry: Anime.currentAnime
                        ? Anime.getLibraryEntry(Anime.currentAnime.id) : null
                    readonly property bool isLastWatched:
                        _libEntry !== null && _libEntry !== undefined
                        && _libEntry.lastWatchedEpNum === String(modelData.number)

                    Rectangle {
                        anchors.fill: parent
                        color: isLastWatched
                            ? Qt.rgba(0.5, 0.5, 1.0, 0.07)
                            : (epRowArea.pressed
                                ? Qt.rgba(0.5, 0.5, 0.5, 0.15)
                                : (epRowArea.containsMouse ? Qt.rgba(0.5, 0.5, 0.5, 0.07) : "transparent"))
                        Behavior on color { ColorAnimation { duration: 110 } }
                    }

                    // Row divider
                    Rectangle {
                        anchors {
                            bottom: parent.bottom
                            left: parent.left; right: parent.right
                            leftMargin: 60; rightMargin: 16
                        }
                        height: 1; color: Colors.outline; opacity: 0.15
                    }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                        spacing: 14

                        // Episode pill
                        Rectangle {
                            width: epPillText.implicitWidth + 14; height: 24; radius: 12
                            color: isLastWatched
                                ? Styling.srItem("primary")
                                : Qt.rgba(0.5, 0.5, 1.0, 0.18)

                            Text {
                                id: epPillText; anchors.centerIn: parent
                                text: "Ep." + (modelData.number || "?")
                                font.family: Config.theme.font
                                font.pixelSize: 9; font.bold: true; font.letterSpacing: 0.4
                                color: isLastWatched
                                    ? Styling.srItem("overprimary")
                                    : Colors.overBackground
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Episode " + (modelData.number || "")
                            font.family: Config.theme.font
                            font.pixelSize: 12; color: Colors.overBackground
                            elide: Text.ElideRight
                        }

                        // Play icon
                        Text {
                            text: Icons.play
                            font.family: Icons.font
                            font.pixelSize: 13
                            color: epRowArea.containsMouse ? Styling.srItem("primary") : Colors.outline
                            opacity: epRowArea.containsMouse ? 0.9 : 0.35
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                            Behavior on color   { ColorAnimation  { duration: 120 } }
                        }
                    }

                    MouseArea {
                        id: epRowArea; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            if (!Anime.currentAnime) return
                            Anime.fetchStreamLinks(Anime.currentAnime.id, modelData.number, "best")
                            if (Anime.isInLibrary(Anime.currentAnime.id)) {
                                Anime.updateLastWatched(
                                    Anime.currentAnime.id,
                                    modelData.id,
                                    modelData.number
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    // Watch for a stream link becoming available → launch mpv
    Connections {
        target: Anime
        function onSelectedLinkChanged() {
            if (!Anime.selectedLink) return
            var lnk = Anime.selectedLink
            if (lnk.error || !lnk.url || lnk.url.length === 0) {
                console.warn("[DetailView] selectedLink invalid, aborting playback")
                Anime.clearStreamLinks()
                return
            }
            var title = Anime.currentAnime
                ? (Anime.currentAnime.englishName || Anime.currentAnime.name)
                  + " — Ep." + Anime.currentEpisode
                : ""
            detailView._playWithMpv(lnk.url, lnk.referer, title)
            Anime.clearStreamLinks()
        }
    }
}
